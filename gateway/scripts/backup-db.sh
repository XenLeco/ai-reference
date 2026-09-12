#!/usr/bin/env bash
# Back up the gateway's Postgres (keys, teams, spend logs) with pg_dump, keep the last N.
# Usage: backup-db.sh [dest_dir=./backups] [keep=14]
# Restore: docker compose exec -T db pg_restore -U litellm -d litellm --clean --if-exists < backups/<file>.dump
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
DEST="${1:-./backups}"
KEEP="${2:-14}"
mkdir -p "$DEST"
stamp="$(date +%Y%m%d-%H%M%S)"
out="$DEST/litellm-$stamp.dump"
docker compose exec -T db pg_dump -U litellm -Fc litellm > "$out"
echo "wrote $out ($(du -h "$out" | cut -f1))"
# rotate
ls -1t "$DEST"/litellm-*.dump 2>/dev/null | tail -n +"$((KEEP + 1))" | xargs -r rm -v --
echo "kept $(ls -1 "$DEST"/litellm-*.dump | wc -l) backups in $DEST (backups/ is git-ignored)"
