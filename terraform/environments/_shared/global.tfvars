# =============================================================================
# Project
# =============================================================================

project_name = "[REPLACE_ME]"

# =============================================================================
# Hetzner Cloud
# =============================================================================

# Names of SSH keys already uploaded to your Hetzner project
admin_ssh_key_names = ["[REPLACE_ME]"]

# Hetzner datacenter location (default: nbg1)
# Options: fsn1 (Falkenstein), nbg1 (Nuremberg), hel1 (Helsinki), ash (Ashburn)
location = "fsn1"

# Server type (default: cx23)
server_type = "cx23"

# Volume size in GB (default: 10)
volume_size = 10

# =============================================================================
# GitHub
# =============================================================================

github_owner      = "[REPLACE_ME]"
github_repository = "[REPLACE_ME]"
docker_registry   = "ghcr.io"

# =============================================================================
# Email / SMTP
# =============================================================================

# Sender address for server info mails
server_info_mail_from = "[REPLACE_ME]"

# Email address for unattended-upgrades and server reboot notifications
server_info_mail_to = "[REPLACE_ME]"

# Email address for Let's Encrypt ACME certificate notifications
acme_mail = "[REPLACE_ME]"

smtp_host = "[REPLACE_ME]"
smtp_port = 587

# =============================================================================
# Application-Specific Environment Variables (optional)
# =============================================================================

base_env_vars = {
  GLOBAL_VARIABLE = "GLOBAL_VARIABLE"
  DB_PORT = 5432
  DB_HOST = "[REPLACE_ME]"
  DB_NAME = "[REPLACE_ME]"
  DB_USER = "[REPLACE_ME]"
}
