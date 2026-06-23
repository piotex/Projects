"""
ECS <-> RDS Debugging Lab
=========================
Scenariusze:
  GET /           healthcheck
  GET /db/ok      normalne zapytanie (szybkie)
  GET /db/slow    wolne zapytanie (blokuje connection pool)
  GET /db/leak    wyciek połączeń (nie zamyka sesji)
  GET /db/hammer  n równoległych zapytań — wyczerpuje pulę
  GET /metrics    aktualny stan puli połączeń
"""

import os
import time
import threading
import logging
from flask import Flask, jsonify
import psycopg2
from psycopg2 import pool

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = int(os.environ.get("DB_PORT", 5432))
DB_NAME = os.environ.get("DB_NAME", "appdb")
DB_USER = os.environ.get("DB_USER", "appuser")
DB_PASS = os.environ.get("DB_PASS", "apppassword")
POOL_MIN = int(os.environ.get("POOL_MIN", 1))
POOL_MAX = int(os.environ.get("POOL_MAX", 5))   # celowo mały – łatwiej wyczerpać

log.info(f"Connecting to {DB_HOST}:{DB_PORT}/{DB_NAME} pool={POOL_MIN}..{POOL_MAX}")

try:
    conn_pool = pool.ThreadedConnectionPool(
        POOL_MIN, POOL_MAX,
        host=DB_HOST, port=DB_PORT,
        database=DB_NAME, user=DB_USER, password=DB_PASS,
        connect_timeout=5,
    )
    log.info("Connection pool created OK")
except Exception as e:
    log.error(f"Cannot create pool: {e}")
    conn_pool = None

leaked_conns = []   # celowo trzymamy referencje (scenariusz leak)
metrics = {
    "requests_total": 0,
    "pool_errors": 0,
    "slow_queries": 0,
}
metrics_lock = threading.Lock()


def get_conn():
    if conn_pool is None:
        raise RuntimeError("Pool not initialized")
    return conn_pool.getconn()


def put_conn(conn):
    conn_pool.putconn(conn)


# ── Routes ────────────────────────────────────────────────────────────────────

@app.route("/")
def healthcheck():
    status = "ok" if conn_pool and not conn_pool.closed else "degraded"
    return jsonify({"status": status, "db_host": DB_HOST})


@app.route("/db/ok")
def db_ok():
    """Normalne, szybkie zapytanie."""
    with metrics_lock:
        metrics["requests_total"] += 1
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT 1 AS ping, now() AS ts;")
        row = cur.fetchone()
        cur.close()
        put_conn(conn)
        return jsonify({"result": row[0], "ts": str(row[1])})
    except pool.PoolError as e:
        with metrics_lock:
            metrics["pool_errors"] += 1
        log.error(f"Pool exhausted: {e}")
        return jsonify({"error": "DB connection timeout", "detail": str(e)}), 503
    except Exception as e:
        log.error(f"DB error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/db/slow")
def db_slow():
    """Wolne zapytanie – trzyma połączenie przez 15 s.
    Wywołaj kilka razy jednocześnie → pool wyczerpany → 503 na /db/ok.
    """
    with metrics_lock:
        metrics["requests_total"] += 1
        metrics["slow_queries"] += 1
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT pg_sleep(15);")
        cur.fetchall()
        cur.close()
        put_conn(conn)
        return jsonify({"status": "slow query done"})
    except pool.PoolError as e:
        with metrics_lock:
            metrics["pool_errors"] += 1
        log.error(f"Pool exhausted: {e}")
        return jsonify({"error": "DB connection timeout", "detail": str(e)}), 503
    except Exception as e:
        log.error(f"DB error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/db/leak")
def db_leak():
    """Pobiera połączenie i NIE oddaje go do puli.
    Po POOL_MAX wywołaniach pula jest martwa.
    """
    with metrics_lock:
        metrics["requests_total"] += 1
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT 'leaked' AS status;")
        cur.fetchall()
        cur.close()
        leaked_conns.append(conn)   # celowy wyciek
        log.warning(f"Connection leaked! Total leaked: {len(leaked_conns)}")
        return jsonify({"leaked": len(leaked_conns), "pool_max": POOL_MAX})
    except pool.PoolError as e:
        with metrics_lock:
            metrics["pool_errors"] += 1
        log.error(f"Pool exhausted (leak): {e}")
        return jsonify({"error": "pool exhausted", "leaked": len(leaked_conns)}), 503


@app.route("/db/hammer")
def db_hammer():
    """Uruchamia 20 wątków naraz – każdy chce połączenie.
    Natychmiast wyczerpuje pulę i generuje błędy.
    """
    with metrics_lock:
        metrics["requests_total"] += 1

    results = []
    errors = []
    lock = threading.Lock()

    def worker(i):
        try:
            conn = get_conn()
            cur = conn.cursor()
            cur.execute("SELECT pg_sleep(2), %s AS id;", (i,))
            row = cur.fetchone()
            cur.close()
            put_conn(conn)
            with lock:
                results.append({"id": i, "ok": True})
        except Exception as e:
            with metrics_lock:
                metrics["pool_errors"] += 1
            with lock:
                errors.append({"id": i, "error": str(e)})

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(20)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    return jsonify({
        "workers": 20,
        "pool_max": POOL_MAX,
        "success": len(results),
        "failed": len(errors),
        "errors": errors[:5],
    })


@app.route("/metrics")
def get_metrics():
    pool_info = {}
    if conn_pool and not conn_pool.closed:
        pool_info = {
            "min": conn_pool.minconn,
            "max": conn_pool.maxconn,
            "closed": conn_pool.closed,
        }
    return jsonify({**metrics, "pool": pool_info, "leaked": len(leaked_conns)})


@app.route("/db/reset-leak")
def reset_leak():
    """Oddaje wszystkie wyciekłe połączenia – reset scenariusza."""
    for conn in leaked_conns:
        try:
            put_conn(conn)
        except Exception:
            pass
    leaked_conns.clear()
    return jsonify({"status": "leaked connections returned", "pool_max": POOL_MAX})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
