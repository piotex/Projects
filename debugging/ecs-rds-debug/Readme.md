# ECS ↔ RDS Debugging Lab

Laboratorium do ćwiczenia debugowania scenariuszy z rozmowy rekrutacyjnej:

```
ALB → ECS (Fargate) → RDS PostgreSQL
CPU: 15% | RAM: 40% | HTTP 5xx ↑ | Latency: 300ms → 12s
Log: DB connection timeout
```

---

## Architektura

```
Internet
   │
   ▼
[ALB :80]
   │
   ├──► [ECS Task 1] ──┐
   └──► [ECS Task 2] ──┤──► [RDS PostgreSQL]
                        │    max_connections=25
                   pool_max=5
             (2 taski × 5 = 10 połączeń)
```

**Kluczowy wzór:**
```
max_aktywnych_połączeń = ecs_desired_count × pool_max
                       ≤ RDS max_connections
```

---

## Setup infrastruktury

### 1. Prerequisity

```bash
export HOME=$(pwd)
export TF_VAR_db_password="TwojeSilneHaslo123!"
```

### 2. Deploy Terraform

```bash
cd $HOME/ecs-rds-debug/terraform

terraform init -backend-config=environments/test/backend.hcl
terraform plan -var-file=environments/test/terraform.tfvars -out=tfplan
terraform apply tfplan

ALB_HOST=$(terraform output -raw alb_dns_name)     && echo $ALB_HOST
ECR_REPO=$(terraform output -raw ecr_repository_url) && echo $ECR_REPO
RDS_HOST=$(terraform output -raw rds_endpoint)       && echo $RDS_HOST
```

### 3. Build i push obrazu Docker

```bash
cd $HOME/ecs-rds-debug/app

AWS_REGION="eu-central-1"
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "$ECR_REPO"

docker build -t "$ECR_REPO:latest" .
docker push "$ECR_REPO:latest"
```

### 4. Wymuś nowy deployment ECS

```bash
aws ecs update-service \
    --cluster test-ecs-rds-debug \
    --service test-ecs-rds-debug \
    --force-new-deployment \
    --region eu-central-1
```

---

## Endpointy aplikacji

| Endpoint          | Opis                                                       |
|-------------------|------------------------------------------------------------|
| `GET /`           | Healthcheck                                                |
| `GET /db/ok`      | Szybkie zapytanie — zwraca SELECT 1                        |
| `GET /db/slow`    | Wolne zapytanie (15s) — trzyma połączenie w puli           |
| `GET /db/leak`    | Wyciek — pobiera połączenie i **nie oddaje** go do puli    |
| `GET /db/hammer`  | 20 workerów jednocześnie — natychmiast wyczerpuje pulę     |
| `GET /metrics`    | Aktualny stan puli + licznik błędów                        |
| `GET /db/reset-leak` | Oddaje wyciekłe połączenia — reset scenariusza          |

---

## Scenariusze debugowania

### Scenariusz 1: Connection Pool Exhaustion (wyczerpanie puli)

**Objawy:** HTTP 5xx, latency 12s, log: `DB connection timeout`, CPU 15%, RAM 40%

```bash
export ALB_HOST="<twój-alb-dns>"

# Krok 1 — sprawdź stan przed
curl http://$ALB_HOST/metrics

# Krok 2 — wywołaj 6 wolnych zapytań (pool_max=5 → wyczerpany)
for i in $(seq 1 6); do
    curl -s http://$ALB_HOST/db/slow &
done

# Krok 3 — sprawdź /db/ok (powinno zwrócić 503)
sleep 1
curl -v http://$ALB_HOST/db/ok

# Krok 4 — sprawdź metryki
curl http://$ALB_HOST/metrics
```

**Co widzisz:**
- `pool_errors` rośnie
- `/db/ok` zwraca `503 {"error": "DB connection timeout"}`
- CPU RDS: 10%, DatabaseConnections: 100%

**Odpowiedź na pytanie z rozmowy:**
> Dlaczego CPU bazy 10%, ale aplikacja się dławi?
>
> 10 tasków × pool_max=5 = 50 żądanych połączeń > max_connections=25 (RDS).
> Aplikacja wisi w kolejce na połączenie, nie w zapytaniu SQL.

---

### Scenariusz 2: Connection Leak (wyciek)

```bash
# Wywołaj 6 razy /db/leak — po 5 pula martwa
for i in $(seq 1 6); do
    curl http://$ALB_HOST/db/leak
    echo ""
done

# Sprawdź
curl http://$ALB_HOST/metrics

# Fix — oddaj połączenia
curl http://$ALB_HOST/db/reset-leak
curl http://$ALB_HOST/metrics
```

---

### Scenariusz 3: Skrypt find_errors.sh

```bash
# Generuj przykładowy log
docker logs ecs-rds-debug 2>&1 > /tmp/app.log

# Uruchom skrypt
./scripts/debug_ecs_rds.sh find-errors /tmp/app.log
# Output:
# ERROR count: 8
# Last ERROR: 2026-06-23 [ERROR] Pool exhausted: ...
```

---

## Skrypt debug_ecs_rds.sh — pełny przewodnik

```bash
cd $HOME/ecs-rds-debug

# Konfiguracja przez zmienne
export ALB_HOST="test-alb-123456.eu-central-1.elb.amazonaws.com"
export CLUSTER="test-ecs-rds-debug"
export SERVICE="test-ecs-rds-debug"
export RDS_ID="test-ecs-rds-debug"
export AWS_REGION="eu-central-1"
export LOG_GROUP="/ecs/test-ecs-rds-debug"

# Pełny przegląd
./scripts/debug_ecs_rds.sh check-all

# Tylko sieć
./scripts/debug_ecs_rds.sh check-network

# Stan puli
./scripts/debug_ecs_rds.sh check-pool

# Metryki RDS z CloudWatch
./scripts/debug_ecs_rds.sh check-rds

# Wyzwól wyczerpanie puli (6 slow queries)
./scripts/debug_ecs_rds.sh trigger-slow 6

# Wyzwól wyciek (5 leaked connections)
./scripts/debug_ecs_rds.sh trigger-leak 5

# 20 workerów naraz
./scripts/debug_ecs_rds.sh trigger-hammer

# Napraw wyciek
./scripts/debug_ecs_rds.sh reset-leak

# Logi ECS (ostatnie 5 minut)
./scripts/debug_ecs_rds.sh logs
```

---

## Kluczowe metryki AWS do sprawdzenia

### CloudWatch — RDS

```bash
# DatabaseConnections (kluczowa!)
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name DatabaseConnections \
    --dimensions Name=DBInstanceIdentifier,Value=test-ecs-rds-debug \
    --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 60 --statistics Maximum \
    --region eu-central-1

# Inne ważne metryki
# CPUUtilization, FreeableMemory, ReadLatency, WriteLatency, DiskQueueDepth
```

### CloudWatch — ALB

```bash
# HTTPCode_Target_5XX_Count
aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name HTTPCode_Target_5XX_Count \
    --dimensions Name=LoadBalancer,Value=<ALB-ARN-suffix> \
    --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 60 --statistics Sum \
    --region eu-central-1
```

### ECS — sprawdź taski

```bash
aws ecs list-tasks \
    --cluster test-ecs-rds-debug \
    --service-name test-ecs-rds-debug \
    --region eu-central-1

# Logi z konkretnego taska
aws logs tail /ecs/test-ecs-rds-debug --since 5m --follow --region eu-central-1
```

---

## Metodyczne zawężanie problemu (z rozmowy)

```
Krok 1 — Czy problem globalny?
├── ALB: HTTPCode_Target_5XX_Count ↑
├── ALB: TargetResponseTime ↑
└── ECS: restarts tasków?

Krok 2 — Czy aplikacja dochodzi do bazy?
├── curl http://ALB/db/ok → 503? → pool problem
├── nc -zv RDS_HOST 5432  → timeout? → Security Group
└── nslookup RDS_HOST     → NXDOMAIN? → DNS/VPC

Krok 3 — Sprawdź RDS
├── DatabaseConnections ≈ max_connections → pool exhaustion
├── CPUUtilization ↑ → wolne zapytania
└── ReadLatency/WriteLatency ↑ → blokady

Krok 4 — Sprawdź aplikację
├── /metrics → pool_errors, leaked
├── pool_max × ecs_tasks vs RDS max_connections
└── Logi: "Pool exhausted" lub "connection timeout"
```

---

## Cleanup

```bash
cd $HOME/ecs-rds-debug/terraform
terraform destroy -var-file=environments/test/terraform.tfvars
```
