#!/bin/bash
echo "Content-Type: application/json"
echo ""

DATA=/data
STRATEGIES_DIR="$DATA/strategies"
STATE_FILE="$DATA/state.json"

# Собираем список стратегий из обоих источников
list_strategies() {
  local source="$1"
  local dir="$STRATEGIES_DIR/$source"
  if [ -d "$dir" ]; then
    find "$dir" -maxdepth 2 -name "*.sh" -o -name "*.conf" -o -name "*.txt" 2>/dev/null \
      | sed "s|$dir/||" | sort | jq -Rs 'split("\n") | map(select(length>0))'
  else
    echo "[]"
  fi
}

BOLVAN=$(list_strategies "bol-van")
FLOWSEAL=$(list_strategies "flowseal")
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo '{}')

# Статус tpws процесса
TPWS_RUNNING=false
if pgrep -x tpws > /dev/null 2>&1; then
  TPWS_RUNNING=true
fi

cat <<EOF
{
  "state": $STATE,
  "tpws_running": $TPWS_RUNNING,
  "strategies": {
    "bol-van": $BOLVAN,
    "flowseal": $FLOWSEAL
  }
}
EOF
