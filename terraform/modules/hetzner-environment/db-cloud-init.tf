locals {
  db_cloud_init = var.database != null ? templatefile("${path.module}/templates/db-cloud-init.yml.tftpl", {
    generated_public_key  = tls_private_key.app_deploy_user.public_key_openssh
    ops_public_key        = tls_private_key.ops_user.public_key_openssh
    admin_ssh_public_keys = var.admin_ssh_public_keys

    sshd_hardening_config = templatefile("${path.module}/templates/files/sshd-hardening.conf.tftpl", {
      ssh_port             = 22
      allow_tcp_forwarding = "no"
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

    docker_compose_config = templatefile("${path.module}/templates/files/db-docker-compose.yml.tftpl", {
      db_user      = var.app_env_vars["DB_USER"]
      db_password  = var.app_env_vars["DB_PASSWORD"]
      db_name      = var.app_env_vars["DB_NAME"]
      db_listen_ip = local.internal_ips.database
    })

    backup_enabled = var.backup != null

    borg_backup_script = var.backup != null ? templatefile("${path.module}/templates/files/borg-backup.sh.tftpl", {
      notify_email = var.server_info_mail_to
    }) : ""

    borg_helper_script = var.backup != null ? file("${path.module}/templates/files/borg.sh.tftpl") : ""

    borg_restore_script = var.backup != null ? file("${path.module}/templates/files/borg-restore.sh.tftpl") : ""

    pg_dump_script = var.backup != null ? file("${path.module}/templates/files/pg-dump.sh.tftpl") : ""
    
    pg_restore_script = var.backup != null ? file("${path.module}/templates/files/pg-restore.sh.tftpl") : ""

    finish_provisioning_script = templatefile("${path.module}/templates/files/finish-provisioning.sh.tftpl", {
      database_ip = ""
    })
  }) : ""
}
