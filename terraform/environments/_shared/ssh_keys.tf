# =============================================================================
# HCloud SSH Keys
#
# Reads the projects SSH keys and exports their IDs and public keys,
# so they can be attached to resources like servers.
# =============================================================================

data "hcloud_ssh_key" "admin" {
  for_each = toset(var.admin_ssh_key_names)
  name     = each.value
}

locals {
  admin_ssh_key_ids     = [for key in data.hcloud_ssh_key.admin : key.id]
  admin_ssh_public_keys = [for key in data.hcloud_ssh_key.admin : key.public_key]
}
