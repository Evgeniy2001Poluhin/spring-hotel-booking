#!/usr/bin/env bash
set -euo pipefail

# Параметры (можно переопределять окружением)
GATEWAY_URL=${GATEWAY_URL:-http://localhost:8080}
HOTEL_URL=${HOTEL_URL:-http://localhost:8081}

# Нужен jq для красивого вывода
have_jq=1
command -v jq >/dev/null 2>&1 || have_jq=0
pp() { if [ "$have_jq" -eq 1 ]; then jq .; else cat; fi; }

say() { printf "\033[1;34m[%s]\033[0m %s\n" "$(date '+%H:%M:%S')" "$*"; }

# Проверка готовности сервисов
check_up () {
  local url="$1"
  curl -fsS "$url" >/dev/null
}

say "Проверяю готовность сервисов…"
check_up "$GATEWAY_URL/actuator/health" && echo "✅ Gateway UP" || echo "⚠️ Gateway недоступен"
check_up "$HOTEL_URL/actuator/health" && echo "✅ Hotel UP" || echo "❌ Hotel недоступен — остановка" && exit 1

# Определяем, будет ли доступ через Gateway
use_gateway=0
if curl -fsS "$GATEWAY_URL/actuator/health" >/dev/null 2>&1; then
  # проверяем, отдаются ли /api/hotels через gateway (не 404)
  code=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/api/hotels")
  if [ "$code" != "404" ] && [ "$code" != "000" ]; then
    use_gateway=1
  fi
fi

if [ "$use_gateway" -eq 1 ]; then
  BASE="$GATEWAY_URL"
  echo "➡️  Использую Gateway: $BASE"
else
  BASE="$HOTEL_URL"
  echo "➡️  Использую прямой Hotel: $BASE"
fi

say "Создаю отели…"
curl -s -X POST "$BASE/api/hotels" -H 'Content-Type: application/json' \
  -d '{"name":"Demo Hotel A","address":"Center st. 1"}' | pp || true

curl -s -X POST "$BASE/api/hotels" -H 'Content-Type: application/json' \
  -d '{"name":"Demo Hotel B","address":"Main ave. 2"}' | pp || true

say "Текущий список отелей:"
curl -s "$BASE/api/hotels" | pp

say "Создаю номера…"
# В твоём Hotel сервисе поле hotelId называется hotelId (по твоему ответу)
curl -s -X POST "$BASE/api/rooms" -H 'Content-Type: application/json' \
  -d '{"hotelId":1,"number":"101","available":true,"timesBooked":0}' | pp || true

curl -s -X POST "$BASE/api/rooms" -H 'Content-Type: application/json' \
  -d '{"hotelId":1,"number":"102","available":true,"timesBooked":0}' | pp || true

curl -s -X POST "$BASE/api/rooms" -H 'Content-Type: application/json' \
  -d '{"hotelId":2,"number":"201","available":true,"timesBooked":1}' | pp || true

say "Список всех номеров:"
curl -s "$BASE/api/rooms" | pp || true

say "Рекомендованные номера (sorted by times_booked):"
curl -s "$BASE/api/rooms/recommend" | pp || true

echo
say "Готово."
