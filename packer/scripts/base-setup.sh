#!/usr/bin/env bash
set -eux
export DEBIAN_FRONTEND=noninteractive

# =============================================================================
# Base server setup — shared between docker and db-server images
# =============================================================================

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------
apt-get update
apt-get install -y \
  fail2ban \
  ufw \
  unattended-upgrades \
  msmtp \
  msmtp-mta \
  borgbackup \
  sshpass \
  lsb-release \
  systemd-container

# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------

# Remove default ubuntu user (present on Hetzner base images)
userdel -r ubuntu 2>/dev/null || true

# Create ops user with explicit UID
useradd -m -u 1001 -s /bin/bash -G users ops

# ---------------------------------------------------------------------------
# Fail2Ban
# ---------------------------------------------------------------------------
cat > /etc/fail2ban/jail.local <<'FAIL2BAN'
[sshd]
enabled = true
maxretry = 3
bantime = 3600
FAIL2BAN

# ---------------------------------------------------------------------------
# Ops directory structure
# ---------------------------------------------------------------------------
mkdir -p /home/ops/.config/borg /home/ops/.ssh /home/ops/logs /home/ops/scripts
chown -R ops:ops /home/ops/.config /home/ops/.ssh /home/ops/logs /home/ops/scripts
chmod 700 /home/ops/.ssh /home/ops/.config/borg

# ---------------------------------------------------------------------------
# Static scripts (not templated — no secrets or env-specific values)
# ---------------------------------------------------------------------------

# Borg helper: sources env, delegates to borg
cat > /home/ops/scripts/borg.sh <<'BORG_HELPER'
#!/bin/bash
set -euo pipefail

set -a
source "$HOME/.config/borg/env"
set +a

exec borg "$@"
BORG_HELPER
chown ops:ops /home/ops/scripts/borg.sh
chmod 755 /home/ops/scripts/borg.sh

# Check-reboot-required: notifies admin if reboot is needed
cat > /home/ops/scripts/check-reboot-required.sh <<'CHECK_REBOOT'
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
CHECK_REBOOT
chown ops:ops /home/ops/scripts/check-reboot-required.sh
chmod 755 /home/ops/scripts/check-reboot-required.sh

# Borg backup script (runs as root via sudo, hourly via cron)
cat > /home/ops/scripts/borg-backup.sh <<'BORG_BACKUP'
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
BORG_BACKUP
chown root:root /home/ops/scripts/borg-backup.sh
chmod 755 /home/ops/scripts/borg-backup.sh

# Borg restore script (runs as root via sudo)
cat > /home/ops/scripts/borg-restore.sh <<'BORG_RESTORE'
#!/bin/bash
set -euo pipefail

# Borg restore script — must be run via: sudo borg-restore.sh [args]
# The sudoers entry allows the ops user to run this as root.

OPS_HOME="/home/ops"

# Parse borg env safely — only accept known variables, never execute the file as shell code
while IFS='=' read -r key value; do
  value=$(echo "$value" | tr -d '"')
  case "$key" in
    BORG_REPO|BORG_PASSPHRASE) export "$key=$value" ;;
  esac
done < "$OPS_HOME/.config/borg/env"
export BORG_RSH="ssh -i $OPS_HOME/.ssh/backup_key -o StrictHostKeyChecking=accept-new"

ARCHIVE="${1:-}"

if [ -z "$ARCHIVE" ]; then
  echo "Available archives:"
  echo ""
  borg list
  echo ""
  echo "Usage: sudo $0 <archive-name> [path ...]"
  exit 0
fi

shift

source "$OPS_HOME/.config/server.conf"

echo "Archive:  $ARCHIVE"
echo "Paths:    ${BACKUP_PATHS:-<not configured>}"
[ $# -gt 0 ] && echo "Filter:   $*"
echo ""
read -p "This will overwrite existing files. Continue? [y/N] " -r
[[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# Extract from / so archived absolute paths resolve correctly
cd /
borg extract "::$ARCHIVE" "$@"

echo ""
echo "Restore complete."
BORG_RESTORE
chown root:root /home/ops/scripts/borg-restore.sh
chmod 755 /home/ops/scripts/borg-restore.sh

# ---------------------------------------------------------------------------
# Sudoers: ops can run borg scripts as root
# ---------------------------------------------------------------------------
cat > /etc/sudoers.d/ops <<'SUDOERS'
ops ALL=(root) NOPASSWD: /home/ops/scripts/borg-backup.sh, /home/ops/scripts/borg-restore.sh
SUDOERS
chmod 440 /etc/sudoers.d/ops
visudo -cf /etc/sudoers.d/ops
