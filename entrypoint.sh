#!/bin/bash
set -e

DATA=/data
STRATEGIES_DIR="$DATA/strategies"
STATE_FILE="$DATA/state.json"

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

# ── Первичная загрузка стратегий если нет ────────────────────
if [ ! -f "$STRATEGIES_DIR/.initialized" ]; then
  echo "[init] Cloning strategies from GitHub..."

  git clone --depth=1 https://github.com/bol-van/zapret.git \
      /tmp/zapret-bolvan 2>/dev/null && \
    cp -r /tmp/zapret-bolvan/docs/strategies/* "$STRATEGIES_DIR/bol-van/" 2>/dev/null || \
    ls /tmp/zapret-bolvan/ > "$STRATEGIES_DIR/bol-van/.cloned" 2>/dev/null || true

  git clone --depth=1 https://github.com/Flowseal/zapret-discord-youtube.git \
      /tmp/zapret-flowseal 2>/dev/null && \
    cp -r /tmp/zapret-flowseal/. "$STRATEGIES_DIR/flowseal/" 2>/dev/null || true

  touch "$STRATEGIES_DIR/.initialized"
  rm -rf /tmp/zapret-bolvan /tmp/zapret-flowseal
  echo "[init] Done."
fi

# ── Запуск microsocks (SOCKS5) ────────────────────────────────
echo "[start] Starting SOCKS5 proxy on :${SOCKS5_PORT:-1080}..."
/usr/local/bin/microsocks -p "${SOCKS5_PORT:-1080}" &

# ── Запуск tpws если есть активная стратегия ─────────────────
ACTIVE=$(jq -r '.active_strategy // ""' "$STATE_FILE")
if [ -n "$ACTIVE" ] && [ "$ACTIVE" != "null" ]; then
  SOURCE=$(jq -r '.active_source // "flowseal"' "$STATE_FILE")
  TPWS_PORT=$(jq -r '.tpws_port // 1188' "$STATE_FILE")
  STRATEGY_FILE="$STRATEGIES_DIR/$SOURCE/$ACTIVE"

  if [ -f "$STRATEGY_FILE" ]; then
    echo "[start] Applying strategy: $SOURCE/$ACTIVE"
    ARGS=$(cat "$STRATEGY_FILE")
    /usr/local/bin/tpws --port="$TPWS_PORT" $ARGS &
  fi
fi

# ── nginx + fcgiwrap (Web UI) ─────────────────────────────────
echo "[start] Starting Web UI on :${WEBUI_PORT:-8080}..."
spawn-fcgi -s /run/fcgiwrap.sock -M 0660 /usr/bin/fcgiwrap
nginx -g 'daemon off;' &

wait
