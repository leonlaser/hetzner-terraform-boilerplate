#!/bin/bash
REBOOT_FILE="/var/run/reboot-required"
STAMP_FILE="/var/run/reboot-notified"

source /home/ops/.config/server.conf

if [ -f "$REBOOT_FILE" ] && [ ! -f "$STAMP_FILE" ]; then
  PKGS="No details available"
  [ -f "$REBOOT_FILE.pkgs" ] && PKGS=$(cat "$REBOOT_FILE.pkgs")

  printf "Subject: [$(hostname)] Reboot necessary\n\nServer: $(hostname)\nUptime: $(uptime -p)\n\nPackages:\n$PKGS" \
    | msmtp "$NOTIFY_EMAIL"

  touch "$STAMP_FILE"
fi

# Cleanup
[ ! -f "$REBOOT_FILE" ] && rm -f "$STAMP_FILE"
