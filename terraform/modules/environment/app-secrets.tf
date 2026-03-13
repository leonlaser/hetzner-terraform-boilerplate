resource "tls_private_key" "ops_user" {
  algorithm = "ED25519"
}

resource "tls_private_key" "app_deploy_user" {
  algorithm = "ED25519"
}

resource "random_integer" "app_ssh_port" {
  min = 49152
  max = 65535
}

resource "random_password" "app_traefik_dashboard" {
  length = 32
}

resource "terraform_data" "app_traefik_dashboard_htpasswd" {
  input = format("%s:%s", "admin", replace(bcrypt(random_password.app_traefik_dashboard.result), "$2a$", "$2y$"))

  lifecycle {
    ignore_changes       = [input]
    replace_triggered_by = [random_password.app_traefik_dashboard]
  }
}

resource "tls_private_key" "app_backup" {
  count     = var.backup != null ? 1 : 0
  algorithm = "ED25519"

  lifecycle {
    ignore_changes = all
  }
}
