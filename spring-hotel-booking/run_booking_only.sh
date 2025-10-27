#!/usr/bin/env bash
set -euo pipefail

pkill -f 'booking-service.*\.jar' 2>/dev/null || true

nohup java -jar booking-service/target/booking-service-0.0.1-SNAPSHOT.jar \
  --server.port=8082 \
  --spring.application.name=BOOKING-SERVICE \
  --eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
  > .booking.log 2>&1 &

echo "⏳ Стартуем booking-service..."
sleep 7

echo "== health =="
curl -s http://localhost:8082/actuator/health | jq . || true

echo "== smoke ping (direct) =="
curl -s http://localhost:8082/booking/smoke/ping | jq . || true

# Если не поднялся — показать лог
if ! curl -sf http://localhost:8082/actuator/health >/dev/null ; then
  echo "❌ Не поднялся, хвост .booking.log:"
  tail -n 200 .booking.log
fi
