#!/bin/bash
set -euo pipefail

# Docker image and build cache cleanup — runs as the ops user.
# Only prunes dangling images and old build cache. Never touches volumes or named images.

LOG_FILE="$HOME/logs/docker-cleanup.log"
export XDG_RUNTIME_DIR=/run/user/1000

source "$HOME/.config/server.conf"

(
  echo "=== Docker cleanup started: $(date) ==="

  sudo -u docker docker image prune --force
  sudo -u docker docker builder prune --force --filter "until=24h"

  echo "=== Docker cleanup finished: $(date) ==="
) >> "$LOG_FILE" 2>&1 || {

  echo "=== Docker cleanup failed: $(date) ===" >> "$LOG_FILE"

  printf "Subject: [$(hostname)] Docker cleanup FAILED\n\nDocker cleanup failed at $(date).\n\nLast 20 lines of log:\n$(tail -20 "$LOG_FILE")" \
    | msmtp "$NOTIFY_EMAIL"
}
