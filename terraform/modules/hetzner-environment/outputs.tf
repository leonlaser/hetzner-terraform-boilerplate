output "server_ip" {
  value = hcloud_floating_ip.master.ip_address
}

output "server_ip_v6" {
  value = hcloud_floating_ip.master_v6.ip_address
}

output "ssh_port" {
  value     = random_integer.app_ssh_port.result
}

output "environment" {
  value = var.environment_name
}

output "server_id" {
  value = hcloud_server.app.id
}

output "traefik_dashboard_password" {
  value       = random_password.app_traefik_dashboard.result
  sensitive   = true
  description = "Generated Traefik dashboard password (username: admin)"
}
