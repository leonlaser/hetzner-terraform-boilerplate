resource "random_password" "storage_box_password" {
  count            = var.backup != null ? 1 : 0
  length           = 64
  special          = true
  override_special = local.safe_special_chars

  lifecycle {
    ignore_changes = all
  }
}

resource "hcloud_storage_box_subaccount" "backup" {
  count = var.backup != null ? 1 : 0

  storage_box_id = var.backup.storage_box_id

  name           = "backup-${var.project_name}-${var.environment_name}"
  description    = "Managed by Terraform"
  home_directory = "${var.project_name}/${var.environment_name}"
  password       = random_password.storage_box_password[0].result

  access_settings = {
    ssh_enabled = true
  }

  lifecycle {
    ignore_changes = [password]
  }
}
