variable "smtp_host" {
  type        = string
  description = "SMTP server hostname"
}

variable "smtp_port" {
  type        = number
  description = "SMTP server port"
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

variable "server_info_mail_from" {
  type        = string
  description = "Sender address for server info mails"
}

variable "server_info_mail_to" {
  type        = string
  description = "Email address for unattended-upgrades and server reboot notifications"
}