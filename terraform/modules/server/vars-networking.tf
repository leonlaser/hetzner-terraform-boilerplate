variable "private_network_enabled" {
  type        = bool
  default     = false
  description = "If set will add the server toa private network - requires private_network_id and private_network_ip"
}

variable "private_network_id" {
  type        = number
  default     = null
  description = "ID if the network"
}

variable "private_network_ip" {
  type        = string
  default     = null
  description = "Server IP in the network"
}

variable "firewall_ids" {
  type        = list(number)
  default     = []
  description = "List of firewall IDs to attach to the server"
}

variable "floating_ips_enabled" {
  type        = bool
  default     = false
  description = "Create floating IPv4 and IPv6 for server"
}

variable "floating_ip_location" {
  type        = string
  default     = null
  description = "Hetzner location for floating IPs"
}

variable "floating_ip_protection" {
  type        = bool
  default     = false
  description = "Enables Hetzner delete_protection"
}

variable "server_ssh_port" {
  type        = number
  default     = 22
  description = "Server SSH port"
}

variable "server_ufw_allowed_ports" {
  type        = list(string)
  default     = []
  description = "List of ports to allow traffic on the server's firewall"
}

variable "server_allow_tcp_forwarding" {
  type        = string
  default     = "no"
  description = "AllowTcpForwarding sshd setting. Set to 'yes' for bastion servers."
}

variable "ansible_host" {
  type        = string
  default     = null
  description = "Override Ansible target host (e.g. private IP when using bastion)"
}

variable "ansible_bastion_host" {
  type        = string
  default     = null
  description = "Bastion host for Ansible SSH connections"
}

variable "ansible_bastion_port" {
  type        = number
  default     = 22
  description = "Bastion SSH port"
}

variable "ansible_bastion_user" {
  type        = string
  default     = "ops"
  description = "Bastion SSH user"
}

variable "ansible_bastion_private_key_file" {
  type        = string
  default     = null
  description = "Path to bastion SSH private key file"
}