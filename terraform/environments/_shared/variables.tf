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

variable "environment_name" {
  type = string
}

variable "deploy_branch" {
  type = string
}

variable "project_name" {
  type = string
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

variable "admin_ssh_key_names" {
  type = list(string)
}

variable "location" {
  type    = string
  default = "fsn1"
}

variable "floating_ip_location" {
  type    = string
  default = null
}

variable "smtp_host" {
  type = string
}

variable "smtp_port" {
  type = number
}

variable "smtp_user" {
  type      = string
  sensitive = true
}

variable "smtp_password" {
  type      = string
  sensitive = true
}

variable "server_info_mail_from" {
  type = string
}

variable "server_info_mail_to" {
  type = string
}

variable "acme_mail" {
  type = string
}

variable "delete_protection" {
  type = object({
    server      = bool
    volume      = bool
    floating_ip = bool
  })
  description = "Enable Hetzner delete_protection and OpenTofu prevent_destroy for critical resources"
}

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

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "volume_size" {
  type    = number
  default = 10
}

variable "base_env_vars" {
  type      = map(string)
  default   = {}
  sensitive = true
}

variable "app_env_vars" {
  type      = map(string)
  default   = {}
  sensitive = true
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