output "server_ip" {
  value = hcloud_floating_ip.master.ip_address
}

output "environment" {
  value = var.environment
}

output "server_id" {
  value = hcloud_server.app.id
}

output "volume_id" {
  value = hcloud_volume.storage.id
}
