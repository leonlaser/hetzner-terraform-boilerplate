#!/bin/bash
set -euo pipefail

# Borg restore script — must be run via: sudo borg-restore.sh <user-home> [archive] [path ...]
# The sudoers entry allows the ops user to run this as root.

USER_HOME="${1:?Usage: borg-restore.sh <user-home> [archive-name] [path ...]}"
shift

# Parse borg env safely — only accept known variables, never execute the file as shell code
while IFS='=' read -r key value; do
  value=$(echo "$value" | tr -d '"')
  case "$key" in
    BORG_REPO|BORG_PASSPHRASE) export "$key=$value" ;;
  esac
done < "$USER_HOME/.config/borg/env"
export BORG_RSH="ssh -i $USER_HOME/.ssh/backup_key -o StrictHostKeyChecking=accept-new"

ARCHIVE="${1:-}"

if [ -z "$ARCHIVE" ]; then
  echo "Available archives:"
  echo ""
  borg list
  echo ""
  echo "Usage: sudo $0 <user-home> <archive-name> [path ...]"
  exit 0
fi

shift

source "$USER_HOME/.config/server.conf"

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