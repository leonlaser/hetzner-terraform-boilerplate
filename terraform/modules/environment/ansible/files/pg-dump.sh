#!/bin/bash
set -euo pipefail

DUMP_DIR="/home/docker/current/pgdump"
echo "pg_dump started: $(date)"

rm -rf "$DUMP_DIR"
mkdir -p "$DUMP_DIR"

# pg_dump inside the container in directory format (one file per table)
# Tar-stream output to local disk
cd /home/docker/current
sudo -u docker docker compose exec -T database bash -c 'rm -rf /tmp/pgdump && \
    pg_dump --username="$POSTGRES_USER" --format=directory --jobs=2 --file=/tmp/pgdump "$POSTGRES_DB" && \
    tar -C /tmp -cf - pgdump && \
    rm -rf /tmp/pgdump' \
  | tar -C "$DUMP_DIR" -xf - --strip-components=1

chown -R docker:docker "$DUMP_DIR"

echo "pg_dump finished: $(date)"