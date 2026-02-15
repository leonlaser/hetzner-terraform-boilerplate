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
  # Base environment variables common to all projects
  base_env_vars = {
    NODE_ENV = "production"

    # Let's Encrypt / ACME
    ACME_MAIL        = var.acme_mail
    ACME_STORAGE_DIR = "/mnt/storage/var/docker/letsencrypt"

    # Application
    APP_DOMAIN = var.domain

    # Database (PostgreSQL)
    DB_HOST     = "database"
    DB_PORT     = "5432"
    DB_NAME     = var.project_name
    DB_USER     = var.project_name
    DB_PASSWORD = random_password.db.result
    DB_VOLUME   = "/mnt/storage/var/docker/postgresql"
    DATABASE_URL = "postgres://${var.project_name}:${random_password.db.result}@database:5432/${var.project_name}"

    # Email / SMTP
    MAIL_DEFAULT_FROM           = var.smtp_from
    MAIL_HOST                   = var.smtp_host
    MAIL_PORT                   = tostring(var.smtp_port)
    MAIL_SECURE                 = "false"
    MAIL_USER                   = var.smtp_user
    MAIL_PASS                   = var.smtp_password
    MAIL_TLS_REJECT_UNAUTHORIZED = "true"
    MAIL_SERVERNAME             = var.smtp_host

    # Application secret (for JWT, sessions, etc.)
    APP_SECRET = random_password.app_secret.result

    # Traefik
    TRAEFIK_DASHBOARD_USERS = replace(var.traefik_dashboard_users, "$", "$$")
  }

  # Merge base vars with any app-specific overrides
  all_env_vars = merge(local.base_env_vars, var.app_env_vars)

  env_content = templatefile("${path.module}/templates/env.tftpl", {
    env_vars = local.all_env_vars
  })
}
