#!/usr/bin/env bash
set -euo pipefail

echo "== health =="
for u in \
  http://localhost:8761/actuator/health \
  http://localhost:8080/actuator/health \
  http://localhost:8081/actuator/health \
  http://localhost:8082/actuator/health ; do
  printf "%-40s -> " "$u"
  curl -s "$u" | jq -r '.status // .components.status // .' || true
done

echo "== eureka apps =="
curl -s -H 'Accept: application/json' http://localhost:8761/eureka/apps | jq '.applications.application[].name' || true

echo "== routes =="
curl -s http://localhost:8080/actuator/gateway/routes | jq '.[].route_id' || true

echo "== smoke via gateway =="
echo "-- booking ping --"
curl -s http://localhost:8080/booking/smoke/ping | jq .
echo "-- hotels --"
curl -is http://localhost:8080/hotels | head -n 1
curl -s  http://localhost:8080/hotels | jq .
