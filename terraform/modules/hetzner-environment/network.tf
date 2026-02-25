resource "hcloud_network" "environment" {
  name     = "${var.project_name}-${var.environment_name}-internal-network"
  ip_range = "10.0.0.0/16"
  labels   = local.network_labels
}

resource "hcloud_network_subnet" "environment" {
  network_id   = hcloud_network.environment.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_firewall" "environment" {
  name   = "${var.project_name}-${var.environment_name}"
  labels = local.firewall_labels

  rule {
    description = "SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = random_integer.app_ssh_port.result
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "HTTPS"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "HTTP (Redirect)"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}
