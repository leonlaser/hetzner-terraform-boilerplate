resource "tls_private_key" "db_backup" {
  count     = var.database != null && var.backup != null ? 1 : 0
  algorithm = "ED25519"

  lifecycle {
    ignore_changes = all
  }
}

resource "random_password" "db_borg_passphrase" {
  count            = var.database != null && var.backup != null ? 1 : 0
  length           = 64
  special          = true
  override_special = local.safe_special_chars

  lifecycle {
    ignore_changes = all
  }
}
