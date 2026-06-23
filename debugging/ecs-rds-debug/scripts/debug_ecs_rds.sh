#!/bin/bash
# =============================================================================
# debug_ecs_rds.sh — Narzędzie do debugowania ECS <-> RDS
# =============================================================================
# Użycie:
#   ./debug_ecs_rds.sh <komenda> [opcje]
#
# Komendy:
#   check-all          Pełny przegląd: ALB, ECS, RDS
#   check-network      Łączność sieciowa (DNS, port, psql)
#   check-pool         Stan connection pool przez /metrics
#   check-rds          Metryki RDS (connections, CPU, latency)
#   trigger-slow N     Wywołaj N równoległych /db/slow (domyślnie 6)
#   trigger-leak N     Wywołaj N razy /db/leak
#   trigger-hammer     Wywołaj /db/hammer (20 workerów)
#   reset-leak         Odwróć wyciek przez /db/reset-leak
#   find-errors LOG    Policz i pokaż ostatni ERROR w logu
#   logs               Ogon logów ECS (CloudWatch)
# =============================================================================

set -euo pipefail

# ── Konfiguracja (override przez zmienne środowiskowe) ────────────────────────
ALB_HOST="${ALB_HOST:-$(terraform -chdir=../terraform output -raw alb_dns_name 2>/dev/null || echo 'localhost')}"
BASE_URL="http://${ALB_HOST}"
CLUSTER="${ECS_CLUSTER:-test-ecs-rds-debug}"
SERVICE="${ECS_SERVICE:-test-ecs-rds-debug}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
LOG_GROUP="${LOG_GROUP:-/ecs/test-ecs-rds-debug}"

RED='\033[0;31m'; YEL='\033[0;33m'; GRN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GRN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YEL}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERR ]${NC}  $*"; }
sep()   { echo "────────────────────────────────────────────────────"; }

# ── find-errors (z rozmowy rekrutacyjnej) ─────────────────────────────────────
find_errors() {
    local log_file="${1:-}"
    if [ $# -ne 1 ] || [ ! -f "$log_file" ]; then
        echo "Usage: $0 find-errors <log_file>"
        exit 1
    fi

    local err_lines
    err_lines=$(grep "ERROR" "$log_file" 2>/dev/null || true)

    echo "ERROR count: $(echo "$err_lines" | grep -c . || echo 0)"
    echo "Last ERROR:  $(echo "$err_lines" | tail -n1)"
}

# ── check-network ─────────────────────────────────────────────────────────────
check_network() {
    sep; info "=== NETWORK CHECK ==="

    # 1. DNS resolution
    info "1. DNS lookup ALB..."
    if nslookup "$ALB_HOST" >/dev/null 2>&1; then
        echo "   ✅  DNS OK: $ALB_HOST"
    else
        error "   DNS nie działa dla: $ALB_HOST"
    fi

    # 2. HTTP healthcheck
    info "2. HTTP healthcheck (ALB → ECS)..."
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$BASE_URL/" || echo "000")
    if [ "$http_code" = "200" ]; then
        echo "   ✅  HTTP 200"
    else
        error "   HTTP $http_code — aplikacja nie odpowiada lub 5xx"
    fi

    # 3. Latency
    info "3. Latency p95 (10 requests)..."
    local times=()
    for _ in $(seq 1 10); do
        t=$(curl -s -o /dev/null -w "%{time_total}" --max-time 5 "$BASE_URL/" 2>/dev/null || echo "5")
        times+=("$t")
    done
    echo "   Czasy: ${times[*]}"

    # 4. DB endpoint port check (jeśli mamy dostęp do RDS endpoint)
    if [ -n "${DB_HOST:-}" ]; then
        info "4. Port 5432 na RDS..."
        if nc -zv "$DB_HOST" 5432 -w 3 2>&1 | grep -q "succeeded"; then
            echo "   ✅  Port 5432 otwarty"
        else
            error "   Port 5432 ZABLOKOWANY — sprawdź Security Group RDS"
        fi
    fi
}

# ── check-pool ────────────────────────────────────────────────────────────────
check_pool() {
    sep; info "=== CONNECTION POOL STATUS ==="
    local resp
    resp=$(curl -s --max-time 5 "$BASE_URL/metrics" || echo '{"error":"timeout"}')
    echo "$resp" | python3 -m json.tool 2>/dev/null || echo "$resp"

    local pool_errors
    pool_errors=$(echo "$resp" | grep -o '"pool_errors": *[0-9]*' | grep -o '[0-9]*' || echo "?")
    local leaked
    leaked=$(echo "$resp" | grep -o '"leaked": *[0-9]*' | grep -o '[0-9]*' || echo "?")

    sep
    echo "  pool_errors : $pool_errors"
    echo "  leaked      : $leaked"

    if [ "$pool_errors" != "0" ] && [ "$pool_errors" != "?" ]; then
        warn "Pool errors > 0 → połączenia wyczerpane lub wyciek!"
        warn "Sprawdź RDS CloudWatch: DatabaseConnections"
    fi
    if [ "$leaked" != "0" ] && [ "$leaked" != "?" ]; then
        warn "$leaked wyciekłych połączeń — wywołaj: $0 reset-leak"
    fi
}

# ── check-rds ─────────────────────────────────────────────────────────────────
check_rds() {
    sep; info "=== RDS METRICS (CloudWatch) ==="
    local db_id="${RDS_ID:-test-ecs-rds-debug}"
    local end_time; end_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local start_time; start_time=$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
        || date -u -v -5M +%Y-%m-%dT%H:%M:%SZ)

    metrics_to_check=(
        "DatabaseConnections"
        "CPUUtilization"
        "FreeableMemory"
        "ReadLatency"
        "WriteLatency"
        "DiskQueueDepth"
    )

    for metric in "${metrics_to_check[@]}"; do
        local val
        val=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/RDS \
            --metric-name "$metric" \
            --dimensions "Name=DBInstanceIdentifier,Value=$db_id" \
            --start-time "$start_time" \
            --end-time "$end_time" \
            --period 60 \
            --statistics Average \
            --region "$AWS_REGION" \
            --query 'Datapoints[-1].Average' \
            --output text 2>/dev/null || echo "N/A")
        printf "  %-26s %s\n" "$metric:" "$val"
    done

    sep
    info "KLUCZOWA METRYKA: DatabaseConnections"
    info "Formuła: ECS_tasks * pool_max = max połączeń aplikacji"
    warn "Jeśli DatabaseConnections ≈ max_connections (RDS param group) → aplikacja się dławi!"
}

# ── check-all ─────────────────────────────────────────────────────────────────
check_all() {
    sep; info "=== PEŁNY PRZEGLĄD ECS <-> RDS ==="
    echo ""

    # ECS service status
    info "ECS Service:"
    aws ecs describe-services \
        --cluster "$CLUSTER" \
        --services "$SERVICE" \
        --region "$AWS_REGION" \
        --query 'services[0].{running:runningCount,desired:desiredCount,pending:pendingCount,status:status}' \
        --output table 2>/dev/null || warn "Nie można pobrać ECS service (sprawdź CLUSTER/SERVICE)"

    echo ""
    check_network
    echo ""
    check_pool
    echo ""
    check_rds
    echo ""

    # Podpowiedź diagnostyczna
    sep
    info "SCHEMAT DIAGNOZY:"
    echo "  1. HTTP 5xx + latency ↑ + CPU OK + RAM OK?"
    echo "     → Podejrzenie: connection pool lub RDS problem"
    echo ""
    echo "  2. Sprawdź /metrics:"
    echo "     pool_errors > 0 → pula wyczerpana"
    echo "     leaked > 0      → wyciek (wywołaj reset-leak)"
    echo ""
    echo "  3. CloudWatch RDS — DatabaseConnections:"
    echo "     ≈ max_connections → za mały pool lub za dużo tasków ECS"
    echo "     Formuła: ECS_tasks * pool_max ≤ RDS max_connections"
    echo ""
    echo "  4. CloudWatch RDS — ReadLatency / WriteLatency:"
    echo "     wolne zapytania blokują połączenia w puli"
}

# ── trigger-slow ──────────────────────────────────────────────────────────────
trigger_slow() {
    local n="${1:-6}"
    sep; warn "=== TRIGGER: $n równoległych /db/slow ==="
    warn "Każde trzyma połączenie przez ~15s. Pool_max domyślnie 5."
    warn "Po $n requestach: pool wyczerpany → 503 na /db/ok"
    echo ""

    for i in $(seq 1 "$n"); do
        curl -s --max-time 30 "$BASE_URL/db/slow" &
        echo "  Wysłano request #$i (background)"
    done

    sleep 2
    info "Sprawdzam /db/ok (powinno zwrócić 503 lub timeout)..."
    curl -s -w "\nHTTP: %{http_code}\n" "$BASE_URL/db/ok"
    echo ""
    info "Stan puli:"
    curl -s "$BASE_URL/metrics" | python3 -m json.tool 2>/dev/null

    wait
    info "Wszystkie slow query zakończone."
}

# ── trigger-leak ──────────────────────────────────────────────────────────────
trigger_leak() {
    local n="${1:-6}"
    sep; warn "=== TRIGGER: $n razy /db/leak ==="
    for i in $(seq 1 "$n"); do
        resp=$(curl -s --max-time 5 "$BASE_URL/db/leak" || echo '{}')
        leaked=$(echo "$resp" | grep -o '"leaked": *[0-9]*' | grep -o '[0-9]*' || echo "?")
        printf "  leak #%d → leaked=%s\n" "$i" "$leaked"
    done
    echo ""
    info "Po wyczerpaniu puli kolejne /db/ok zwrócą 503:"
    curl -s -w "\nHTTP: %{http_code}\n" "$BASE_URL/db/ok"
}

# ── trigger-hammer ────────────────────────────────────────────────────────────
trigger_hammer() {
    sep; warn "=== TRIGGER: /db/hammer (20 workerów) ==="
    warn "Wywołuje 20 wątków jednocześnie – wyczerpuje pulę natychmiast"
    curl -s --max-time 60 "$BASE_URL/db/hammer" | python3 -m json.tool 2>/dev/null
    echo ""
    check_pool
}

# ── reset-leak ────────────────────────────────────────────────────────────────
reset_leak() {
    sep; info "=== RESET: oddaję wyciekłe połączenia ==="
    curl -s "$BASE_URL/db/reset-leak" | python3 -m json.tool 2>/dev/null
    echo ""
    check_pool
}

# ── logs ─────────────────────────────────────────────────────────────────────
show_logs() {
    sep; info "=== ECS LOGS (CloudWatch) ==="
    aws logs tail "$LOG_GROUP" \
        --since 5m \
        --follow \
        --region "$AWS_REGION" 2>/dev/null || \
    warn "Nie można pobrać logów — sprawdź LOG_GROUP i uprawnienia AWS"
}

# ── main ─────────────────────────────────────────────────────────────────────
main() {
    local cmd="${1:-help}"
    shift || true

    case "$cmd" in
        check-all)      check_all ;;
        check-network)  check_network ;;
        check-pool)     check_pool ;;
        check-rds)      check_rds ;;
        trigger-slow)   trigger_slow "${1:-6}" ;;
        trigger-leak)   trigger_leak "${1:-6}" ;;
        trigger-hammer) trigger_hammer ;;
        reset-leak)     reset_leak ;;
        find-errors)    find_errors "${1:-}" ;;
        logs)           show_logs ;;
        *)
            echo ""
            echo "Użycie: $0 <komenda>"
            echo ""
            echo "Komendy:"
            echo "  check-all          Pełny przegląd: ALB + ECS + RDS"
            echo "  check-network      Sprawdź DNS, HTTP, port 5432"
            echo "  check-pool         Stan connection pool (/metrics)"
            echo "  check-rds          Metryki CloudWatch RDS"
            echo "  trigger-slow N     N równoległych /db/slow (wyczerpuje pulę)"
            echo "  trigger-leak N     N razy /db/leak (wyciek połączeń)"
            echo "  trigger-hammer     20 workerów jednocześnie"
            echo "  reset-leak         Oddaj wyciekłe połączenia"
            echo "  find-errors LOG    Policz ERROR w pliku logu"
            echo "  logs               Ogon logów ECS z CloudWatch"
            echo ""
            echo "Zmienne środowiskowe:"
            echo "  ALB_HOST    DNS ALB (domyślnie: terraform output)"
            echo "  CLUSTER     Nazwa klastra ECS"
            echo "  SERVICE     Nazwa serwisu ECS"
            echo "  RDS_ID      Identifier instancji RDS"
            echo "  AWS_REGION  Region (domyślnie eu-central-1)"
            echo "  LOG_GROUP   CloudWatch log group"
            ;;
    esac
}

main "$@"
