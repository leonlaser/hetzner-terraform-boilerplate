#!/usr/bin/env bash
set -eux
export DEBIAN_FRONTEND=noninteractive

# =============================================================================
# Docker server setup — rootless Docker
# =============================================================================

# ---------------------------------------------------------------------------
# Docker APT repository (DEB822 .sources format)
# ---------------------------------------------------------------------------
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

UBUNTU_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
cat > /etc/apt/sources.list.d/docker.sources <<DOCKER_SOURCES
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
DOCKER_SOURCES

apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  uidmap \
  dbus-user-session

# ---------------------------------------------------------------------------
# Sysctl for rootless Docker
# ---------------------------------------------------------------------------
cat > /etc/sysctl.d/99-docker-rootless.conf <<'SYSCTL'
# Allow unprivileged users to bind ports from 80
net.ipv4.ip_unprivileged_port_start=80
# Increase user namespaces
user.max_user_namespaces=28633
# Prefer RAM over swap
vm.swappiness=10
SYSCTL

sysctl --system

# ---------------------------------------------------------------------------
# Docker user (UID 1000 — rootless Docker expects this)
# Docker CE already created the 'docker' group — create user with it as primary
# ---------------------------------------------------------------------------
useradd -m -u 1000 -s /bin/bash -g docker -G users docker

# subuid/subgid for docker user
echo "docker:100000:65536" >> /etc/subuid
echo "docker:100000:65536" >> /etc/subgid

# ---------------------------------------------------------------------------
# Rootless Docker environment files
# ---------------------------------------------------------------------------
cat > /home/docker/.docker-env <<'DOCKER_ENV'
export XDG_RUNTIME_DIR=/run/user/1000
export PATH=/usr/bin:$PATH
DOCKER_ENV
chown docker:docker /home/docker/.docker-env
chmod 644 /home/docker/.docker-env

# Source Docker env in .profile and .bashrc
grep -qxF '. ~/.docker-env' /home/docker/.profile 2>/dev/null || echo '. ~/.docker-env' >> /home/docker/.profile
grep -qxF '. ~/.docker-env' /home/docker/.bashrc 2>/dev/null || echo '. ~/.docker-env' >> /home/docker/.bashrc
chown docker:docker /home/docker/.profile /home/docker/.bashrc

# ---------------------------------------------------------------------------
# Rootless Docker installation
# ---------------------------------------------------------------------------

# Disable rootful Docker
systemctl disable docker.service docker.socket
systemctl stop docker.service docker.socket || true
rm -f /var/run/docker.sock

# Enable linger so the user manager starts on boot
loginctl enable-linger docker

# Wait for user manager to be ready
sleep 2

# Install rootless Docker as docker user
# Uses systemd-run --pipe (not machinectl shell) for proper stdout/stderr
# forwarding and exit code propagation in non-interactive contexts.
systemd-run --machine=docker@ --user --pipe --wait \
  /usr/bin/dockerd-rootless-setuptool.sh install

systemd-run --machine=docker@ --user --pipe --wait \
  /usr/bin/systemctl --user enable docker

# ---------------------------------------------------------------------------
# SSH environment (for non-interactive SSH commands, e.g. CI/CD deployment)
# ---------------------------------------------------------------------------
mkdir -p /home/docker/.ssh
cat > /home/docker/.ssh/environment <<'SSH_ENV'
XDG_RUNTIME_DIR=/run/user/1000
DOCKER_HOST=unix:///run/user/1000/docker.sock
SSH_ENV
chown -R docker:docker /home/docker/.ssh
chmod 700 /home/docker/.ssh
chmod 600 /home/docker/.ssh/environment

# ---------------------------------------------------------------------------
# Home directory permissions
# ---------------------------------------------------------------------------
chmod 750 /home/docker

# ---------------------------------------------------------------------------
# Ops user access
# ---------------------------------------------------------------------------
usermod -aG docker ops

# Shell function: dkr — runs commands as docker user from /home/docker/current
cat >> /home/ops/.bashrc <<'BASH_FUNC'
dkr() { cd /home/docker/current && sudo -u docker "$@"; }
BASH_FUNC
chown ops:ops /home/ops/.bashrc

# Sudoers: ops can run commands as docker user
cat > /etc/sudoers.d/docker <<'SUDOERS'
ops ALL=(docker) NOPASSWD: ALL
SUDOERS
chmod 440 /etc/sudoers.d/docker
visudo -cf /etc/sudoers.d/docker
