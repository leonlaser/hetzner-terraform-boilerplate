# =============================================================================
# HCloud SSH Keys
#
# Reads the projects SSH keys and exports their IDs and public keys,
# so they can be attached to resources like servers.
# =============================================================================

data "hcloud_ssh_key" "ops" {
  for_each = toset(var.ops_ssh_key_names)
  name     = each.value
}

locals {
  ops_ssh_public_keys = [for key in data.hcloud_ssh_key.ops : key.public_key]
}
