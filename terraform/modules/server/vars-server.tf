# ---------------------------------------------------------------------------
# Server configuration
# ---------------------------------------------------------------------------
variable "ops_ssh_public_keys" {
  type        = list(string)
  description = "Public key content for admin SSH keys (added to ops user authorized_keys)"
}

variable "server_name" {
  type = string
}

variable "server_image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "server_image_id" {
  type        = number
  default     = null
  description = "Packer snapshot ID. When set, overrides server_image."
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "server_location" {
  type        = string
  default     = "fsn1"
  description = "Hetzner datacenter location for servers (fsn1, nbg1, hel1, ash)"
}

variable "server_swap_size" {
  type        = number
  default     = 0
  description = "Swap file size in GB. 0 disables swap."
}

variable "server_protection" {
  type        = bool
  description = "Enables Hetzner delete_protection"
}

variable "server_role" {
  type        = string
  default     = "server"
  description = "Adds a 'role' label to the server"
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
variable "backup_enabled" {
  type        = bool
  default     = false
  description = "Enable backups"
}

variable "backup_storage_box_id" {
  type        = number
  default     = 0
  description = "StorageBox ID for backups"
}

variable "backup_passphrase" {
  type        = string
  sensitive   = true
  description = "Passphrase to encrypt and decrypt backups"
}

variable "backup_paths" {
  type        = string
  default     = ""
  description = "Space-separated list of paths to include in borg backups"
}
