#!/usr/bin/env bash
set -euo pipefail

GATEWAY_URL="${GATEWAY_URL:-http://localhost:8080}"
EUREKA_URL="${EUREKA_URL:-http://localhost:8761}"
ADMIN_USER="${ADMIN_USER:-}"
ADMIN_PASS="${ADMIN_PASS:-}"

echo "[SMOKE] Eureka health:"
curl -fsS "$EUREKA_URL/actuator/health" | jq .; echo

echo "[SMOKE] Gateway health:"
if curl -fsS "$GATEWAY_URL/actuator/health" >/dev/null 2>&1; then
  curl -fsS "$GATEWAY_URL/actuator/health" | jq .; echo
else
  # пробуем с базовой аутентификацией, если заданы креды
  if [[ -n "$ADMIN_USER" && -n "$ADMIN_PASS" ]] && \
     curl -u "$ADMIN_USER:$ADMIN_PASS" -fsS "$GATEWAY_URL/actuator/health" >/dev/null 2>&1; then
    curl -u "$ADMIN_USER:$ADMIN_PASS" -fsS "$GATEWAY_URL/actuator/health" | jq .; echo
  else
    echo "⚠️  /actuator/health возвращает 401 (это ок). Продолжаю проверку по функциональным маршрутам…"
  fi
fi

echo "[SMOKE] Hotels через Gateway:"
curl -fsS "$GATEWAY_URL/api/hotels" | jq .; echo

echo "[SMOKE] Booking ping через Gateway:"
curl -fsS "$GATEWAY_URL/booking/ping" | jq .; echo

echo "[SMOKE] Зарегистрированные приложения в Eureka:"
curl -fsS "$EUREKA_URL/eureka/apps" | sed -n 's:.*<name>\(.*\)</name>.*:\1:p' | sort -u

echo "✅ SMOKE OK"
