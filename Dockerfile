# syntax=docker/dockerfile:1
FROM alpine:3.19 AS builder

RUN apk add --no-cache \
    git \
    gcc \
    make \
    musl-dev \
    linux-headers \
    libcap-dev \
    zlib-dev

# Build tpws from zapret (bol-van)
# tpws живёт в tpws/, не в nfq/
RUN git clone --depth=1 https://github.com/bol-van/zapret.git /build/zapret && \
    cd /build/zapret && \
    make -C tpws && \
    strip tpws/tpws

# Build 3proxy — лёгкий прокси с SOCKS5 + HTTP + username/password auth
RUN git clone --depth=1 https://github.com/3proxy/3proxy.git /build/3proxy && \
    cd /build/3proxy && \
    make -f Makefile.Linux && \
    strip bin/3proxy

# ────────────────────────────────────────────────────────────
FROM alpine:3.19

RUN apk add --no-cache \
    bash \
    curl \
    git \
    nginx \
    fcgiwrap \
    spawn-fcgi \
    ca-certificates \
    jq \
    apache2-utils

# Copy binaries from builder
COPY --from=builder /build/zapret/tpws/tpws  /usr/local/bin/tpws
COPY --from=builder /build/3proxy/bin/3proxy /usr/local/bin/3proxy

# Web UI
COPY webui/ /var/www/webui/
RUN chmod +x /var/www/webui/cgi-bin/*.sh

# nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Data volume: стратегии, конфиги, состояние, логи
VOLUME ["/data"]

EXPOSE 1080 8080

ENTRYPOINT ["/entrypoint.sh"]