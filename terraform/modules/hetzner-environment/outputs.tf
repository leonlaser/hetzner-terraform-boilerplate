output "server_ip" {
  value = hcloud_floating_ip.master.ip_address
}

output "server_ip_v6" {
  value = hcloud_floating_ip.master_v6.ip_address
}

output "ssh_port" {
  value     = random_integer.app_ssh_port.result
  sensitive = true
}

output "environment" {
  value = var.environment_name
}

output "server_id" {
  value = hcloud_server.app.id
}

output "volume_id" {
  value = hcloud_volume.app.id
}

output "traefik_dashboard_password" {
  value       = random_password.app_traefik_dashboard.result
  sensitive   = true
  description = "Generated Traefik dashboard password (username: admin)"
}

output "borg_passphrase" {
  value       = var.backup != null ? random_password.app_borg_passphrase[0].result : null
  sensitive   = true
  description = "Borg encryption passphrase — store securely for disaster recovery"
}

output "db_borg_passphrase" {
  value       = var.database != null && var.backup != null ? random_password.db_borg_passphrase[0].result : null
  sensitive   = true
  description = "DB server Borg encryption passphrase — store securely for disaster recovery"
}
