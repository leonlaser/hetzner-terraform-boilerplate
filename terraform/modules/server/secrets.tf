resource "tls_private_key" "ops_user" {
  algorithm = "ED25519"
}

resource "tls_private_key" "backup" {
  count     = var.backup_enabled ? 1 : 0
  algorithm = "ED25519"

  lifecycle {
    ignore_changes = all
  }
}
