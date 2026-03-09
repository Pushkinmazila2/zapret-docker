#!/bin/sh
# Auto-generated from: general (ALT5).bat
# Source: https://github.com/Flowseal/zapret-discord-youtube
# Converted by bat2sh.py -- do not edit manually

TPWS="${TPWS_BIN:-/usr/local/bin/tpws}"
PORT="${TPWS_PORT:-1188}"

exec "$TPWS" \
    --port="$PORT" \
    --filter-udp=443 --hostlist=/data/lists/list-general.txt --hostlist=/data/lists/list-general-user.txt --hostlist-exclude=/data/lists/list-exclude.txt --hostlist-exclude=/data/lists/list-exclude-user.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=/data/bin/quic_initial_www_google_com.bin --new \
    --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6 --new \
    --filter-l3=ipv4 --filter-tcp=80,443,2053,2083,2087,2096,8443 --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=syndata,multidisorder --new \
    --filter-tcp= --ipset=/data/lists/ipset-all.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=syndata,multidisorder --dpi-desync-any-protocol=1 --dpi-desync-cutoff=n4 --new \
    --filter-udp=443 --ipset=/data/lists/ipset-all.txt --hostlist-exclude=/data/lists/list-exclude.txt --hostlist-exclude=/data/lists/list-exclude-user.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=/data/bin/quic_initial_www_google_com.bin --new \
    --filter-udp= --ipset=/data/lists/ipset-all.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=14 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=/data/bin/quic_initial_www_google_com.bin --dpi-desync-cutoff=n3
