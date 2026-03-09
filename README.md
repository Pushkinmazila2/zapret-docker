# zapret-docker
zapret-docker

Архитектура (Alpine, ~15-20MB итого):

microsocks — SOCKS5 вход на порту 1080
tpws — скомпилирован из bol-van/zapret, управляется через UI
nginx + fcgiwrap — Web UI с bash CGI, под паролем через htpasswd

Web UI умеет:

Выбирать источник (flowseal / bol-van) и стратегию из файлов
Применять стратегию → перезапускает tpws с новыми аргументами
Кнопка "Обновить" → git pull оба репозитория
Редактировать hostlist доменов
Показывать статус tpws в шапке (обновляется каждые 10 сек)
