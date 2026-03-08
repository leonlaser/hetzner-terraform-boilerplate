locals {
  # Special characters safe for use in .env files (single-quoted values),
  # YAML values, and URI strings.
  # Excludes: ' " ` $ \ # : { } [ ] | > < @ / ! + ? %
  safe_special_chars = "-_=^~."
}

resource "random_password" "database_password" {
  length           = 64
  special          = true
  override_special = local.safe_special_chars

  # Once the database has been initialized, the database password should not change. 
  lifecycle {
    ignore_changes = all
  }
}

locals {
  dynamic_env_vars = {
    APP_URL     = "https://${var.domain}"
    DB_PASSWORD = random_string.database_password.result
  }
}
