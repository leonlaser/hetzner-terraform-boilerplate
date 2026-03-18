#!/bin/bash
set -euo pipefail

# Pure borg backup script — must be run via: sudo borg-backup.sh <user-home>
# Only handles borg create, prune, and compact. Application-specific
# hooks (pg_dump, cleanup) are handled by the calling wrapper (backup.sh).

USER_HOME="${1:?Usage: borg-backup.sh <user-home>}"

source "$USER_HOME/.config/server.conf"

# Guard: skip if secrets not yet provisioned
[ -f "$USER_HOME/.config/borg/env" ] || exit 0

# Parse borg env safely — only accept known variables, never execute the file as shell code
while IFS='=' read -r key value; do
  value=$(echo "$value" | tr -d '"')
  case "$key" in
    BORG_REPO|BORG_PASSPHRASE) export "$key=$value" ;;
  esac
done < "$USER_HOME/.config/borg/env"
export BORG_RSH="ssh -i $USER_HOME/.ssh/backup_key -o StrictHostKeyChecking=accept-new"

BACKUP_NAME="$(hostname)-$(date +%Y-%m-%dT%H:%M:%S)"

# Create backup
borg create \
  --read-special \
  --compression zstd,3 \
  "::$BACKUP_NAME" \
  $BACKUP_PATHS

# Prune old backups
borg prune \
  --keep-hourly 48 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --keep-yearly 1

# Compact repository
borg compact