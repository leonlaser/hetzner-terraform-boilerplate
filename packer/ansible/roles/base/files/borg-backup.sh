#!/bin/bash
set -euo pipefail

# This script must be run via: sudo borg-backup.sh
# It sources borg config from the ops user's home directory.

OPS_HOME="/home/ops"
LOG_FILE="$OPS_HOME/logs/borg-backup.log"

source "$OPS_HOME/.config/server.conf"

# Guard: skip if secrets not yet provisioned
[ -f "$OPS_HOME/.config/borg/env" ] || exit 0

# Guard: skip if backup is paused (e.g. during a restore)
if [ -f "$OPS_HOME/.backup-paused" ]; then
  echo "=== Backup paused — remove $OPS_HOME/.backup-paused to resume: $(date) === " >> "$LOG_FILE"
  printf "Subject: [$(hostname)] Borg backup SKIPPED (paused)\n\nBackup was skipped at $(date) because $OPS_HOME/.backup-paused exists.\n\nRemove the file to resume automatic backups." \
    | msmtp "$NOTIFY_EMAIL"
  exit 0
fi

# Parse borg env safely — only accept known variables, never execute the file as shell code
while IFS='=' read -r key value; do
  value=$(echo "$value" | tr -d '"')
  case "$key" in
    BORG_REPO|BORG_PASSPHRASE) export "$key=$value" ;;
  esac
done < "$OPS_HOME/.config/borg/env"
export BORG_RSH="ssh -i $OPS_HOME/.ssh/backup_key -o StrictHostKeyChecking=accept-new"

BACKUP_NAME="$(hostname)-$(date +%Y-%m-%dT%H:%M:%S)"
PGDUMP_SCRIPT="$OPS_HOME/scripts/pg-dump.sh"

(
  echo "=== Backup started: $(date) ==="

  # Pre-backup hook: pg_dump (if configured)
  # The dump is written inside BACKUP_PATHS and included automatically.
  if [ -x "$PGDUMP_SCRIPT" ]; then
    "$PGDUMP_SCRIPT" || exit 1
  fi

  # Create backup
  borg create \
    --read-special \
    --compression zstd,3 \
    "::$BACKUP_NAME" \
    $BACKUP_PATHS

  # Post-backup hook: cleanup (if configured)
  PGDUMP_CLEANUP_SCRIPT="$OPS_HOME/scripts/pg-dump-cleanup.sh"
  if [ -x "$PGDUMP_CLEANUP_SCRIPT" ]; then
    "$PGDUMP_CLEANUP_SCRIPT"
  fi

  # Prune old backups
  borg prune \
    --keep-hourly 48 \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --keep-yearly 1

  # Compact repository
  borg compact

  echo "=== Backup finished: $(date) ==="
) >> "$LOG_FILE" 2>&1 || {

  echo "=== Backup failed: $(date) ===" >> "$LOG_FILE"

  printf "Subject: [$(hostname)] Borg backup FAILED\n\nBackup failed at $(date).\n\nLast 50 lines of log:\n$(tail -50 $LOG_FILE)" \
    | msmtp "$NOTIFY_EMAIL"
}
