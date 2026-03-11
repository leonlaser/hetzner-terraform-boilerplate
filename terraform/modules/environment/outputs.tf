output "server_ipv4" {
  value = module.app-server.server_ipv4
}

output "server_ipv6" {
  value = module.app-server.server_ipv6
}

output "ssh_port" {
  value = random_integer.app_ssh_port.result
}

output "environment" {
  value = var.environment_name
}

output "traefik_dashboard_password" {
  value       = random_password.app_traefik_dashboard.result
  sensitive   = true
  description = "Generated Traefik dashboard password (username: admin)"
}
