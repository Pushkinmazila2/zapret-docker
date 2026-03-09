#!/bin/bash
echo "Content-Type: application/json"
echo ""

CONNECTIONS_LOG="/data/connections.log"

if [ ! -f "$CONNECTIONS_LOG" ]; then
  echo '{"clients":[],"total":0}'
  exit 0
fi

# Парсим лог 3proxy: берём подключения за последние 24ч
# Формат: дата время N.p ERROR USER CLIENT:port REMOTE:port bytes_out bytes_in ...
NOW=$(date +%s)
CUTOFF=$((NOW - 86400))

clients_json="["
first=1

while IFS= read -r line; do
  # Пропускаем служебные строки
  [[ "$line" =~ ^# ]] && continue
  [ -z "$line" ] && continue

  # Извлекаем поля
  user=$(echo "$line" | awk '{print $6}')
  client=$(echo "$line" | awk '{print $7}')
  remote=$(echo "$line" | awk '{print $8}')
  bytes_out=$(echo "$line" | awk '{print $9}')
  bytes_in=$(echo "$line" | awk '{print $10}')
  timestamp=$(echo "$line" | awk '{print $1, $2}' | sed 's/\./:/3')

  [ -z "$client" ] && continue
  [ "$client" = "-" ] && continue

  client_ip="${client%%:*}"
  client_port="${client##*:}"
  remote_host="${remote%%:*}"
  remote_port="${remote##*:}"

  [ "$first" = "1" ] && first=0 || clients_json+=","
  clients_json+="{\"user\":\"$user\",\"client_ip\":\"$client_ip\",\"client_port\":\"$client_port\",\"remote\":\"$remote_host\",\"remote_port\":\"$remote_port\",\"bytes_out\":\"$bytes_out\",\"bytes_in\":\"$bytes_in\",\"time\":\"$timestamp\"}"

done < <(tail -200 "$CONNECTIONS_LOG")

clients_json+="]"

total=$(echo "$clients_json" | jq 'length' 2>/dev/null || echo 0)

echo "{\"clients\":$clients_json,\"total\":$total}"