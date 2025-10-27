#!/usr/bin/env bash
set -euo pipefail

# ===== настройки портов =====
EUREKA_PORT=${EUREKA_PORT:-8761}
HOTEL_PORT=${HOTEL_PORT:-8081}
BOOKING_PORT=${BOOKING_PORT:-8082}
GATEWAY_PORT=${GATEWAY_PORT:-8080}

EUREKA_URL="http://localhost:${EUREKA_PORT}"
EUREKA_API="${EUREKA_URL}/eureka/"
HEALTH_WAIT_SECONDS=${HEALTH_WAIT_SECONDS:-60}

# ===== утилиты =====
log() { printf "\033[1;34m[%s]\033[0m %s\n" "$(date '+%H:%M:%S')" "$*"; }
fail() { printf "\033[1;31mERROR:\033[0m %s\n" "$*" >&2; exit 1; }

wait_health() {
  local url="$1"
  local deadline=$((SECONDS + HEALTH_WAIT_SECONDS))
  log "⏳ Жду готовности ${url}"
  until curl -fsS "${url}" >/dev/null 2>&1; do
    if (( SECONDS > deadline )); then
      fail "Не дождался ${url} за ${HEALTH_WAIT_SECONDS}с"
    fi
    sleep 2
  done
  log "✅ Готов: ${url}"
}

kill_if_running() {
  local pat="$1"
  if pgrep -f "$pat" >/dev/null 2>&1; then
    log "⛔ Останавливаю $pat"
    pkill -f "$pat" || true
    sleep 1
  fi
}

# ===== подготовка =====
log "🔨 Maven build (все модули, без тестов)"
mvn -DskipTests clean package

# ===== старт Eureka =====
kill_if_running "eureka-server.*\.jar"
log "🚀 Eureka"
nohup java -jar eureka-server/target/eureka-server-0.0.1-SNAPSHOT.jar \
  --server.port="${EUREKA_PORT}" \
  > .eureka.log 2>&1 &

wait_health "${EUREKA_URL}/actuator/health"

# ===== старт Hotel =====
kill_if_running "hotel-service.*\.jar"
log "🚀 Hotel Service"
nohup java -jar hotel-service/target/hotel-service-0.0.1-SNAPSHOT.jar \
  --server.port="${HOTEL_PORT}" \
  --eureka.client.serviceUrl.defaultZone="${EUREKA_API}" \
  > .hotel.log 2>&1 &

wait_health "http://localhost:${HOTEL_PORT}/actuator/health"

# ===== старт Booking =====
kill_if_running "booking-service.*\.jar"
log "🚀 Booking Service"
nohup java -jar booking-service/target/booking-service-0.0.1-SNAPSHOT.jar \
  --server.port="${BOOKING_PORT}" \
  --eureka.client.serviceUrl.defaultZone="${EUREKA_API}" \
  > .booking.log 2>&1 &

wait_health "http://localhost:${BOOKING_PORT}/actuator/health"

# ===== старт Gateway =====
kill_if_running "api-gateway.*\.jar"
log "🚀 API Gateway"
nohup java -jar api-gateway/target/api-gateway-0.0.1-SNAPSHOT.jar \
  --server.port="${GATEWAY_PORT}" \
  --eureka.client.serviceUrl.defaultZone="${EUREKA_API}" \
  > .gateway.log 2>&1 &

wait_health "http://localhost:${GATEWAY_PORT}/actuator/health"

# ===== смоук-проверки =====
log "🔍 Проверяю регистрацию в Eureka (актуально, если включён discovery)"
curl -fsS "${EUREKA_URL}/actuator/health" >/dev/null && log "Eureka UP"
log "🌐 Gateway UP: http://localhost:${GATEWAY_PORT}"

log "🧪 Smoke через Gateway:"
set +e
curl -s "http://localhost:${GATEWAY_PORT}/api/hotels" | jq . || true
curl -s "http://localhost:${GATEWAY_PORT}/api/rooms" | jq . || true
curl -s "http://localhost:${GATEWAY_PORT}/api/rooms/recommend" | jq . || true
set -e

log "📜 Логи: .eureka.log  .hotel.log  .booking.log  .gateway.log"
