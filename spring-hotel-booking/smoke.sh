#!/usr/bin/env bash
set -euo pipefail

# ===== Настройки =====
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8080}"
EUREKA_URL="${EUREKA_URL:-http://localhost:8761}"
HOTEL_DIR="${HOTEL_DIR:-/api/hotels}"
ROOMS_DIR="${ROOMS_DIR:-/api/rooms}"

# Аутентификация:
# 1) Если у тебя уже JWT — положи его в TOKEN (см. .env.sample).
# 2) Если JWT ещё нет и включён httpBasic — укажи ADMIN_USER/ADMIN_PASS.
AUTH_HEADER_USER=""
AUTH_HEADER_ADMIN=""
if [[ -n "${TOKEN_USER:-}" ]]; then
  AUTH_HEADER_USER=(-H "Authorization: Bearer ${TOKEN_USER}")
fi
if [[ -n "${TOKEN_ADMIN:-}" ]]; then
  AUTH_HEADER_ADMIN=(-H "Authorization: Bearer ${TOKEN_ADMIN}")
elif [[ -n "${ADMIN_USER:-}" && -n "${ADMIN_PASS:-}" ]]; then
  AUTH_HEADER_ADMIN=(--user "${ADMIN_USER}:${ADMIN_PASS}")
fi

say() { echo -e "\n=== $* ==="; }
jpost() { curl -fsS "${@:1}" -H 'Content-Type: application/json' -d "${@: -1}"; }
jget() { curl -fsS "${@:1}"; }

# ===== 0. Базовые health =====
say "Проверка health всех сервисов"
curl -fsS "${EUREKA_URL}/actuator/health" | jq .
curl -fsS "${GATEWAY_URL}/actuator/health" | jq . || true
curl -fsS "http://localhost:8081/actuator/health" | jq . || true
curl -fsS "http://localhost:8082/actuator/health" | jq . || true

# ===== 1. Смотрим зарегистрированные экземпляры в Eureka =====
say "Проверка регистрации сервисов в Eureka (ожидаем 3 клиента: gateway, hotel, booking)"
curl -fsS "${EUREKA_URL}/eureka/apps" | head -n 40 || true

# ===== 2. Проверка маршрутов Gateway =====
say "Список маршрутов Gateway"
curl -fsS "${GATEWAY_URL}/actuator/gateway/routes" | jq . || true

# ===== 3. Админ создаёт отель =====
say "Создание отеля (ADMIN)"
HOTEL_ID=$(jpost -X POST "${GATEWAY_URL}${HOTEL_DIR}" "${AUTH_HEADER_ADMIN[@]}" \
'{"name":"Test Hotel","address":"Main street 1"}' | jq -r '.id')
echo "HOTEL_ID=${HOTEL_ID}"

# ===== 4. Админ создаёт номер =====
say "Создание номера в отеле (ADMIN)"
ROOM_ID=$(jpost -X POST "${GATEWAY_URL}${ROOMS_DIR}" "${AUTH_HEADER_ADMIN[@]}" \
"{\"hotelId\":${HOTEL_ID},\"number\":\"101\",\"available\":true,\"times_booked\":0}" | jq -r '.id')
echo "ROOM_ID=${ROOM_ID}"

# ===== 5. Пользователь получает список отелей/номеров =====
say "GET /api/hotels (USER)"
jget "${GATEWAY_URL}${HOTEL_DIR}" "${AUTH_HEADER_USER[@]}" | jq .

say "GET /api/rooms (USER)"
jget "${GATEWAY_URL}${ROOMS_DIR}" "${AUTH_HEADER_USER[@]}" | jq .

say "GET /api/rooms/recommend (USER) — сортировка по times_booked"
jget "${GATEWAY_URL}${ROOMS_DIR}/recommend" "${AUTH_HEADER_USER[@]}" | jq .

# ===== 6. (опционально) Проверка внутренних эндпойнтов Hotel напрямую =====
say "INTERNAL: confirm-availability напрямую на 8081 (симуляция шага саги)"
curl -fsS -X POST "http://localhost:8081/api/rooms/${ROOM_ID}/confirm-availability" \
  -H 'Content-Type: application/json' -d '{"startDate":"2025-11-01","endDate":"2025-11-05","requestId":"demo-req-1"}' | jq .

say "INTERNAL: release (компенсация)"
curl -fsS -X POST "http://localhost:8081/api/rooms/${ROOM_ID}/release" \
  -H 'Content-Type: application/json' -d '{"requestId":"demo-req-1"}' | jq .

echo -e "\n✓ Smoke-тесты выполнены."
