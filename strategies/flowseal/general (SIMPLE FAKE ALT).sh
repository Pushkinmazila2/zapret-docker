#!/bin/sh
# Auto-generated from: general (SIMPLE FAKE ALT).bat
# Source: https://github.com/Flowseal/zapret-discord-youtube
# Converted by bat2sh.py -- do not edit manually

TPWS="${TPWS_BIN:-/usr/local/bin/tpws}"
PORT="${TPWS_PORT:-1188}"

exec "$TPWS" \
    --port="$PORT" \
    --filter-udp=443 --hostlist=/data/lists/list-general.txt --hostlist=/data/lists/list-general-user.txt --hostlist-exclude=/data/lists/list-exclude.txt --hostlist-exclude=/data/lists/list-exclude-user.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=/data/bin/quic_initial_www_google_com.bin --new \
    --filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6 --new \
    --filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=/data/bin/tls_clienthello_www_google_com.bin --new \
    --filter-tcp=443 --hostlist=/data/lists/list-google.txt --ip-id=zero --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=/data/bin/tls_clienthello_www_google_com.bin --new \
    --filter-tcp=80,443 --hostlist=/data/lists/list-general.txt --hostlist=/data/lists/list-general-user.txt --hostlist-exclude=/data/lists/list-exclude.txt --hostlist-exclude=/data/lists/list-exclude-user.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=/data/bin/stun.bin --dpi-desync-fake-tls=/data/bin/tls_clienthello_www_google_com.bin --dpi-desync-fake-http=/data/bin/tls_clienthello_max_ru.bin --new \
    --filter-udp=443 --ipset=/data/lists/ipset-all.txt --hostlist-exclude=/data/lists/list-exclude.txt --hostlist-exclude=/data/lists/list-exclude-user.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=/data/bin/quic_initial_www_google_com.bin --new \
    --filter-tcp=80,443,8443 --ipset=/data/lists/ipset-all.txt --hostlist-exclude=/data/lists/list-exclude.txt --hostlist-exclude=/data/lists/list-exclude-user.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=/data/bin/stun.bin --dpi-desync-fake-tls=/data/bin/tls_clienthello_www_google_com.bin --dpi-desync-fake-http=/data/bin/tls_clienthello_max_ru.bin --new \
    --filter-tcp= --ipset=/data/lists/ipset-all.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol=1 --dpi-desync-cutoff=n3 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=/data/bin/stun.bin --dpi-desync-fake-tls=/data/bin/tls_clienthello_www_google_com.bin --dpi-desync-fake-http=/data/bin/tls_clienthello_max_ru.bin --new \
    --filter-udp= --ipset=/data/lists/ipset-all.txt --ipset-exclude=/data/lists/ipset-exclude.txt --ipset-exclude=/data/lists/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=10 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=/data/bin/quic_initial_www_google_com.bin --dpi-desync-cutoff=n2
