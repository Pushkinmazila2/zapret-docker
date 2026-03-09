#!/bin/bash
echo "Content-Type: application/json"
echo ""

DATA=/data
STRATEGIES_DIR="$DATA/strategies"
STATE_FILE="$DATA/state.json"

# Читаем POST body
read -r -n "${CONTENT_LENGTH:-0}" POST_DATA

SOURCE=$(echo "$POST_DATA" | jq -r '.source // ""')
STRATEGY=$(echo "$POST_DATA" | jq -r '.strategy // ""')
TPWS_PORT=$(echo "$POST_DATA" | jq -r '.tpws_port // "1188"')

if [ -z "$SOURCE" ] || [ -z "$STRATEGY" ]; then
  echo '{"ok":false,"error":"source and strategy required"}'
  exit 0
fi

STRATEGY_FILE="$STRATEGIES_DIR/$SOURCE/$STRATEGY"

if [ ! -f "$STRATEGY_FILE" ]; then
  echo "{\"ok\":false,\"error\":\"file not found: $SOURCE/$STRATEGY\"}"
  exit 0
fi

# Убиваем старый tpws
pkill -x tpws 2>/dev/null || true
sleep 0.3

# Читаем аргументы из файла стратегии
ARGS=$(grep -v '^#' "$STRATEGY_FILE" | tr '\n' ' ')

# Запускаем tpws
/usr/local/bin/tpws --port="$TPWS_PORT" $ARGS > /data/tpws.log 2>&1 &

# Обновляем state
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo '{}')
echo "$STATE" | jq \
  --arg s "$SOURCE" \
  --arg st "$STRATEGY" \
  --argjson p "$TPWS_PORT" \
  '.active_source=$s | .active_strategy=$st | .tpws_port=$p' \
  > "$STATE_FILE"

echo '{"ok":true}'
