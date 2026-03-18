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
