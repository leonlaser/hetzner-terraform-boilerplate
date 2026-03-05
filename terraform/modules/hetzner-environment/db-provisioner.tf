# =============================================================================
# DB Provisioners — push secrets to DB server via app bastion
#
# Re-provision for secret rotation:
#   tofu apply -replace=module.environment.terraform_data.db_provisioner
# =============================================================================

# -----------------------------------------------------------------------------
# DB server: core secrets (SMTP password)
# -----------------------------------------------------------------------------
resource "terraform_data" "db_provisioner" {
  count = var.database != null ? 1 : 0

  input = {
    smtp_password = var.smtp_password
  }

  connection {
    type        = "ssh"
    user        = "ops"
    private_key = tls_private_key.ops_user.private_key_openssh
    host        = local.internal_ips.database
    port        = 22
    timeout     = "10m"

    bastion_host        = hcloud_floating_ip.master.ip_address
    bastion_port        = random_integer.app_ssh_port.result
    bastion_user        = "ops"
    bastion_private_key = tls_private_key.ops_user.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait 2>/dev/null"]
  }

  # SMTP password
  provisioner "file" {
    content     = var.smtp_password
    destination = "/home/ops/.msmtp-password"
  }

  provisioner "remote-exec" {
    inline = ["chmod 600 /home/ops/.msmtp-password"]
  }

  depends_on = [
    hcloud_server.database,
    terraform_data.app_provisioner,
  ]

  lifecycle {
    ignore_changes = [input]
  }
}

# -----------------------------------------------------------------------------
# DB server: backup secrets (borg env, backup SSH key, StorageBox setup)
# -----------------------------------------------------------------------------
resource "terraform_data" "db_backup_provisioner" {
  count = var.database != null && var.backup != null ? 1 : 0

  input = {
    db_borg_passphrase = random_password.db_borg_passphrase[0].result
    db_backup_key      = tls_private_key.db_backup[0].private_key_openssh
    storagebox_host    = hcloud_storage_box_subaccount.backup[0].server
    storagebox_user    = hcloud_storage_box_subaccount.backup[0].username
    storagebox_pw      = hcloud_storage_box_subaccount.backup[0].password
    db_backup_pub_key  = tls_private_key.db_backup[0].public_key_openssh
  }

  connection {
    type        = "ssh"
    user        = "ops"
    private_key = tls_private_key.ops_user.private_key_openssh
    host        = local.internal_ips.database
    port        = 22
    timeout     = "5m"

    bastion_host        = hcloud_floating_ip.master.ip_address
    bastion_port        = random_integer.app_ssh_port.result
    bastion_user        = "ops"
    bastion_private_key = tls_private_key.ops_user.private_key_openssh
  }

  # Borg environment (credentials)
  provisioner "file" {
    content = templatefile("${path.module}/templates/files/borg-env.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
      storagebox_user = hcloud_storage_box_subaccount.backup[0].username
      storagebox_path = "./db"
      borg_passphrase = random_password.db_borg_passphrase[0].result
    })
    destination = "/home/ops/.config/borg/env"
  }

  # DB backup SSH private key
  provisioner "file" {
    content     = tls_private_key.db_backup[0].private_key_openssh
    destination = "/home/ops/.ssh/backup_key"
  }

  # Backup SSH config
  provisioner "file" {
    content = templatefile("${path.module}/templates/files/ssh-config.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
      database_ip = ""
    })
    destination = "/home/ops/.ssh/config"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ops/.config/borg/env /home/ops/.ssh/backup_key /home/ops/.ssh/config",

      # Install SSH key on StorageBox
      "echo '${chomp(tls_private_key.db_backup[0].public_key_openssh)}' | sshpass -p '${hcloud_storage_box_subaccount.backup[0].password}' ssh -p 23 -o StrictHostKeyChecking=accept-new ${hcloud_storage_box_subaccount.backup[0].username}@${hcloud_storage_box_subaccount.backup[0].server} install-ssh-key",

      # Create borg repo directory
      "ssh -i /home/ops/.ssh/backup_key -o StrictHostKeyChecking=accept-new ${hcloud_storage_box_subaccount.backup[0].username}@${hcloud_storage_box_subaccount.backup[0].server} mkdir db || true",

      # Initialize borg repository
      "/home/ops/scripts/borg.sh init --encryption=repokey --remote-path=borg-1.4 || true",
    ]
  }

  depends_on = [terraform_data.db_provisioner]

  lifecycle {
    ignore_changes = [input]
  }
}