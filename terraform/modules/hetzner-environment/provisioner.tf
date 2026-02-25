# =============================================================================
# Provisioners — push secrets to servers via SSH after cloud-init completes
#
# Cloud-init contains ZERO secrets. All sensitive material is delivered here.
# Re-provision for secret rotation:
#   tofu apply -replace=module.environment.terraform_data.app_provisioner
# =============================================================================

# -----------------------------------------------------------------------------
# 1. App server: core secrets (SMTP password, ops internal key)
# -----------------------------------------------------------------------------
resource "terraform_data" "app_provisioner" {
  input = {
    smtp_password = var.smtp_password
    ops_key       = tls_private_key.ops_user.private_key_openssh
    has_database  = var.database != null
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

  provisioner "remote-exec" {
    inline = ["chmod 600 /home/ops/.ssh/internal_key"]
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
# 2. App server: backup secrets (borg env, backup SSH key, StorageBox setup)
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

  # Backup SSH config
  provisioner "file" {
    content = templatefile("${path.module}/templates/files/backup-ssh-config.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
    })
    destination = "/home/ops/.ssh/config"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ops/.config/borg/env /home/ops/.ssh/backup_key /home/ops/.ssh/config",

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
# 3. DB server: core secrets (SMTP password) — via app bastion
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
    hcloud_server_network.database,
    terraform_data.app_provisioner,
  ]

  lifecycle {
    ignore_changes = [input]
  }
}

# -----------------------------------------------------------------------------
# 4. DB server: backup secrets — via app bastion
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
    content = templatefile("${path.module}/templates/files/backup-ssh-config.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
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

# -----------------------------------------------------------------------------
# 5. Finalize: reboot DB (if exists) then app server
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
