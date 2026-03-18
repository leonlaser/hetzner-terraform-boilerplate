locals {
  # Infrastructure-only environment variables (Traefik, ACME, domain) are directly defined here.
  # Application-specific vars (DB, SMTP, secrets, etc.) belong in base_env_vars and app_env_vars.
  base_env_vars = {
    APP_DOMAIN              = var.domain
    ACME_MAIL               = var.acme_mail
    ACME_STORAGE_DIR        = "/home/docker/current/letsencrypt"
    TRAEFIK_DASHBOARD_USERS = terraform_data.app_traefik_dashboard_htpasswd.output
  }

  # When a dedicated database server is used, override DB_HOST to its internal IP.
  #
  # This is the only exception where we overwrite an app specific .env variable in the generic module.
  # Doing this in the environment calling the module (stage, prod), would require using a separate
  # module to define the database. This would lead to unnecessary complexity.
  db_env_overrides = var.database != null ? {
    DB_HOST = local.internal_ips.database
  } : {}

  # Merge base vars with any app-specific overrides
  all_env_vars = merge(local.base_env_vars, var.app_env_vars, local.db_env_overrides)

  env_content = templatefile("${path.module}/templates/env.tftpl", {
    env_vars = local.all_env_vars
  })
}
