module "db-server" {
  count  = var.database != null ? 1 : 0
  source = "../server"

  depends_on = [hcloud_network_subnet.environment, module.app-server]

  project_name     = var.project_name
  environment_name = var.environment_name
  base_labels      = local.base_labels

  ops_ssh_public_keys = [module.app-server.ops_public_key]

  server_name       = "db"
  server_image_id   = data.hcloud_image.docker.id
  server_type       = var.database.server_type
  server_location   = var.location
  server_protection = var.delete_protection.server
  server_role       = "database"
  server_ssh_port          = 22
  server_ufw_allowed_ports = [5432]

  firewall_ids = [hcloud_firewall.database[0].id]

  floating_ips_enabled    = false
  private_network_enabled = true
  private_network_id      = hcloud_network.environment.id
  private_network_ip      = local.internal_ips.database

  # Bastion through app server
  ansible_host                     = local.internal_ips.database
  ansible_bastion_host             = module.app-server.server_ipv4
  ansible_bastion_port             = random_integer.app_ssh_port.result
  ansible_bastion_private_key_file = module.app-server.ansible_ssh_key_file

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

  cloud_init_runcmd = [
    "mkdir -p /home/docker/current",
    "chown docker:docker /home/docker/current",
  ]

  ansible_playbooks = [
    {
      playbook = "${path.module}/ansible/db-server.yml"
      extra_vars = {
        docker_compose_content = templatefile("${path.module}/templates/files/db-docker-compose.yml.tftpl", {
          db_user      = var.app_env_vars["DB_USER"]
          db_password  = var.app_env_vars["DB_PASSWORD"]
          db_name      = var.app_env_vars["DB_NAME"]
          db_listen_ip = local.internal_ips.database
        })
      }
    }
  ]
}
