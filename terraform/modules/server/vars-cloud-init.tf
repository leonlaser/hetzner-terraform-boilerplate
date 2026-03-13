variable "cloud_init_runcmd" {
  type        = list(string)
  default     = []
  description = "Additional commands to run"
}

variable "cloud_init_users" {
  type = list(
    object({
      name                = string,
      groups              = string,
      ssh_authorized_keys = list(string)
    })
  )
  default     = []
  description = "Additional users to inject SSH keys for"
}