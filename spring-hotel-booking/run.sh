#!/usr/bin/env bash
set -euo pipefail

# ---- Сборка исполняемых JAR ----
echo "=== Сборка исполняемых JAR (boot-jar) ==="
mvn -DskipTests clean package

# ---- Проверка, что в манифестах есть Main-Class ----
echo "=== Проверка манифестов JAR ==="
for jar in \
  "eureka-server/target/eureka-server-0.0.1-SNAPSHOT.jar" \
  "hotel-service/target/hotel-service-0.0.1-SNAPSHOT.jar" \
  "booking-service/target/booking-service-0.0.1-SNAPSHOT.jar" \
  "api-gateway/target/api-gateway-0.0.1-SNAPSHOT.jar"
do
  if ! unzip -p "$jar" META-INF/MANIFEST.MF | grep -q "Main-Class:" ; then
    echo "В JAR нет Main-Class: $jar"
    exit 1
  fi
done

# ---- Старт сервисов по порядку ----
echo "=== Запуск Eureka ==="
nohup java -jar eureka-server/target/eureka-server-0.0.1-SNAPSHOT.jar \
  > .eureka.log 2>&1 &

# ждём Eureka
echo -n "→ Жду готовности http://localhost:8761/actuator/health "
until curl -fsS http://localhost:8761/actuator/health >/dev/null 2>&1; do
  echo -n "."
  sleep 2
done
echo " OK"

echo "=== Запуск Hotel Service ==="
nohup java -jar hotel-service/target/hotel-service-0.0.1-SNAPSHOT.jar \
  --eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
  > .hotel.log 2>&1 &

echo "=== Запуск Booking Service ==="
nohup java -jar booking-service/target/booking-service-0.0.1-SNAPSHOT.jar \
  --eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
  > .booking.log 2>&1 &

echo "=== Запуск API Gateway ==="
nohup java -jar api-gateway/target/api-gateway-0.0.1-SNAPSHOT.jar \
  --eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
  > .gateway.log 2>&1 &

echo "=== Всё запущено ==="
echo "Логи: .eureka.log  .hotel.log  .booking.log  .gateway.log"
