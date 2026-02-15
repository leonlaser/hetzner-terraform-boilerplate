# Hetzner Terraform Template

Terraform template for provisioning a Docker-ready Hetzner Cloud server with multi-environment support (production, staging, demo), automated GitHub Actions CI/CD, and security hardening out of the box.

## What You Get

- **Hetzner Cloud server** (Ubuntu 24.04) with floating IP and block storage volume
- **Rootless Docker** setup with Docker Compose
- **Security hardening**: SSH hardening, fail2ban, UFW firewall, unattended security upgrades
- **SMTP notifications** for reboot-required alerts and unattended-upgrades reports
- **Traefik-ready** with Let's Encrypt ACME support and dashboard auth
- **GitHub Actions** CI/CD pipeline with Docker build, push, and SSH-based deployment
- **GitHub Environments** auto-provisioned with branch protection policies and deployment secrets
- **Multi-environment**: production (`main`), staging (`develop`), demo (`demo`) branches

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.10 (required for ephemeral variables)
- A [Hetzner Cloud](https://www.hetzner.com/cloud) project with an API token
- An S3-compatible backend for Terraform state (e.g. Hetzner Object Storage, MinIO)
- A [GitHub fine-grained PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) with permissions: administration (r/w), variables (r/w), actions (r), environments (r/w), secrets (r/w)
- SSH key(s) uploaded to your Hetzner project
- DNS pointing your domain to the server's floating IP (after first apply)

## Quick Start

### 1. Copy the template

```bash
# Use this repository as a template, or clone it
cp -r terraform/ your-project/terraform/
cp -r .github/ your-project/.github/
```

### 2. Configure secrets

```bash
# Copy the example and wire it up to your secrets manager
cp populate-env.sh.example populate-env.sh
chmod +x populate-env.sh
$EDITOR populate-env.sh
```

Replace the empty values with calls to your secrets manager (1Password CLI, Bitwarden CLI, pass, etc.). See the comments in the example file for usage patterns. This file is gitignored.

### 3. Configure your project

```bash
cd terraform/environments/_shared

# Copy the example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
$EDITOR terraform.tfvars
```

Key values to set:
- `project_name` - short identifier (used for resource names, DB user/name)
- `github_owner` / `github_repository` - your GitHub repo
- `domain` - your domain name
- SMTP host, port, and sender address

### 4. Update S3 backend buckets

In each environment's `main.tf`, replace the `bucket` name:

```hcl
# terraform/environments/production/main.tf
backend "s3" {
  bucket = "yourproject-production"  # <-- change this
  ...
}
```

### 5. Configure S3 backend credentials

```bash
cd terraform/environments

# Copy the example and fill in your S3 credentials
cp backend.hcl.example backend.hcl
$EDITOR backend.hcl
```

> **Security**: Always use `backend.hcl` or environment variables (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) for backend credentials. Never pass them as CLI arguments — they leak into shell history.

### 6. Initialize and apply

```bash
# For each environment, create symlinks first:
cd terraform/environments/demo
ln -s ../_shared/variables.tf .
ln -s ../_shared/ssh_keys.tf .
ln -s ../_shared/terraform.tfvars .

# Then use tf.sh from the project root:
cd ../../..
./tf.sh demo init
./tf.sh demo plan
./tf.sh demo apply
```

### 7. Point DNS

After `terraform apply`, note the `server_ip` output and create an A record for your domain.

## Project Structure

```
tf.sh                         # Terraform wrapper (sources secrets, selects env)
populate-env.sh.example       # Template for secrets population script

terraform/
├── environments/
│   ├── backend.hcl.example   # S3 backend credentials template
│   ├── _shared/              # Shared variable definitions and config
│   │   ├── variables.tf
│   │   ├── ssh_keys.tf
│   │   └── terraform.tfvars.example
│   ├── demo/
│   │   └── main.tf           # Demo: deploys from 'demo' branch
│   ├── staging/
│   │   └── main.tf           # Staging: deploys from 'develop' branch
│   └── production/
│       └── main.tf           # Production: deploys from 'main' branch
└── modules/
    └── hetzner-environment/  # Reusable infrastructure module
        ├── main.tf           # Provider requirements
        ├── variables.tf      # Module inputs
        ├── outputs.tf        # Module outputs
        ├── server.tf         # Server, floating IP, volume
        ├── network.tf        # VPC, subnet, firewall
        ├── github.tf         # GitHub environment & secrets
        ├── deploy.tf         # .env file provisioning
        ├── generated.tf      # Auto-generated SSH keys & passwords
        └── templates/
            ├── cloud-init.yml.tftpl  # Server bootstrap
            └── env.tftpl             # .env file template

.github/workflows/
├── ci.yml                    # Build, test, Docker push, deploy trigger
└── deploy.yml                # SSH-based deployment via Docker Compose
```

## Customization

### Application Environment Variables

The module provides common env vars out of the box (database, SMTP, domain, Traefik, ACME, app secret). To add application-specific variables, use the `app_env_vars` map:

```hcl
# In terraform.tfvars
app_env_vars = {
  JWT_ACCESS_TOKEN_EXPIRES_IN  = "15m"
  JWT_REFRESH_TOKEN_EXPIRES_IN = "7d"
  PERSISTENCE                  = "prisma"
  SOME_API_KEY                 = "secret-value"
}
```

These are merged with the base env vars and deployed to `/home/deploy/.env` on the server.

### Docker Images

Edit the `matrix` in `.github/workflows/ci.yml` to match your project's Dockerfiles:

```yaml
matrix:
  include:
    - image: frontend
      dockerfile: ./apps/frontend/Dockerfile
    - image: backend
      dockerfile: ./apps/backend/Dockerfile
```

### Compose Files

Update `.github/workflows/deploy.yml` to copy and use your project's compose files.

### Build Steps

Replace the `build` job in `.github/workflows/ci.yml` with your project's build/test/lint commands.

## Security Notes

- **Ephemeral provider tokens**: `hcloud_token` and `github_token` are marked `ephemeral = true` (Terraform >= 1.10). They exist only in memory during a run and are never written to state. Other secrets like SMTP credentials and Traefik dashboard users are *not* ephemeral because they flow into resource attributes (the `.env` file deployed to the server) which Terraform must track in state.
- **SSH keys in state**: The auto-generated SSH key is stored in Terraform state. This is acceptable for ephemeral demo environments. For production/staging, create and deploy SSH keys manually.
- **Secrets management**: All secrets are populated via `populate-env.sh` (sourced by `tf.sh`), not stored in files. Copy `populate-env.sh.example` and wire it up to your secrets manager. Both `populate-env.sh` and `terraform.tfvars` are gitignored.
- The server runs rootless Docker, SSH is hardened (key-only, max 2 retries), fail2ban blocks brute-force attempts, and UFW restricts traffic to ports 22/80/443.
