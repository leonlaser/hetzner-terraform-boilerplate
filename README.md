# Hetzner Terraform Template

A template for Terraform and GitHub Actions CI for provisioning a Docker-ready Hetzner Cloud server with multi-environment support (production,
staging, demo), with a Docker Compose stack deployed via SSH.

> This is not a production-ready template. It's meant as a reference and starting point.

## Setup

- **Hetzner Cloud server** (Ubuntu 24.04) with floating IP and block storage volume
- **Rootless Docker** setup with Docker Compose
- **Security hardening**: SSH hardening, fail2ban, UFW firewall, unattended security upgrades
- **SMTP notifications** for reboot-required alerts and unattended-upgrades reports
- **Traefik-ready** with Let's Encrypt ACME support and dashboard auth
- **GitHub Actions** CI/CD pipeline with Docker build, push, and SSH-based deployment
- **GitHub Environments** auto-provisioned with branch protection policies and deployment secrets
- **Multi-environment**: production (`main`), staging (`develop`), demo (`demo`)

You can customize the terraform `hetzner-environment` module, to create your own custom environment.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.10 (required for ephemeral variables)
- A [Hetzner Cloud](https://www.hetzner.com/cloud) project with an API token
- An S3-compatible backend for Terraform state (e.g. Hetzner Object Storage, MinIO)
- A [GitHub fine-grained PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) with permissions: administration (r/w), variables (r/w), actions (r), environments (r/w), secrets (r/w)
- A GitHub Repository
- SSH key(s) uploaded to your Hetzner project
- DNS pointing your domain to the server's floating IP (after first apply)

## Using the template

### 1. Copy files to your own project

```bash
cp -r terraform/ $YOUR_PROJECT_DIR/terraform/
cp -r .github/ $YOUR_PROJECT_DIR/.github/
cp tf.sh $YOUR_PROJECT_DIR/
cp populate-env.sh.example $YOUR_PROJECT_DIR/populate-env.sh
cd $YOUR_PROJECT_DIR
chmod +x populate-env.sh
cd terraform/environments
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

### 2. Configure secrets and variables

Modify the example files you copied in step 1:

- Modify `populate-env.sh`, so all necessary secrets are available when executing `tf.sh`.
- Modify `terraform.tfvars` and store configuration here which will be applied to all environments.
- Optional: Create `<env>/terraform.tfvars` and override values which are specific to that environment.

### 3. Configure S3 backend

Edit `backend.hcl` to match your S3 endpoint and other configuration. Do not store any credentials in this file. Use `populate-env.sh` to populate environment variables with credentials from your secrets manager.

Edit `main.tf` of each environment, and set the bucket name of the S3 bucket you created.

```hcl
backend "s3" {
  bucket = "yourproject-production"  # <-- change this
  #...
}
```

### 4. Initialize and apply using `tf.sh`

`tf.sh` allows you to select the environment you want to setup or modify, and will apply global and environment-specific variables.

```bash
./tf.sh staging init
./tf.sh staging plan
./tf.sh staging apply
```

### 5. Point DNS

After `terraform apply`, note the `server_ip` output and create the A record for that domain.

## Project Structure

```
tf.sh                         # Terraform wrapper (sources secrets, selects env)
populate-env.sh.example       # Template for secrets population script

terraform/
├── environments/
│   ├── backend.hcl.example      # S3 backend credentials template
│   ├── terraform.tfvars.example # Global environment variables template
│   ├── _shared/                 # Shared variable definitions
│   │   ├── variables.tf
│   │   ├── ssh_keys.tf
│   ├── demo/
│   │   └── main.tf              # Demo: deploys from 'demo' branch
│   ├── staging/
│   │   └── main.tf              # Staging: deploys from 'develop' branch
│   └── production/
│       └── main.tf              # Production: deploys from 'main' branch
└── modules/
    └── hetzner-environment/  # Reusable infrastructure module
        ├── main.tf           # Provider requirements
        ├── variables.tf      # Module inputs
        ├── outputs.tf        # Module outputs
        ├── server.tf         # Server, floating IP, volume
        ├── network.tf        # VPC, subnet, firewall
        ├── github.tf         # GitHub environment & secrets
        ├── deploy.tf         # .env file provisioning
        ├── generated.tf      # Auto-generated SSH keys
        └── templates/
            ├── cloud-init.yml.tftpl  # Server bootstrap
            └── env.tftpl             # .env file template

.github/workflows/
├── ci.yml      # Build, test, Docker push, deploy trigger
└── deploy.yml  # SSH-based deployment via Docker Compose
```

## Customization

As this is only a starting point, you should customize it to your own needs and reflect on the security measures you want and need.

### Application Environment Variables

The module deploys a `.env` file to `/home/deploy/.env` on the server. It contains a small set of infrastructure variables by default:

- `APP_DOMAIN`, `ACME_MAIL`, `ACME_STORAGE_DIR` — domain and Let's Encrypt config
- `TRAEFIK_DASHBOARD_USERS` — Traefik basic auth

All application-specific variables (database, SMTP, secrets, etc.) are defined via the `app_env_vars` map. Values in `app_env_vars` are merged with the base infra vars and can override them.

**Static vars** go in `terraform.tfvars`:

```hcl
app_env_vars = {
  NODE_ENV = "production"
  DB_HOST  = "database"
  DB_PORT  = "5432"
  DB_NAME  = "myapp"
  DB_USER  = "myapp"
}
```

**Generated secrets** (passwords, tokens) should be created at the environment level and merged in the environment's `main.tf`:

```hcl
resource "random_password" "db" {
  length  = 64
  special = false
}

resource "random_password" "app_secret" {
  length  = 64
  special = false
}

module "environment" {
  # ...

  # merge() combines tfvars-defined app vars with generated secrets.
  # Generated secrets override tfvars values if keys collide.
  app_env_vars = merge(var.app_env_vars, {
    DB_PASSWORD  = random_password.db.result
    DATABASE_URL = "postgres://${var.project_name}:${random_password.db.result}@database:5432/${var.project_name}"
    APP_SECRET   = random_password.app_secret.result
  })
}
```

### Managing secrets per container

For a single-server Docker Compose setup, a `.env` file on disk is a reasonable approach. If someone gains access to your server, they can reach any secret your running processes need — regardless of whether those secrets come from a file, an environment variable, or a mounted volume. The same applies at the container level: a compromised container exposes whatever secrets were passed to it.

The more useful question is not *where* secrets are stored, but *which* secrets each container actually needs. Reducing the blast radius matters more than the storage mechanism:

- **Your frontend container** does not need database credentials or SSH deployment keys.
- **Your backend container** does not need your hcloud token or GitHub token.
- **Your database container** does not need SMTP credentials.

Each container in a Docker Compose setup can select which variables it needs via the `environment:` directive. See [`compose.example.yaml`](compose.example.yaml) for an example with Traefik and an application service that selectively passes only the secrets each service requires.

**When to go further:** If you run multiple servers, need audit trails for secret access, or work in a compliance-heavy environment, consider a secrets manager like HashiCorp Vault, AWS Secrets Manager, or Infisical. These give you short-lived credentials, automatic rotation, and access logging — things a static `.env` file cannot provide. For a single-server setup like this template, that complexity is usually not worth the trade-off.

### CI/CD

Edit the `matrix` in `.github/workflows/ci.yml` to match your project's Dockerfiles:

```yaml
matrix:
  include:
    - image: frontend
      dockerfile: ./apps/frontend/Dockerfile
    - image: backend
      dockerfile: ./apps/backend/Dockerfile
```

### Build Steps

Replace the `build` job in `.github/workflows/ci.yml` with your project's build/test/lint commands.

### Compose Files

Update `.github/workflows/deploy.yml` to copy and use your project's docker compose files.

## Security Notes

- **Ephemeral provider tokens**: `hcloud_token` and `github_token` are marked `ephemeral = true`. They exist only in memory during a run and are never written to state. Other secrets like SMTP credentials and Traefik dashboard users are *not* ephemeral because they flow into resource attributes (the `.env` file deployed to the server). Terraform must track their values in state to react to changes.
- **SSH keys in state**: The auto-generated SSH key is stored in Terraform state. This is acceptable for ephemeral demo environments. For production/staging, create SSH keys manually and update them on your server and in GitHub's environment secrets.
- **Secrets management**: All secrets are populated via `populate-env.sh` (sourced by `tf.sh`), not stored in files. If you need more additional secrets, extend the variables in the `terraform/environments/_shared/variables.tf` and populate them in `populate-env.sh`.
- **This is not a production-ready template.** You need to customize it to your own needs to have a secure production environment.

## Ideas on how you can build upon this template for your own use

- Split `server.tf` into `frontend-server.tf`, `backend-server.tf` and `db-server.tf`. Disable the public network for the database server and connect backend and database via the existing private network.
- Automate creating DNS records for your app, by using the `hcloud_dns_record` resource and add hetzners nameservers to your domain.
- Use the INWX terraform provider to create DNS records for your app.
- Add a secret manager like Vault or AWS Secrets Manager to store secrets.