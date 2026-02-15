variable "project_name" {
  type        = string
  description = "Short project identifier used for naming resources (e.g. 'myapp')"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. 'production', 'staging', 'demo')"
}

variable "deploy_branch" {
  type        = string
  description = "Git branch allowed to deploy to this environment"
}

variable "server_type" {
  type        = string
  default     = "cx23"
  description = "Hetzner server type (e.g. cx32, cx42)"
}

variable "volume_size" {
  type        = number
  default     = 10
  description = "Block storage volume size in GB"
}

variable "domain" {
  type        = string
  description = "Domain name pointing to the server's floating IP"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name (without owner prefix)"
}

variable "docker_registry" {
  type        = string
  default     = "ghcr.io"
  description = "Docker registry for pulling container images"
}

variable "ssh_key_ids" {
  type        = list(number)
  description = "List of Hetzner SSH key IDs to install on the server"
}

variable "location" {
  type        = string
  default     = "nbg1"
  description = "Hetzner datacenter location (nbg1, fsn1, hel1, ash)"
}

variable "smtp_host" {
  type        = string
  description = "SMTP server hostname"
}

variable "smtp_port" {
  type        = number
  description = "SMTP server port"
}

variable "smtp_from" {
  type        = string
  description = "SMTP sender address"
}

variable "smtp_user" {
  type      = string
  sensitive = true
}

variable "smtp_password" {
  type      = string
  sensitive = true
}

variable "unattended_upgrades_mail_to" {
  type        = string
  description = "Email address for unattended-upgrades and server reboot notifications"
}

variable "acme_mail" {
  type        = string
  description = "Email address for Let's Encrypt ACME certificate notifications"
}

variable "traefik_dashboard_users" {
  type        = string
  sensitive   = true
  description = "htpasswd-encoded basic auth credentials for the Traefik dashboard"
}

# ---------------------------------------------------------------------------
# Application environment variables
# ---------------------------------------------------------------------------
# These are passed into the .env template deployed to the server.
# Customize or extend them to match your application's needs.

variable "app_env_vars" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "Additional application-specific environment variables injected into the deployed .env file"
}
