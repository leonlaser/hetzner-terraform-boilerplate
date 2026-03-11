#!/bin/bash
set -euo pipefail

DUMP_DIR="/home/docker/current/pgdump"
echo "pg_restore started: $(date)"

cd /home/docker/current
sudo -u docker docker compose exec -T database bash -c 'rm -rf /tmp/pgdump && mkdir -p /tmp/pgdump'
tar cf - -C $DUMP_DIR . | sudo -u docker docker compose exec -T database bash -c 'tar xf - -C /tmp/pgdump'
sudo -u docker docker compose exec -T database bash -c 'pg_restore \
  --clean --if-exists --jobs=2 \
  --dbname="$POSTGRES_DB" --username="$POSTGRES_USER" \
  /tmp/pgdump'
sudo -u docker docker compose exec database rm -rf /tmp/pgdump

sudo -u docker rm -rf "$DUMP_DIR"

echo "pg_restore finished: $(date)"