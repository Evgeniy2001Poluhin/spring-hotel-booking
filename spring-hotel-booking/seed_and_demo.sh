#!/usr/bin/env bash
set -euo pipefail

# 0) быстрая проверка сервисов
echo "[CHK] services:"
curl -s http://localhost:8761/actuator/health | jq . >/dev/null || { echo "Eureka DOWN"; exit 1; }
curl -s http://localhost:8081/actuator/health | jq . >/dev/null || { echo "Hotel DOWN"; exit 1; }
curl -s http://localhost:8080/actuator | jq . >/dev/null || echo "Gateway actuator закрыт (это ок)"

# 1) гарантируем, что есть минимум 1 отель и 2 комнаты
echo "[SEED] hotels:"
curl -s http://localhost:8081/api/hotels | jq .

# если отелей нет — создадим базовый
HOT_CNT=$(curl -s http://localhost:8081/api/hotels | jq 'length')
if [ "${HOT_CNT:-0}" -eq 0 ]; then
  curl -s -X POST http://localhost:8081/api/hotels \
    -H 'Content-Type: application/json' \
    -d '{"name":"Demo Hotel","address":"Center st. 1"}' | jq .
fi

# возьмём id первого отеля
HOTEL_ID=$(curl -s http://localhost:8081/api/hotels | jq '.[0].id')
echo "[SEED] using HOTEL_ID=$HOTEL_ID"

# создадим комнаты, если их пока нет
ROOM_CNT=$(curl -s http://localhost:8081/api/rooms | jq 'length')
if [ "${ROOM_CNT:-0}" -eq 0 ]; then
  echo "[SEED] rooms create"
  curl -s -X POST http://localhost:8081/api/rooms -H 'Content-Type: application/json' \
    -d "{\"hotelId\":${HOTEL_ID},\"number\":\"101\",\"available\":true}" | jq .
  curl -s -X POST http://localhost:8081/api/rooms -H 'Content-Type: application/json' \
    -d "{\"hotelId\":${HOTEL_ID},\"number\":\"102\",\"available\":true}" | jq .
fi

echo "[INFO] recommend:"
curl -s "http://localhost:8081/api/rooms/recommend?startDate=2025-11-10&endDate=2025-11-12" | jq .

# 2) (на всякий) убедимся, что booking-service жив
echo "[CHK] booking-service health (через gateway ping):"
curl -s http://localhost:8080/booking/ping | jq .

# 3) демо саги: автоподбор (равномерность по times_booked)
REQ_ID="demo-req-1"
echo "[BOOK] create (autoSelect=true), requestId=$REQ_ID"
curl -s -X POST "http://localhost:8080/booking" \
  -H "Content-Type: application/json" \
  -d "{\"userId\":1,\"autoSelect\":true,\"startDate\":\"2025-11-10\",\"endDate\":\"2025-11-12\",\"requestId\":\"${REQ_ID}\"}" | jq .

echo "[BOOK] idem repeat same requestId=$REQ_ID"
curl -s -X POST "http://localhost:8080/booking" \
  -H "Content-Type: application/json" \
  -d "{\"userId\":1,\"autoSelect\":true,\"startDate\":\"2025-11-10\",\"endDate\":\"2025-11-12\",\"requestId\":\"${REQ_ID}\"}" | jq .

echo "[BOOK] user history (userId=1):"
curl -s "http://localhost:8080/bookings?userId=1" | jq .
