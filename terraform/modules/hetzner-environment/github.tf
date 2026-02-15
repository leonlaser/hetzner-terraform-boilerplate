resource "github_repository_environment" "default" {
  repository  = var.github_repository
  environment = var.environment

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

resource "github_actions_environment_variable" "server_ip" {
  repository    = var.github_repository
  environment   = github_repository_environment.default.environment
  variable_name = "SERVER_IP"
  value         = hcloud_floating_ip.master.ip_address
}

resource "github_actions_environment_secret" "server_ssh_key" {
  repository      = var.github_repository
  environment     = github_repository_environment.default.environment
  secret_name     = "SERVER_SSH_PRIVATE_KEY"
  plaintext_value = tls_private_key.default.private_key_openssh

  lifecycle {
    ignore_changes = [remote_updated_at]
  }
}

resource "github_actions_environment_variable" "docker_registry" {
  environment   = github_repository_environment.default.environment
  repository    = var.github_repository
  variable_name = "DOCKER_REGISTRY"
  value         = var.docker_registry
}
