# syntax=docker/dockerfile:1
FROM alpine:3.19 AS builder

RUN apk add --no-cache \
    git \
    gcc \
    make \
    musl-dev \
    linux-headers \
    libcap-dev

# Build microsocks (lightweight SOCKS5 proxy)
RUN git clone --depth=1 https://github.com/rofl0r/microsocks.git /build/microsocks && \
    cd /build/microsocks && make && strip microsocks

# Build tpws from zapret (bol-van)
RUN git clone --depth=1 https://github.com/bol-van/zapret.git /build/zapret && \
    cd /build/zapret && \
    make -C nfq tpws && \
    strip /build/zapret/tpws/tpws

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
    jq

# Copy binaries from builder
COPY --from=builder /build/microsocks/microsocks /usr/local/bin/microsocks
COPY --from=builder /build/zapret/tpws/tpws     /usr/local/bin/tpws

# Web UI
COPY webui/ /var/www/webui/
RUN chmod +x /var/www/webui/cgi-bin/*.sh

# nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Data volume: стратегии, конфиги, состояние
VOLUME ["/data"]

EXPOSE 1080 8080

ENTRYPOINT ["/entrypoint.sh"]
