resource "tls_private_key" "db_backup" {
  count     = var.database != null && var.backup != null ? 1 : 0
  algorithm = "ED25519"

  lifecycle {
    ignore_changes = all
  }
}
