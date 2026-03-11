locals {
  # Special characters safe for use in .env files (single-quoted values),
  # YAML values, and URI connection strings (DATABASE_URL).
  # Excludes: ' " ` $ \ # : { } [ ] | > < @ / ! + ? %
  safe_special_chars = "-_=^~."

  server_labels   = merge(var.base_labels, { role = var.server_role })
  network_labels  = merge(var.base_labels, { role = "network" })
  firewall_labels = merge(var.base_labels, { role = "firewall" })
  ip_labels       = merge(var.base_labels, { role = "ip" })
}
