#!/usr/bin/env bash
set -euo pipefail
echo "⛔ Останавливаю сервисы…"
pkill -f 'api-gateway.*\.jar' 2>/dev/null || true
pkill -f 'booking-service.*\.jar' 2>/dev/null || true
pkill -f 'hotel-service.*\.jar' 2>/dev/null || true
pkill -f 'eureka-server.*\.jar' 2>/dev/null || true
sleep 1
echo "✅ Готово."
