#!/bin/bash
set -euo pipefail

# Backup orchestrator — runs as the ops user.
# Handles application-specific hooks (pg_dump, cleanup) around the
# privileged borg backup script which runs as root via sudo.

SCRIPT_DIR="$(dirname "$0")"
LOG_FILE="$HOME/logs/borg-backup.log"

source "$HOME/.config/server.conf"

# Guard: skip if backup is paused (e.g. during a restore)
if [ -f "$HOME/.backup-paused" ]; then
  echo "=== Backup paused — remove $HOME/.backup-paused to resume: $(date) === " >> "$LOG_FILE"
  printf "Subject: [$(hostname)] Borg backup SKIPPED (paused)\n\nBackup was skipped at $(date) because $HOME/.backup-paused exists.\n\nRemove the file to resume automatic backups." \
    | msmtp "$NOTIFY_EMAIL"
  exit 0
fi

PGDUMP_SCRIPT="$SCRIPT_DIR/pg-dump.sh"
PGDUMP_CLEANUP_SCRIPT="$SCRIPT_DIR/pg-dump-cleanup.sh"

(
  echo "=== Backup started: $(date) ==="

  # Pre-backup hook: pg_dump (if configured)
  # The dump is written inside the backup paths and included automatically.
  if [ -x "$PGDUMP_SCRIPT" ]; then
    "$PGDUMP_SCRIPT" || exit 1
  fi

  # Borg backup (runs as root)
  sudo /root/scripts/borg-backup.sh "$HOME"

  # Post-backup hook: cleanup (if configured)
  if [ -x "$PGDUMP_CLEANUP_SCRIPT" ]; then
    "$PGDUMP_CLEANUP_SCRIPT"
  fi

  echo "=== Backup finished: $(date) ==="
) >> "$LOG_FILE" 2>&1 || {

  echo "=== Backup failed: $(date) ===" >> "$LOG_FILE"

  printf "Subject: [$(hostname)] Borg backup FAILED\n\nBackup failed at $(date).\n\nLast 50 lines of log:\n$(tail -50 $LOG_FILE)" \
    | msmtp "$NOTIFY_EMAIL"
}