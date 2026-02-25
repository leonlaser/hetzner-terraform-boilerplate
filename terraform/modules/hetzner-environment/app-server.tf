data "hcloud_server_type" "app" {
  name = var.server_type
}

resource "terraform_data" "current_app_server_config" {
  input = {
    server_type = var.server_type
    location    = var.location
  }
}

resource "hcloud_server" "app" {
  name        = "${var.project_name}-${var.environment_name}-app-server"
  server_type = var.server_type
  location    = var.location
  image       = "ubuntu-24.04"
  ssh_keys    = var.root_ssh_key_ids
  labels      = local.app_labels

  delete_protection  = var.delete_protection.server
  rebuild_protection = var.delete_protection.server

  firewall_ids = [hcloud_firewall.environment.id]

  user_data = local.cloud_init

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  depends_on = [hcloud_network_subnet.environment]

  lifecycle {
    # Catch early if a server_type is not available at the given location.
    precondition {
      condition = (
        (
          var.server_type == terraform_data.current_app_server_config.output.server_type &&
          var.location == terraform_data.current_app_server_config.output.location
        ) ||
        anytrue([
          for loc in data.hcloud_server_type.app.locations :
          loc.name == var.location && !loc.is_deprecated
        ])
      )
      error_message = "Server type '${var.server_type}' is not available (or deprecated) in location '${var.location}'."
    }
  }
}

resource "hcloud_server_network" "app" {
  server_id  = hcloud_server.app.id
  network_id = hcloud_network.environment.id
  ip         = local.internal_ips.app
}

resource "hcloud_floating_ip" "master" {
  type              = "ipv4"
  home_location     = coalesce(var.floating_ip_location, var.location)
  delete_protection = var.delete_protection.floating_ip
  labels            = local.ip_labels
}

resource "hcloud_floating_ip_assignment" "master" {
  floating_ip_id = hcloud_floating_ip.master.id
  server_id      = hcloud_server.app.id
}

resource "hcloud_floating_ip" "master_v6" {
  type              = "ipv6"
  home_location     = coalesce(var.floating_ip_location, var.location)
  delete_protection = var.delete_protection.floating_ip
  labels            = local.ip_labels
}

resource "hcloud_floating_ip_assignment" "master_v6" {
  floating_ip_id = hcloud_floating_ip.master_v6.id
  server_id      = hcloud_server.app.id
}

resource "hcloud_volume" "app" {
  name              = "${var.project_name}-${var.environment_name}-app-storage"
  size              = var.volume_size
  location          = var.location
  format            = "ext4"
  delete_protection = var.delete_protection.volume
  labels            = local.app_labels
}

resource "hcloud_volume_attachment" "storage" {
  volume_id = hcloud_volume.app.id
  server_id = hcloud_server.app.id
  automount = true
}
