#!/bin/sh
# Auto-generated from: service.bat
# Source: https://github.com/Flowseal/zapret-discord-youtube
# Converted by bat2sh.py -- do not edit manually

TPWS="${TPWS_BIN:-/usr/local/bin/tpws}"
PORT="${TPWS_PORT:-1188}"

exec "$TPWS" \
    --port="$PORT" \
    | find /I winws.exe > nul
