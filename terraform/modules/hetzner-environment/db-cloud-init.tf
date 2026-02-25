locals {
  db_cloud_init = var.database != null ? templatefile("${path.module}/templates/db-cloud-init.yml.tftpl", {
    generated_public_key = tls_private_key.app_deploy_user.public_key_openssh
    volume_id            = hcloud_volume.database[0].id

    auto_upgrades_config = templatefile("${path.module}/templates/files/30auto-upgrades.tftpl", {
      server_info_mail_from = var.server_info_mail_from
      server_info_mail_to   = var.server_info_mail_to
    })

    msmtp_config = templatefile("${path.module}/templates/files/msmtprc.tftpl", {
      smtp_host             = var.smtp_host
      smtp_port             = var.smtp_port
      server_info_mail_from = var.server_info_mail_from
      smtp_user             = var.smtp_user
      smtp_password         = var.smtp_password
    })

    check_reboot_script = templatefile("${path.module}/templates/files/check-reboot-required.sh.tftpl", {
      server_info_mail_to = var.server_info_mail_to
    })

    docker_compose_config = templatefile("${path.module}/templates/files/db-docker-compose.yml.tftpl", {
      db_user      = var.app_env_vars["DB_NAME"]
      db_password  = var.app_env_vars["DB_PASSWORD"]
      db_name      = var.app_env_vars["DB_NAME"]
      db_listen_ip = local.internal_ips.database
    })

    backup_enabled = var.backup != null

    borg_backup_script = var.backup != null ? templatefile("${path.module}/templates/files/borg-backup.sh.tftpl", {
      notify_email = var.server_info_mail_to
    }) : ""

    borg_helper_script = var.backup != null ? templatefile("${path.module}/templates/files/borg.sh.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
      storagebox_user = hcloud_storage_box_subaccount.backup[0].username
      storagebox_path = "./db"
      borg_passphrase = random_password.db_borg_passphrase[0].result
    }) : ""

    backup_ssh_config = var.backup != null ? templatefile("${path.module}/templates/files/backup-ssh-config.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
    }) : ""

    backup_ssh_private_key = var.backup != null ? tls_private_key.db_backup[0].private_key_openssh : ""
    borg_passphrase        = var.backup != null ? random_password.db_borg_passphrase[0].result : ""
    storagebox_host        = var.backup != null ? hcloud_storage_box_subaccount.backup[0].server : ""
    storagebox_user        = var.backup != null ? hcloud_storage_box_subaccount.backup[0].username : ""
    storagebox_path        = "./db"
    storagebox_password    = var.backup != null ? hcloud_storage_box_subaccount.backup[0].password : ""
    backup_ssh_public_key  = var.backup != null ? chomp(tls_private_key.db_backup[0].public_key_openssh) : ""
  }) : ""
}
