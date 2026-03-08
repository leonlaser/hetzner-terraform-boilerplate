locals {
  cloud_init = templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
    generated_public_key  = tls_private_key.app_deploy_user.public_key_openssh
    ops_public_key        = tls_private_key.ops_user.public_key_openssh
    admin_ssh_public_keys = var.admin_ssh_public_keys
    
    ssh_port       = random_integer.app_ssh_port.result
    volume_id      = hcloud_volume.app.id
    swap_size      = var.swap_size
    has_database   = var.database != null
    backup_enabled = var.backup != null

    netplan_config = templatefile("${path.module}/templates/files/60-floating-ip.yaml.tftpl", {
      floating_ip    = hcloud_floating_ip.master.ip_address
      floating_ip_v6 = hcloud_floating_ip.master_v6.ip_address
    })

    sshd_hardening_config = templatefile("${path.module}/templates/files/sshd-hardening.conf.tftpl", {
      ssh_port             = random_integer.app_ssh_port.result
      allow_tcp_forwarding = var.database != null ? "yes" : "no"
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
    })

    check_reboot_script = templatefile("${path.module}/templates/files/check-reboot-required.sh.tftpl", {
      server_info_mail_to = var.server_info_mail_to
    })

    borg_backup_script = var.backup != null ? templatefile("${path.module}/templates/files/borg-backup.sh.tftpl", {
      notify_email = var.server_info_mail_to
    }) : ""

    borg_helper_script = var.backup != null ? file("${path.module}/templates/files/borg.sh.tftpl") : ""

    borg_restore_script = var.backup != null ? file("${path.module}/templates/files/borg-restore.sh.tftpl") : ""

    pg_dump_script = var.database == null && var.backup != null ? templatefile("${path.module}/templates/files/pg-dump.sh.tftpl", {
      compose_dir = "/mnt/storage/app"
    }) : ""

    pre_deploy_backup_script = var.backup != null ? templatefile("${path.module}/templates/files/pre-deploy-backup.sh.tftpl", {
      database_ip = var.database != null ? local.internal_ips.database : ""
    }) : ""

    finish_provisioning_script = templatefile("${path.module}/templates/files/finish-provisioning.sh.tftpl", {
      database_ip = var.database != null ? local.internal_ips.database : ""
    })
  })
}
