output "server_ipv4" {
  value = var.floating_ips_enabled ? hcloud_floating_ip.server_ipv4[0].ip_address : hcloud_server.server.ipv4_address
}

output "server_ipv6" {
  value = var.floating_ips_enabled ? hcloud_floating_ip.server_ipv6[0].ip_address : hcloud_server.server.ipv6_address
}

output "ops_public_key" {
  value = tls_private_key.ops_user.public_key_openssh
}

output "ansible_ssh_key_file" {
  value = local_sensitive_file.ansible_ssh_key.filename
}