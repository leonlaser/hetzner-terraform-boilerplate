resource "github_repository_environment" "default" {
  repository  = var.github_repository
  environment = var.environment_name

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "branch" {
  repository     = var.github_repository
  environment    = github_repository_environment.default.environment
  branch_pattern = var.deploy_branch
}

resource "github_actions_environment_secret" "app_server_ip" {
  repository      = var.github_repository
  environment     = github_repository_environment.default.environment
  secret_name     = "APP_SERVER_IP"
  plaintext_value = module.app-server.server_ipv4
}

resource "github_actions_environment_secret" "app_server_ssh_port" {
  repository      = var.github_repository
  environment     = github_repository_environment.default.environment
  secret_name     = "APP_SERVER_SSH_PORT"
  plaintext_value = random_integer.app_ssh_port.result
}

resource "github_actions_environment_secret" "app_ssh_deploy_private_key" {
  repository      = var.github_repository
  environment     = github_repository_environment.default.environment
  secret_name     = "APP_DEPLOY_SSH_PRIVATE_KEY"
  plaintext_value = tls_private_key.app_deploy_user.private_key_openssh
}

resource "github_actions_environment_variable" "docker_registry" {
  repository    = var.github_repository
  environment   = github_repository_environment.default.environment
  variable_name = "DOCKER_REGISTRY"
  value         = var.docker_registry
}

resource "github_actions_environment_variable" "deploy_database_with_app" {
  repository    = var.github_repository
  environment   = github_repository_environment.default.environment
  variable_name = "DEPLOY_DATABASE_WITH_APP"
  value         = var.database == null ? "true" : "false"
}

resource "github_actions_environment_variable" "backup_enabled" {
  repository    = var.github_repository
  environment   = github_repository_environment.default.environment
  variable_name = "BACKUP_ENABLED"
  value         = var.backup != null ? "true" : "false"
}

resource "github_actions_environment_secret" "app_env" {
  repository      = var.github_repository
  environment     = github_repository_environment.default.environment
  secret_name     = "APP_ENV"
  plaintext_value = local.env_content
}
