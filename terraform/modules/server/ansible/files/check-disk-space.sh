#!/bin/bash

source "$HOME/.config/server.conf"

THRESHOLD="${DISK_THRESHOLD:-90}"
STAMP_FILE="$HOME/.disk-space-notified"

USAGE=$(df / --output=pcent | tail -1 | tr -d ' %')

if [ "$USAGE" -ge "$THRESHOLD" ] && [ ! -f "$STAMP_FILE" ]; then
  DISK_INFO=$(df -h / --output=source,size,used,avail,pcent)
  DOCKER_INFO=$(sudo -u docker XDG_RUNTIME_DIR=/run/user/1000 docker system df 2>/dev/null || echo "N/A")

  printf "Subject: [$(hostname)] Disk usage at %s%% (threshold: %s%%)\n\nServer: %s\n\nDisk usage:\n%s\n\nDocker disk usage:\n%s" \
    "$USAGE" "$THRESHOLD" "$(hostname)" "$DISK_INFO" "$DOCKER_INFO" \
    | msmtp "$NOTIFY_EMAIL"

  touch "$STAMP_FILE"
fi

# Clear stamp when usage drops below threshold
if [ "$USAGE" -lt "$THRESHOLD" ] && [ -f "$STAMP_FILE" ]; then
  rm -f "$STAMP_FILE"
fi
