#!/bin/bash
echo "Content-Type: application/json"
echo ""

DATA=/data
STRATEGIES_DIR="$DATA/strategies"
LOG=""

update_repo() {
  local name="$1"
  local url="$2"
  local dest="$STRATEGIES_DIR/$name"

  if [ -d "$dest/.git" ]; then
    OUT=$(git -C "$dest" pull 2>&1)
    LOG="$LOG\n[$name] pull: $OUT"
  else
    rm -rf "$dest"
    OUT=$(git clone --depth=1 "$url" "$dest" 2>&1)
    LOG="$LOG\n[$name] clone: $OUT"
  fi
}

update_repo "bol-van"  "https://github.com/bol-van/zapret.git"
update_repo "flowseal" "https://github.com/Flowseal/zapret-discord-youtube.git"

echo "{\"ok\":true,\"log\":$(echo -e "$LOG" | jq -Rs .)}"
