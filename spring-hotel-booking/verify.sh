#!/usr/bin/env bash
set -euo pipefail

echo "=== Проверка JDK ==="
java -version || true

echo "=== Maven build (со всеми тестами) ==="
mvn -U -DskipTests=false -DfailIfNoTests=false clean package

echo "MAIN-классы:"
grep -R --include="*Application.java" -n "class .*Application" . | sed 's|^\./||'

echo "=== Пытаюсь достучаться до Eureka, если запущен ==="
if curl -fsS http://localhost:8761/actuator/health >/dev/null 2>&1; then
  echo "Eureka уже запущен."
else
  echo "Eureka не отвечает (это нормально, если сервисы не стартованы)."
fi

echo "Подсказка: запусти ./run.sh для старта всех сервисов."
