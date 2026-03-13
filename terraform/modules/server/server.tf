data "hcloud_server_type" "app" {
  name = var.server_type
}

resource "terraform_data" "current_app_server_config" {
  input = {
    server_type = var.server_type
    location    = var.server_location
  }
}

resource "hcloud_server" "server" {
  name        = "${var.project_name}-${var.environment_name}-${var.server_name}"
  server_type = var.server_type
  location    = var.server_location
  image       = var.server_image_id != null ? var.server_image_id : var.server_image
  labels      = local.server_labels

  delete_protection  = var.server_protection
  rebuild_protection = var.server_protection

  firewall_ids = var.firewall_ids

  user_data = local.cloud_init

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  lifecycle {
    # Catch early if a server_type is not available at the given location.
    precondition {
      condition = (
        (
          var.server_type == terraform_data.current_app_server_config.output.server_type &&
          var.server_location == terraform_data.current_app_server_config.output.location
        ) ||
        anytrue([
          for loc in data.hcloud_server_type.app.locations :
          loc.name == var.server_location && !loc.is_deprecated
        ])
      )
      error_message = "Server type '${var.server_type}' is not available (or deprecated) in location '${var.server_location}'."
    }
  }
}

resource "hcloud_server_network" "private" {
  count = var.private_network_enabled ? 1 : 0

  server_id  = hcloud_server.server.id
  network_id = var.private_network_id
  ip         = var.private_network_ip
}

resource "hcloud_floating_ip" "server_ipv4" {
  count = var.floating_ips_enabled ? 1 : 0

  name              = "${var.project_name}-${var.environment_name}-${var.server_name}-v4"
  type              = "ipv4"
  home_location     = coalesce(var.floating_ip_location, var.server_location)
  delete_protection = var.floating_ip_protection
  labels            = local.ip_labels
}

resource "hcloud_floating_ip_assignment" "server" {
  count = var.floating_ips_enabled ? 1 : 0

  floating_ip_id = hcloud_floating_ip.server_ipv4[0].id
  server_id      = hcloud_server.server.id
}

resource "hcloud_floating_ip" "server_ipv6" {
  count = var.floating_ips_enabled ? 1 : 0

  name              = "${var.project_name}-${var.environment_name}-${var.server_name}-v6"
  type              = "ipv6"
  home_location     = coalesce(var.floating_ip_location, var.server_location)
  delete_protection = var.floating_ip_protection
  labels            = local.ip_labels
}

resource "hcloud_floating_ip_assignment" "server_v6" {
  count          = var.floating_ips_enabled ? 1 : 0
  floating_ip_id = hcloud_floating_ip.server_ipv6[0].id
  server_id      = hcloud_server.server.id
}
