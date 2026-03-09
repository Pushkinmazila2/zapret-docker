# zapret-docker

Минималистичный Docker-контейнер с DPI-bypass (zapret/tpws) + SOCKS5 прокси + Web UI.

## Структура

```
zapret-docker/
├── Dockerfile          # Alpine multi-stage, ~30-50MB итого
├── docker-compose.yml
├── entrypoint.sh
├── nginx.conf
└── webui/
    ├── index.html
    └── cgi-bin/
        ├── status.sh   # GET  → текущее состояние + список стратегий
        ├── update.sh   # GET  → git pull оба репо
        ├── apply.sh    # POST → применить стратегию (перезапуск tpws)
        └── domains.sh  # GET/POST → управление hostlist
```

## Быстрый старт

```bash
# 1. Собрать и запустить
docker compose up -d --build

# 2. Создать htpasswd для Web UI (первый запуск)
docker exec zapret sh -c \
  "apk add --no-cache apache2-utils && \
   htpasswd -cb /data/.htpasswd \${WEBUI_USER:-admin} \${WEBUI_PASS:-changeme}"

# 3. Открыть Web UI
open http://localhost:8080
```

## Использование

| Порт | Назначение |
|------|-----------|
| 1080 | SOCKS5 прокси (вход) |
| 8080 | Web UI (под паролем) |

### Настройка клиента
Укажи в браузере/системе SOCKS5 прокси: `<host>:1080`

### Web UI
- **Выбор стратегии** → источник (flowseal / bol-van) → файл → Применить
- **Обновить** → git pull с обоих GitHub репозиториев
- **Домены** → список хостов, передаётся в `--hostlist` tpws

## Переменные окружения

| Переменная   | По умолчанию | Описание |
|-------------|-------------|---------|
| WEBUI_USER  | admin       | Логин Web UI |
| WEBUI_PASS  | changeme    | Пароль Web UI |
| SOCKS5_PORT | 1080        | Порт SOCKS5 |
| WEBUI_PORT  | 8080        | Порт Web UI |

## Важно

- Контейнер требует `cap_add: NET_ADMIN` для tpws
- Стратегии хранятся в volume `zapret_data` → переживают перезапуск
- tpws работает в режиме transparent proxy; microsocks — входной SOCKS5

## Размер образа

| Компонент | Размер |
|-----------|--------|
| Alpine base | ~7MB |
| tpws (stripped) | ~500KB |
| microsocks (stripped) | ~50KB |
| nginx + fcgiwrap | ~5MB |
| **Итого** | **~15-20MB** |
