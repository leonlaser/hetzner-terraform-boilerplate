#!/bin/bash
set -euo pipefail

# Restore wrapper — runs as the ops user.
# Pauses automatic backups during restore to avoid borg lock conflicts,
# then delegates to the root-owned borg-restore.sh via sudo.

LOG_FILE="$HOME/logs/borg-backup.log"
PAUSE_FILE="$HOME/.backup-paused"

# Track whether we created the pause file (don't remove someone else's)
CREATED_PAUSE=false

cleanup() {
  if [ "$CREATED_PAUSE" = true ]; then
    rm -f "$PAUSE_FILE"
    echo "=== Restore cleanup: backup resumed: $(date) ===" >> "$LOG_FILE"
  fi
}
trap cleanup EXIT INT TERM

# Pause backups if not already paused
if [ ! -f "$PAUSE_FILE" ]; then
  touch "$PAUSE_FILE"
  CREATED_PAUSE=true
  echo "=== Restore: backup paused: $(date) ===" >> "$LOG_FILE"
fi

echo "=== Restore started: $(date) ===" >> "$LOG_FILE"

sudo /root/scripts/borg-restore.sh "$HOME" "$@"

echo "=== Restore finished: $(date) ===" >> "$LOG_FILE"
