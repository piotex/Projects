"""
Wersja podstawowa – jedno połączenie bez puli.
Używana do porównania z main.py (z pulą).
"""
import os
import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = int(os.environ.get("DB_PORT", 5432))
DB_NAME = os.environ.get("DB_NAME", "appdb")
DB_USER = os.environ.get("DB_USER", "appuser")
DB_PASS = os.environ.get("DB_PASS", "apppassword")


def get_conn():
    return psycopg2.connect(
        host=DB_HOST, port=DB_PORT,
        database=DB_NAME, user=DB_USER, password=DB_PASS,
        connect_timeout=5,
    )


@app.route("/")
def healthcheck():
    return jsonify({"status": "ok", "db_host": DB_HOST})


@app.route("/db/ok")
def db_ok():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT 1 AS ping, now() AS ts;")
        row = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify({"result": row[0], "ts": str(row[1])})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
