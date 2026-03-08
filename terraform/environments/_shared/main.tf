terraform {
  required_version = ">= 1.10"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.2"
    }
  }

  backend "s3" {
    use_lockfile                = true
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }

  encryption {
    key_provider "pbkdf2" "s3" {
      key_length    = 32
      iterations    = 600000
      salt_length   = 32
      hash_function = "sha512"
    }
    method "aes_gcm" "secure_method" {
      keys = key_provider.pbkdf2.s3
    }
    state {
      method = method.aes_gcm.secure_method
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

module "environment" {
  source = "../../modules/hetzner-environment"

  project_name     = var.project_name
  environment_name = var.environment_name
  deploy_branch    = var.deploy_branch

  server_type = var.server_type
  volume_size = var.volume_size

  domain                = var.domain
  github_repository     = var.github_repository
  docker_registry       = var.docker_registry
  admin_ssh_key_ids     = local.admin_ssh_key_ids
  admin_ssh_public_keys = local.admin_ssh_public_keys
  location              = var.location
  floating_ip_location  = var.floating_ip_location
  smtp_host             = var.smtp_host
  smtp_port             = var.smtp_port
  server_info_mail_from = var.server_info_mail_from
  smtp_user             = var.smtp_user
  smtp_password         = var.smtp_password
  server_info_mail_to   = var.server_info_mail_to
  acme_mail             = var.acme_mail
  delete_protection     = var.delete_protection
  swap_size             = var.swap_size
  backup                = var.backup
  borg_passphrase       = var.borg_passphrase
  database              = var.database
  app_env_vars = merge(
    local.dynamic_env_vars,
    var.base_env_vars,
    var.app_env_vars
  )
}

output "server_ip" {
  value = module.environment.server_ip
}

output "server_ip_v6" {
  value = module.environment.server_ip_v6
}

output "environment" {
  value = module.environment.environment
}

output "ssh_port" {
  value = module.environment.ssh_port
}

output "traefik_dashboard_password" {
  value     = module.environment.traefik_dashboard_password
  sensitive = true
}
