# =============================================================================
# App Provisioners — push secrets to app server via SSH after cloud-init
#
# Cloud-init contains ZERO secrets. All sensitive material is delivered here.
# Re-provision for secret rotation:
#   tofu apply -replace=module.environment.terraform_data.app_provisioner
# =============================================================================

# -----------------------------------------------------------------------------
# App server: core secrets (SMTP password, ops internal key)
# -----------------------------------------------------------------------------
resource "terraform_data" "app_provisioner" {
  input = {
    smtp_password   = var.smtp_password
    ops_key         = tls_private_key.ops_user.private_key_openssh
    storagebox_host = hcloud_storage_box_subaccount.backup[0].server
    has_database    = var.database != null
  }

  connection {
    type        = "ssh"
    user        = "ops"
    private_key = tls_private_key.ops_user.private_key_openssh
    host        = hcloud_floating_ip.master.ip_address
    port        = random_integer.app_ssh_port.result
    timeout     = "10m"
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

  # Ops internal key (for app→DB SSH, also used by finish-provisioning)
  provisioner "file" {
    content     = tls_private_key.ops_user.private_key_openssh
    destination = "/home/ops/.ssh/internal_key"
  }

  # SSH config (database + StorageBox connectivity)
  provisioner "file" {
    content = templatefile("${path.module}/templates/files/ssh-config.tftpl", {
      storagebox_host = var.backup != null ? hcloud_storage_box_subaccount.backup[0].server : ""
      database_ip     = var.database != null ? local.internal_ips.database : ""
    })
    destination = "/home/ops/.ssh/config"
  }

  provisioner "remote-exec" {
    inline = ["chmod 600 /home/ops/.ssh/internal_key /home/ops/.ssh/config"]
  }

  depends_on = [
    hcloud_server.app,
    hcloud_floating_ip_assignment.master,
    hcloud_server_network.app,
  ]

  lifecycle {
    ignore_changes = [input]
  }
}

# -----------------------------------------------------------------------------
# App server: backup secrets (borg env, backup SSH key, StorageBox setup)
# -----------------------------------------------------------------------------
resource "terraform_data" "app_backup_provisioner" {
  count = var.backup != null ? 1 : 0

  input = {
    borg_passphrase   = random_password.app_borg_passphrase[0].result
    backup_key        = tls_private_key.app_backup[0].private_key_openssh
    storagebox_host   = hcloud_storage_box_subaccount.backup[0].server
    storagebox_user   = hcloud_storage_box_subaccount.backup[0].username
    storagebox_pw     = hcloud_storage_box_subaccount.backup[0].password
    backup_public_key = tls_private_key.app_backup[0].public_key_openssh
  }

  connection {
    type        = "ssh"
    user        = "ops"
    private_key = tls_private_key.ops_user.private_key_openssh
    host        = hcloud_floating_ip.master.ip_address
    port        = random_integer.app_ssh_port.result
    timeout     = "5m"
  }

  # Borg environment (credentials)
  provisioner "file" {
    content = templatefile("${path.module}/templates/files/borg-env.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
      storagebox_user = hcloud_storage_box_subaccount.backup[0].username
      storagebox_path = "./app"
      borg_passphrase = random_password.app_borg_passphrase[0].result
    })
    destination = "/home/ops/.config/borg/env"
  }

  # Backup SSH private key
  provisioner "file" {
    content     = tls_private_key.app_backup[0].private_key_openssh
    destination = "/home/ops/.ssh/backup_key"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ops/.config/borg/env /home/ops/.ssh/backup_key",

      # Install SSH key on StorageBox (idempotent, uses sshpass)
      "echo '${chomp(tls_private_key.app_backup[0].public_key_openssh)}' | sshpass -p '${hcloud_storage_box_subaccount.backup[0].password}' ssh -p 23 -o StrictHostKeyChecking=accept-new ${hcloud_storage_box_subaccount.backup[0].username}@${hcloud_storage_box_subaccount.backup[0].server} install-ssh-key",

      # Create borg repo directory (home dir has .ssh/ so can't be repo root)
      "ssh -i /home/ops/.ssh/backup_key -o StrictHostKeyChecking=accept-new ${hcloud_storage_box_subaccount.backup[0].username}@${hcloud_storage_box_subaccount.backup[0].server} mkdir app || true",

      # Initialize borg repository (ignore "already exists" error)
      "/home/ops/scripts/borg.sh init --encryption=repokey --remote-path=borg-1.4 || true",
    ]
  }

  depends_on = [terraform_data.app_provisioner]

  lifecycle {
    ignore_changes = [input]
  }
}

# -----------------------------------------------------------------------------
# Finalize: reboot DB (if exists) then app server
# -----------------------------------------------------------------------------
resource "terraform_data" "finalize" {
  input = {
    app_provisioner       = terraform_data.app_provisioner.id
    app_backup            = var.backup != null ? terraform_data.app_backup_provisioner[0].id : null
    db_provisioner        = var.database != null ? terraform_data.db_provisioner[0].id : null
    db_backup_provisioner = var.database != null && var.backup != null ? terraform_data.db_backup_provisioner[0].id : null
  }

  connection {
    type        = "ssh"
    user        = "ops"
    private_key = tls_private_key.ops_user.private_key_openssh
    host        = hcloud_floating_ip.master.ip_address
    port        = random_integer.app_ssh_port.result
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = ["sudo /home/ops/scripts/finish-provisioning.sh"]
  }

  depends_on = [
    terraform_data.app_provisioner,
    terraform_data.app_backup_provisioner,
    terraform_data.db_provisioner,
    terraform_data.db_backup_provisioner,
  ]

  lifecycle {
    ignore_changes = [input]
  }
}