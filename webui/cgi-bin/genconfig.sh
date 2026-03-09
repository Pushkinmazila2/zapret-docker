#!/bin/bash
echo "Content-Type: application/json"
echo ""

read -r -n "${CONTENT_LENGTH:-0}" POST_DATA

CLIENT_TYPE=$(echo "$POST_DATA" | jq -r '.type // "url"')
LABEL=$(echo "$POST_DATA" | jq -r '.label // "zapret"')

# Достаём параметры из env / конфига
PROXY_USER="${PROXY_USER:-proxyuser}"
PROXY_PASS="${PROXY_PASS:-changeme}"
SOCKS_PORT="${SOCKS5_PORT:-1080}"

# Пытаемся определить внешний IP
SERVER_IP=$(curl -sf --max-time 3 https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")

case "$CLIENT_TYPE" in
  url)
    # socks5://user:pass@host:port
    CONFIG="socks5://${PROXY_USER}:${PROXY_PASS}@${SERVER_IP}:${SOCKS_PORT}"
    ;;

  clash)
    CONFIG=$(cat <<EOF
proxies:
  - name: "${LABEL}"
    type: socks5
    server: ${SERVER_IP}
    port: ${SOCKS_PORT}
    username: ${PROXY_USER}
    password: ${PROXY_PASS}
    udp: true

proxy-groups:
  - name: "PROXY"
    type: select
    proxies:
      - "${LABEL}"
      - DIRECT

rules:
  - MATCH,PROXY
EOF
)
    ;;

  v2ray)
    CONFIG=$(cat <<EOF
{
  "outbounds": [
    {
      "tag": "${LABEL}",
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "${SERVER_IP}",
            "port": ${SOCKS_PORT},
            "users": [
              {
                "user": "${PROXY_USER}",
                "pass": "${PROXY_PASS}"
              }
            ]
          }
        ]
      }
    }
  ]
}
EOF
)
    ;;

  proxychains)
    CONFIG=$(cat <<EOF
# proxychains.conf
strict_chain
proxy_dns

[ProxyList]
socks5  ${SERVER_IP}  ${SOCKS_PORT}  ${PROXY_USER}  ${PROXY_PASS}
EOF
)
    ;;

  curl)
    CONFIG="curl --proxy socks5h://${PROXY_USER}:${PROXY_PASS}@${SERVER_IP}:${SOCKS_PORT} https://example.com"
    ;;

  *)
    echo '{"ok":false,"error":"unknown type"}'
    exit 0
    ;;
esac

CONFIG_ESCAPED=$(echo "$CONFIG" | jq -Rs .)
echo "{\"ok\":true,\"type\":\"$CLIENT_TYPE\",\"server\":\"$SERVER_IP\",\"port\":$SOCKS_PORT,\"config\":$CONFIG_ESCAPED}"