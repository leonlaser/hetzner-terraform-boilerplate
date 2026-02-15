variable "hcloud_token" {
  type      = string
  sensitive = true
  ephemeral = true
}

variable "github_token" {
  type      = string
  sensitive = true
  ephemeral = true
}

variable "github_owner" {
  type = string
}

variable "project_name" {
  type        = string
  description = "Short project identifier used for naming resources (e.g. 'myapp')"
}

variable "domain" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "docker_registry" {
  type    = string
  default = "ghcr.io"
}

variable "ssh_key_names" {
  type = list(string)
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "smtp_host" {
  type = string
}

variable "smtp_port" {
  type = number
}

variable "smtp_from" {
  type = string
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
  type      = string
  sensitive = true
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "volume_size" {
  type    = number
  default = 10
}

variable "app_env_vars" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "Additional application-specific environment variables injected into the deployed .env file"
}
