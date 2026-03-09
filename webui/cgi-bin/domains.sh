#!/bin/bash
echo "Content-Type: application/json"
echo ""

DATA=/data
DOMAINS_FILE="$DATA/domains.txt"

METHOD="${REQUEST_METHOD:-GET}"

if [ "$METHOD" = "GET" ]; then
  if [ -f "$DOMAINS_FILE" ]; then
    jq -Rns '[inputs | select(length>0)]' < "$DOMAINS_FILE"
  else
    echo "[]"
  fi

elif [ "$METHOD" = "POST" ]; then
  read -r -n "${CONTENT_LENGTH:-0}" POST_DATA
  DOMAINS=$(echo "$POST_DATA" | jq -r '.domains // [] | .[]')
  echo "$DOMAINS" > "$DOMAINS_FILE"

  # Перезаписываем hostlist для tpws если процесс жив
  if pgrep -x tpws > /dev/null 2>&1; then
    pkill -HUP tpws 2>/dev/null || true
  fi

  echo '{"ok":true}'
fi
