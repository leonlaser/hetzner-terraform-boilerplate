#!/usr/bin/env bash
set -eux

# =============================================================================
# Image cleanup — minimize snapshot size and remove instance-specific state
# =============================================================================

# ---------------------------------------------------------------------------
# Cloud-init: remove all instance-specific state so it re-runs on first boot
# ---------------------------------------------------------------------------
if command -v cloud-init &>/dev/null; then
  cloud-init clean --logs --machine-id --seed --configs all
fi
rm -rf /run/cloud-init/* /var/lib/cloud/*

# ---------------------------------------------------------------------------
# APT: remove caches and package lists
# ---------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get autopurge -y
apt-get clean
rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# SSH host keys: regenerated on first boot by cloud-init
# ---------------------------------------------------------------------------
rm -f /etc/ssh/ssh_host_*

# ---------------------------------------------------------------------------
# Logs: flush and truncate
# ---------------------------------------------------------------------------
if command -v journalctl &>/dev/null; then
  journalctl --flush --rotate --vacuum-time=0 || true
fi

# Truncate all log files, remove archived/compressed logs
find /var/log -type f -name '*.gz' -delete
find /var/log -type f -name '*.xz' -delete
find /var/log -type f -name '*.[0-9]' -delete
find /var/log -type f -exec truncate -s 0 {} \;

# ---------------------------------------------------------------------------
# Root home: remove caches, SSH keys, history
# ---------------------------------------------------------------------------
rm -rf /root/.cache /root/.ssh
rm -f /root/.bash_history /root/.lesshst /root/.viminfo

# ---------------------------------------------------------------------------
# Filesystem: trim unused blocks for smaller snapshot
# ---------------------------------------------------------------------------
fstrim --all || true
sync
