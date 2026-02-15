resource "null_resource" "deploy_env" {
  triggers = {
    env_hash  = sha256(local.env_content)
    server_id = hcloud_server.app.id
  }

  depends_on = [hcloud_floating_ip_assignment.master]

  connection {
    type        = "ssh"
    user        = "deploy"
    host        = hcloud_floating_ip.master.ip_address
    private_key = tls_private_key.default.private_key_openssh
    timeout     = "2m"
  }

  provisioner "file" {
    content     = local.env_content
    destination = "/home/deploy/.env"
  }
}

locals {
  # Infrastructure-only environment variables (Traefik, ACME, domain).
  # Application-specific vars (DB, SMTP, secrets, etc.) belong in app_env_vars.
  base_env_vars = {
    APP_DOMAIN              = var.domain
    ACME_MAIL               = var.acme_mail
    ACME_STORAGE_DIR        = "/mnt/storage/var/docker/letsencrypt"
    TRAEFIK_DASHBOARD_USERS = replace(var.traefik_dashboard_users, "$", "$$")
  }

  # Merge base vars with any app-specific overrides
  all_env_vars = merge(local.base_env_vars, var.app_env_vars)

  env_content = templatefile("${path.module}/templates/env.tftpl", {
    env_vars = local.all_env_vars
  })
}
