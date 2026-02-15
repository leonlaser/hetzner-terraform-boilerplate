terraform {
  required_version = ">= 1.10"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  # TODO: Replace bucket name with your project's S3 bucket
  backend "s3" {
    bucket                      = "myapp-demo"
    key                         = "terraform.tfstate"
    region                      = "eu-central"
    endpoint                    = "https://your.storage.example"
    use_lockfile                = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
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

  project_name  = var.project_name
  environment   = "demo"
  deploy_branch = "demo"

  server_type = var.server_type
  volume_size = var.volume_size

  domain                      = var.domain
  github_repository           = var.github_repository
  docker_registry             = var.docker_registry
  ssh_key_ids                 = local.ssh_key_ids
  location                    = var.location
  smtp_host                   = var.smtp_host
  smtp_port                   = var.smtp_port
  smtp_from                   = var.smtp_from
  smtp_user                   = var.smtp_user
  smtp_password               = var.smtp_password
  unattended_upgrades_mail_to = var.unattended_upgrades_mail_to
  acme_mail                   = var.acme_mail
  traefik_dashboard_users     = var.traefik_dashboard_users
  app_env_vars                = var.app_env_vars
}

output "server_ip" {
  value = module.environment.server_ip
}

output "environment" {
  value = module.environment.environment
}
