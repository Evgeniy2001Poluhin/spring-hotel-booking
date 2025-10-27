#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

kill_java() {
  pkill -f 'eureka-server.*\.jar' 2>/dev/null || true
  pkill -f 'hotel-service.*\.jar'  2>/dev/null || true
  pkill -f 'booking-service.*\.jar' 2>/dev/null || true
  pkill -f 'api-gateway.*\.jar'    2>/dev/null || true
}
start_eureka() {
  echo "== Eureka =="
  mvn -DskipTests -pl eureka-server -am clean package
  nohup java -jar eureka-server/target/eureka-server-0.0.1-SNAPSHOT.jar > .eureka.log 2>&1 &
  sleep 6
  curl -sf http://localhost:8761/actuator/health || (echo "Eureka health failed" && exit 1)
}
start_hotel() {
  echo "== hotel-service =="
  mvn -DskipTests -pl hotel-service -am clean package
  nohup java -jar hotel-service/target/hotel-service-0.0.1-SNAPSHOT.jar \
    --server.port=8081 \
    --eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
    > .hotel.log 2>&1 &
  sleep 6
  curl -sf http://localhost:8081/actuator/health || (echo "hotel-service health failed" && exit 1)
}
start_booking() {
  echo "== booking-service =="
  mvn -DskipTests -pl booking-service -am clean package
  nohup java -jar booking-service/target/booking-service-0.0.1-SNAPSHOT.jar \
    --server.port=8082 \
    --spring.application.name=BOOKING-SERVICE \
    --eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
    > .booking.log 2>&1 &
  sleep 6
  curl -sf http://localhost:8082/booking/ping || (echo "booking-service ping failed" && exit 1)
}
start_gateway() {
  echo "== api-gateway =="
  mvn -DskipTests -pl api-gateway -am clean package
  nohup java -jar api-gateway/target/api-gateway-0.0.1-SNAPSHOT.jar \
    --server.port=8080 \
    --eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
    > .gateway.log 2>&1 &
  sleep 6
  # если gateway пока не знает маршрут, /booking/ping может дать 503 — это ок до регистрации
}

show_eureka_and_routes() {
  echo "== Eureka apps (JSON) =="
  curl -s -H 'Accept: application/json' http://localhost:8761/eureka/apps | jq . | sed -n '1,120p'

  echo "== Gateway routes =="
  curl -s http://localhost:8080/actuator/gateway/routes | jq . || true
}

smoke() {
  echo "== Smoke checks =="
  echo "-- direct:"
  curl -s http://localhost:8082/booking/ping | jq .
  echo "-- via gateway:"
  curl -s http://localhost:8080/booking/ping | jq . || true
}

main() {
  cd "$ROOT_DIR"
  kill_java
  start_eureka
  start_hotel
  start_booking
  start_gateway
  show_eureka_and_routes
  smoke
  echo "== Done =="
}

main
