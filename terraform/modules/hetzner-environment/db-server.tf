data "hcloud_server_type" "database" {
  count = var.database != null ? 1 : 0
  name  = var.database.server_type
}

resource "terraform_data" "current_db_server_config" {
  count = var.database != null ? 1 : 0
  input = {
    server_type = var.database.server_type
    location    = var.location
  }
}

resource "hcloud_server" "database" {
  count = var.database != null ? 1 : 0

  name        = "${var.project_name}-${var.environment_name}-db-server"
  server_type = var.database.server_type
  location    = var.location
  image       = "ubuntu-24.04"
  ssh_keys    = var.admin_ssh_key_ids
  labels      = local.database_labels

  delete_protection  = var.delete_protection.server
  rebuild_protection = var.delete_protection.server

  firewall_ids = [hcloud_firewall.database[0].id]
  user_data    = local.db_cloud_init

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.environment.id
    ip         = local.internal_ips.database
    alias_ips  = []
  }

  depends_on = [hcloud_network_subnet.environment]

  lifecycle {
    precondition {
      condition = (
        (
          var.database.server_type == terraform_data.current_db_server_config[0].output.server_type &&
          var.location == terraform_data.current_db_server_config[0].output.location
        ) ||
        anytrue([
          for loc in data.hcloud_server_type.database[0].locations :
          loc.name == var.location && !loc.is_deprecated
        ])
      )
      error_message = "Database server type '${var.database.server_type}' is not available (or deprecated) in location '${var.location}'."
    }
  }
}

resource "hcloud_volume" "database" {
  count = var.database != null ? 1 : 0

  name              = "${var.project_name}-${var.environment_name}-db-storage"
  size              = var.database.volume_size
  location          = var.location
  format            = "ext4"
  delete_protection = var.delete_protection.volume
  labels            = local.database_labels
}

resource "hcloud_volume_attachment" "database" {
  count = var.database != null ? 1 : 0

  volume_id = hcloud_volume.database[0].id
  server_id = hcloud_server.database[0].id
  automount = true
}
