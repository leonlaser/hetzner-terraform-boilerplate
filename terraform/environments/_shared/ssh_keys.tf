# =============================================================================
# HCloud SSH Keys
#
# Reads the projects SSH keys and exports their IDs, so they can be attached to
# resources like servers.
# =============================================================================

data "hcloud_ssh_key" "root_ssh_key_ids" {
  for_each = toset(var.root_access_ssh_key_names)
  name     = each.value
}

locals {
  root_ssh_key_ids = [for key in data.hcloud_ssh_key.root_ssh_key_ids : key.id]
}
