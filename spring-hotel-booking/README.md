Spring Hotel Booking (Eureka + API Gateway + Services)

Микросервисный пример со связкой Eureka Server, API Gateway, Hotel Service и Booking Service.
Маршрутизация идёт через gateway, сервисы регистрируются в Eureka. В комплекте есть скрипты для быстрого запуска и смоук-проверок.

Состав

eureka-server — реестр сервисов: http://localhost:8761

api-gateway — точка входа, маршрутизация:

/booking/** → BOOKING-SERVICE

/hotels/** → HOTEL-SERVICE

hotel-service — список отелей, H2: http://localhost:8081

booking-service — smoke-эндпоинты, H2: http://localhost:8082

Требования

JDK 17

Maven 3.9+

(Опционально) jq для красивого вывода JSON

Быстрый старт
Вариант A — одним скриптом (рекомендуется)

Из корня репозитория:

./fix_all_services.sh


Скрипт:

собирает все модули (mvn -DskipTests clean package)

запускает Eureka, Hotel, Booking, Gateway

делает smoke-проверки

Вариант B — вручную

Сборка:

mvn -DskipTests clean package


Запуск (в разных терминалах/фонах):

java -jar eureka-server/target/eureka-server-0.0.1-SNAPSHOT.jar
java -jar hotel-service/target/hotel-service-0.0.1-SNAPSHOT.jar
java -jar booking-service/target/booking-service-0.0.1-SNAPSHOT.jar
java -jar api-gateway/target/api-gateway-0.0.1-SNAPSHOT.jar

Как проверить
Health
curl -s http://localhost:8761/actuator/health | jq .
curl -s http://localhost:8080/actuator/health | jq .
curl -s http://localhost:8081/actuator/health | jq .
curl -s http://localhost:8082/actuator/health | jq .


Ожидание: везде UP.

Регистрация в Eureka (JSON)
curl -s -H 'Accept: application/json' http://localhost:8761/eureka/apps | jq .


Ожидание: приложения BOOKING-SERVICE, HOTEL-SERVICE, API-GATEWAY присутствуют и UP.

Маршруты gateway (если включён actuator gateway)
curl -s http://localhost:8080/actuator/gateway/routes | jq '.[].route_id'


Ожидание: discovery-маршруты плюс

"hotel-route"
"booking-route"

Смоук-эндпоинты (через gateway)
# booking
curl -s http://localhost:8080/booking/smoke/ping | jq .
# hotels
curl -s http://localhost:8080/hotels | jq .


Ожидание:

{"service":"booking","status":"ok"}
["Hotel 1","Hotel 2","Hotel 3"]

Контрольный one-liner для сдачи
echo '== health =='; for u in 8761 8080 8081 8082; do curl -s http://localhost:$u/actuator/health | jq -r ".status // .components.status"; done; \
echo '== routes =='; curl -s http://localhost:8080/actuator/gateway/routes | jq '.[].route_id'; \
echo '== smoke ==' ; curl -s http://localhost:8080/booking/smoke/ping | jq . ; curl -s http://localhost:8080/hotels | jq .


Ожидание:

health: все UP

routes: есть hotel-route и booking-route

smoke: booking ok и список отелей

Полезные скрипты (в корне)

fix_all_services.sh — сборка, запуск всего стека, смоук-проверки

run_stack_and_smoke.sh — запустить все + смоук

run_booking_only.sh — локальный запуск только booking-service

fix_gateway_routes_and_actuator.sh / keep_paths_in_gateway.sh — конфиг gateway (маршруты/actuator)

Для запуска в macOS могут понадобиться:
chmod +x <имя_скрипта> и, если файл пришёл с CRLF:
sed -i '' -e $'s/\r$//' <имя_скрипта>

Технологии

Spring Boot 3.2.x

Spring Cloud (Eureka Client, Spring Cloud Gateway, LoadBalancer)

Spring Security (минимальные открытия для /actuator и GET /hotels)

H2 (in-memory)

Maven

Структура проекта
spring-hotel-booking/
  eureka-server/
  api-gateway/
  hotel-service/
  booking-service/
  pom.xml
  README.md
  (скрипты *.sh)

.gitignore 

**/target/
*.log
.*.log
*.bak
*.bak_*
.DS_Store

Troubleshooting 

Gateway 401 на /hotels:
В финальной конфигурации Hotel Service открыт для GET /hotels/**. Если видите 401 — пересоберите hotel-service (mvn -DskipTests -pl hotel-service -am clean package) и перезапустите.

Не видны сервисы в Eureka:
Проверьте URL Eureka в application.yml сервисов (должен указывать на http://localhost:8761/eureka/) и сетевые политики/файрвол.

Маршруты 404:
Проверьте список маршрутов GET /actuator/gateway/routes и что сервисы UP.
