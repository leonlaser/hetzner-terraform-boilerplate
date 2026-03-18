#!/bin/bash
set -euo pipefail

DUMP_DIR="/home/docker/current/pgdump"
echo "pg_dump_cleanup started: $(date)"

rm -rf "$DUMP_DIR"

echo "pg_dump_cleanup finished: $(date)"
