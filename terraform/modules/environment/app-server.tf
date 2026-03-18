module "app-server" {
  source = "../server"

  depends_on = [hcloud_network_subnet.environment, hcloud_firewall.app]

  project_name     = var.project_name
  environment_name = var.environment_name
  base_labels      = local.base_labels

  ops_ssh_public_keys = var.ops_ssh_public_keys

  server_name                 = "app"
  server_image_id             = data.hcloud_image.docker.id
  server_type                 = var.server_type
  server_location             = var.location
  server_protection           = var.delete_protection.server
  server_role                 = "app"
  server_ssh_port             = random_integer.app_ssh_port.result
  server_ufw_allowed_ports    = [80, 443]
  server_allow_tcp_forwarding = "yes"

  firewall_ids = [hcloud_firewall.app.id]

  floating_ips_enabled = true
  floating_ip_location = coalesce(var.floating_ip_location, var.location)
  floating_ip_protection = var.delete_protection.floating_ip

  private_network_enabled = true
  private_network_id      = hcloud_network.environment.id
  private_network_ip      = local.internal_ips.app

  backup_enabled        = var.backup != null
  backup_storage_box_id = var.backup != null ? var.backup.storage_box_id : 0
  backup_passphrase     = var.borg_passphrase
  backup_paths          = "/home/docker/current"

  smtp_host             = var.smtp_host
  smtp_port             = var.smtp_port
  smtp_user             = var.smtp_user
  smtp_password         = var.smtp_password
  server_info_mail_from = var.server_info_mail_from
  server_info_mail_to   = var.server_info_mail_to

  # Docker user exists in Packer image — cloud-init only injects the deploy SSH key
  cloud_init_users = [
    {
      name                = "docker",
      groups              = "users",
      ssh_authorized_keys = [tls_private_key.app_deploy_user.public_key_openssh]
    }
  ]

  # App-specific deploy-time setup
  cloud_init_runcmd = [
    # App directories
    "mkdir -p /home/docker/current/traefik /home/docker/current/letsencrypt",
    "chown -R docker:docker /home/docker/current",
    # Sudoers: docker user can run pre-deploy-backup as ops
    "printf 'docker ALL=(ops) NOPASSWD: /home/ops/scripts/pre-deploy-backup.sh\\n' > /etc/sudoers.d/app",
    "chmod 440 /etc/sudoers.d/app",
  ]

  ansible_playbooks = [
    {
      playbook = "${path.module}/ansible/app-server.yml"
      extra_vars = {
        swap_size   = tostring(var.swap_size)
        database_ip = var.database != null ? local.internal_ips.database : ""
      }
      file_hashes = [
        filesha256("${path.module}/ansible/files/pg-dump.sh"),
        filesha256("${path.module}/ansible/files/pg-restore.sh"),
      ]
    }
  ]
}