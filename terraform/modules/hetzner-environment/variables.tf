variable "project_name" {
  type        = string
  description = "Short project identifier used for naming resources (e.g. 'myapp')"
}

variable "environment_name" {
  type        = string
  description = "Environment name (e.g. 'prod', 'stage', 'demo')"
}

variable "deploy_branch" {
  type        = string
  description = "Git branch allowed to deploy to this environment"
}

variable "server_type" {
  type        = string
  default     = "cx23"
  description = "Hetzner server type (e.g. cx33, cx43, cpx22, cpx32, ccx13, ccx23)"
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

variable "admin_ssh_key_ids" {
  type        = list(number)
  description = "List of Hetzner SSH key IDs for admin access (attached to servers at creation)"
}

variable "admin_ssh_public_keys" {
  type        = list(string)
  description = "Public key content for admin SSH keys (added to ops user authorized_keys)"
}

variable "location" {
  type        = string
  default     = "fsn1"
  description = "Hetzner datacenter location for servers and volumes (fsn1, nbg1, hel1, ash)"
}

variable "floating_ip_location" {
  type        = string
  default     = null
  description = "Hetzner location for floating IPs. Defaults to var.location if not set."
}

variable "smtp_host" {
  type        = string
  description = "SMTP server hostname"
}

variable "smtp_port" {
  type        = number
  description = "SMTP server port"
}

variable "server_info_mail_from" {
  type        = string
  description = "Sender address for server info mails"
}

variable "smtp_user" {
  type        = string
  sensitive   = true
  description = "SMTP login user"
}

variable "smtp_password" {
  type        = string
  sensitive   = true
  description = "SMTP login password"
}

variable "server_info_mail_to" {
  type        = string
  description = "Email address for unattended-upgrades and server reboot notifications"
}

variable "acme_mail" {
  type        = string
  description = "Email address for Let's Encrypt ACME certificate notifications"
}

variable "delete_protection" {
  type = object({
    server      = bool
    volume      = bool
    floating_ip = bool
  })
  description = "Enable Hetzner delete_protection and OpenTofu prevent_destroy for critical resources"
}

# ---------------------------------------------------------------------------
# Application environment variables
# ---------------------------------------------------------------------------
# These are passed into the .env template deployed to the server.
# Customize or extend them to match your application's needs.

variable "backup" {
  type = object({
    storage_box_id = number
  })
  default     = null
  description = "StorageBox ID for borg backups. Null disables backups."
}

variable "borg_passphrase" {
  type      = string
  sensitive = true
}

variable "app_env_vars" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "Additional application-specific environment variables injected into the deployed .env file"
}

variable "swap_size" {
  type        = number
  default     = 0
  description = "Swap file size in GB. 0 disables swap."
}

variable "database" {
  type = object({
    server_type = string
    volume_size = number
  })
  default     = null
  description = "Dedicated database server. Null means DB runs on the app server."
}
