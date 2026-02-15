resource "hcloud_server" "app" {
  name        = "${var.environment}-app-server"
  server_type = var.server_type
  location    = var.location
  image       = "ubuntu-24.04"
  ssh_keys    = var.ssh_key_ids

  firewall_ids = [hcloud_firewall.app.id]

  user_data = templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
    floating_ip                 = hcloud_floating_ip.master.ip_address
    generated_public_key        = tls_private_key.default.public_key_openssh
    unattended_upgrades_mail_to = var.unattended_upgrades_mail_to
    smtp_host                   = var.smtp_host
    smtp_port                   = var.smtp_port
    smtp_from                   = var.smtp_from
    smtp_user                   = var.smtp_user
    smtp_password               = var.smtp_password
    volume_id                   = hcloud_volume.storage.id
  })

  network {
    network_id = hcloud_network.internal.id
    ip         = "10.0.1.10"
  }

  depends_on = [hcloud_network_subnet.app]
}

resource "hcloud_floating_ip" "master" {
  type          = "ipv4"
  home_location = var.location
}

resource "hcloud_floating_ip_assignment" "master" {
  floating_ip_id = hcloud_floating_ip.master.id
  server_id      = hcloud_server.app.id
}

resource "hcloud_volume" "storage" {
  name     = "${var.environment}-storage"
  size     = var.volume_size
  location = var.location
  format   = "ext4"
}

resource "hcloud_volume_attachment" "storage" {
  volume_id = hcloud_volume.storage.id
  server_id = hcloud_server.app.id
  automount = true
}
