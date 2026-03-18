locals {
  cloud_init = templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
    ops_public_key        = tls_private_key.ops_user.public_key_openssh
    ops_ssh_public_keys = var.ops_ssh_public_keys

    additional_users = var.cloud_init_users

    ssh_port                 = var.server_ssh_port
    swap_size                = var.server_swap_size
    backup_enabled           = var.backup_enabled
    backup_paths             = var.backup_paths
    server_ufw_allowed_ports = var.server_ufw_allowed_ports
    server_info_mail_to      = var.server_info_mail_to
    disk_threshold           = var.disk_threshold

    appended_runcmd = var.cloud_init_runcmd

    netplan_config = var.floating_ips_enabled ? templatefile("${path.module}/templates/files/60-floating-ip.yaml.tftpl", {
      floating_ip    = hcloud_floating_ip.server_ipv4[0].ip_address
      floating_ip_v6 = hcloud_floating_ip.server_ipv6[0].ip_address
    }) : ""

    ops_ssh_config = templatefile("${path.module}/templates/files/ops-ssh-config.tftpl", {
      storagebox_host = var.backup_enabled ? hcloud_storage_box_subaccount.backup[0].server : ""
    })

    sshd_hardening_config = templatefile("${path.module}/templates/files/sshd-hardening.conf.tftpl", {
      ssh_port             = var.server_ssh_port
      allow_tcp_forwarding = var.server_allow_tcp_forwarding
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
  })
}
