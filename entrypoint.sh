#!/bin/bash
set -e

DATA=/data
STRATEGIES_DIR="$DATA/strategies"
STATE_FILE="$DATA/state.json"
PROXY_CONF="$DATA/3proxy.cfg"
CONNECTIONS_LOG="$DATA/connections.log"

# ── Инициализация директорий ──────────────────────────────────
mkdir -p "$STRATEGIES_DIR/bol-van"
mkdir -p "$STRATEGIES_DIR/flowseal"
mkdir -p "$DATA/lists"

# ── Дефолтный state если нет ─────────────────────────────────
if [ ! -f "$STATE_FILE" ]; then
  cat > "$STATE_FILE" <<'EOF'
{
  "active_strategy": "",
  "active_source": "",
  "tpws_port": 1188,
  "domains": []
}
EOF
fi

# ── Генерация htpasswd для Web UI ─────────────────────────────
if [ ! -f /data/.htpasswd ]; then
  htpasswd -cb /data/.htpasswd "${WEBUI_USER:-admin}" "${WEBUI_PASS:-changeme}"
fi

# ── Генерация конфига 3proxy ──────────────────────────────────
PROXY_USER="${PROXY_USER:-proxyuser}"
PROXY_PASS="${PROXY_PASS:-proxypass}"
SOCKS_PORT="${SOCKS5_PORT:-1080}"

cat > "$PROXY_CONF" <<EOF
# 3proxy config — auto-generated
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
log $CONNECTIONS_LOG D
logformat "- +_L%t.%.  %N.%p %E %U %C:%c %R:%r %O %I %h %T"
rotate 7

# Аутентификация: username/password
auth strong
users ${PROXY_USER}:CL:${PROXY_PASS}

# SOCKS5 с авторизацией
allow *
socks -p${SOCKS_PORT}
EOF

# ── Первичная загрузка стратегий если нет ────────────────────
if [ ! -f "$STRATEGIES_DIR/.initialized" ]; then
  echo "[init] Cloning strategies from GitHub..."

  git clone --depth=1 https://github.com/bol-van/zapret.git \
      /tmp/zapret-bolvan 2>/dev/null && \
    cp -rf /tmp/zapret-bolvan/. "$STRATEGIES_DIR/bol-van/" 2>/dev/null || true

  git clone --depth=1 https://github.com/Flowseal/zapret-discord-youtube.git \
      /tmp/zapret-flowseal 2>/dev/null && \
    cp -rf /tmp/zapret-flowseal/. "$STRATEGIES_DIR/flowseal/" 2>/dev/null || true

  touch "$STRATEGIES_DIR/.initialized"
  rm -rf /tmp/zapret-bolvan /tmp/zapret-flowseal
  echo "[init] Done."
fi

# ── Запуск 3proxy (SOCKS5 с авторизацией) ────────────────────
echo "[start] Starting 3proxy SOCKS5 on :${SOCKS_PORT} (user: ${PROXY_USER})..."
/usr/local/bin/3proxy "$PROXY_CONF" &

# ── Запуск tpws если есть активная стратегия ─────────────────
ACTIVE=$(jq -r '.active_strategy // ""' "$STATE_FILE")
if [ -n "$ACTIVE" ] && [ "$ACTIVE" != "null" ]; then
  SOURCE=$(jq -r '.active_source // "flowseal"' "$STATE_FILE")
  TPWS_PORT=$(jq -r '.tpws_port // 1188' "$STATE_FILE")
  STRATEGY_FILE="$STRATEGIES_DIR/$SOURCE/$ACTIVE"

  if [ -f "$STRATEGY_FILE" ]; then
    echo "[start] Applying strategy: $SOURCE/$ACTIVE"
    ARGS=$(grep -v '^#' "$STRATEGY_FILE" | tr '\n' ' ')
    /usr/local/bin/tpws --port="$TPWS_PORT" $ARGS > /data/tpws.log 2>&1 &
  fi
fi

# ── nginx + fcgiwrap (Web UI) ─────────────────────────────────
echo "[start] Starting Web UI on :${WEBUI_PORT:-8080}..."
spawn-fcgi -s /run/fcgiwrap.sock -M 0660 /usr/bin/fcgiwrap
nginx -g 'daemon off;' &

wait