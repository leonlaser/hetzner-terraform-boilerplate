locals {
  cloud_init = templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
    generated_public_key = tls_private_key.app_deploy_user.public_key_openssh
    volume_id            = hcloud_volume.app.id
    ssh_port             = random_integer.app_ssh_port.result

    netplan_config = templatefile("${path.module}/templates/files/60-floating-ip.yaml.tftpl", {
      floating_ip    = hcloud_floating_ip.master.ip_address
      floating_ip_v6 = hcloud_floating_ip.master_v6.ip_address
    })

    sshd_hardening_config = templatefile("${path.module}/templates/files/sshd-hardening.conf.tftpl", {
      ssh_port = random_integer.app_ssh_port.result
    })

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

    backup_enabled = var.backup != null

    borg_backup_script = var.backup != null ? templatefile("${path.module}/templates/files/borg-backup.sh.tftpl", {
      notify_email = var.server_info_mail_to
    }) : ""

    borg_helper_script = var.backup != null ? templatefile("${path.module}/templates/files/borg.sh.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
      storagebox_user = hcloud_storage_box_subaccount.backup[0].username
      storagebox_path = "./app"
      borg_passphrase = random_password.app_borg_passphrase[0].result
    }) : ""

    backup_ssh_config = var.backup != null ? templatefile("${path.module}/templates/files/backup-ssh-config.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
    }) : ""

    backup_ssh_private_key = var.backup != null ? tls_private_key.app_backup[0].private_key_openssh : ""
    borg_passphrase        = var.backup != null ? random_password.app_borg_passphrase[0].result : ""
    storagebox_host        = var.backup != null ? hcloud_storage_box_subaccount.backup[0].server : ""
    storagebox_user        = var.backup != null ? hcloud_storage_box_subaccount.backup[0].username : ""
    storagebox_path        = "./app"
    storagebox_password    = var.backup != null ? hcloud_storage_box_subaccount.backup[0].password : ""
    backup_ssh_public_key  = var.backup != null ? chomp(tls_private_key.app_backup[0].public_key_openssh) : ""

    pre_deploy_backup_script = var.backup != null ? templatefile("${path.module}/templates/files/pre-deploy-backup.sh.tftpl", {
      database_ip = var.database != null ? local.internal_ips.database : ""
    }) : ""

    swap_size = var.swap_size

    deploy_private_key = tls_private_key.app_deploy_user.private_key_openssh
    database_ip        = var.database != null ? local.internal_ips.database : ""
  })
}
