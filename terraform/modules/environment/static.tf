locals {
  internal_ips = {
    app      = "10.0.1.10"
    database = "10.0.1.20"
  }

  # Special characters safe for use in .env files (single-quoted values),
  # YAML values, and URI connection strings (DATABASE_URL).
  # Excludes: ' " ` $ \ # : { } [ ] | > < @ / ! + ? %
  safe_special_chars = "-_=^~."

  # Labels applied to all Hetzner Cloud resources
  base_labels = {
    project     = var.project_name
    environment = var.environment_name
    managed-by  = "opentofu"
  }
  app_labels      = merge(local.base_labels, { role = "app" })
  database_labels = merge(local.base_labels, { role = "database" })
  network_labels  = merge(local.base_labels, { role = "network" })
  firewall_labels = merge(local.base_labels, { role = "firewall" })
  ip_labels       = merge(local.base_labels, { role = "ip" })
}
