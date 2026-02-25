# Hetzner Infrastructure

Multi-environment OpenTofu setup deploying single-server instances on Hetzner Cloud. Each environment gets its own server(s), floating IP, persistent volume, and GitHub deployment environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [tf.sh](#tfsh)
- [Adding New Environment Variables to existing Environments](#adding-new-environment-variables-to-existing-environments)
  - [Static Environment Variables](#static-environment-variables)
  - [External Secrets as Environment Variables](#external-secrets-as-environment-variables)
- [Accessing Generated Credentials and Values](#accessing-generated-credentials-and-values)
- [Providing Secrets](#providing-secrets)
  - [Shared Secrets for all environments](#shared-secrets-for-all-environments)
  - [Secrets Per-Environment](#secrets-per-environment)
- [Configuration](#configuration)
  - [Shared Configuration](#shared-configuration)
  - [Configuration Per-Environment](#configuration-per-environment)
    - [Dedicated Database Server (Optional)](#dedicated-database-server-optional)
    - [Delete Protection](#delete-protection)
- [Creating a New Environment](#creating-a-new-environment)
  - [Create the Environment Directory](#create-the-environment-directory)
  - [Setup Checklist](#setup-checklist)
  - [Deploying a New Environment](#deploying-a-new-environment)
- [Application Server Structure](#application-server-structure)
- [Backups (Borg + Hetzner StorageBox)](#backups-borg--hetzner-storagebox)
  - [Borg Helper Script](#borg-helper-script)
  - [Restoring from a Backup](#restoring-from-a-backup)
- [Server Replacement Safety](#server-replacement-safety)
- [Directory Structure](#directory-structure)

```
├── tf.sh                    # CLI wrapper
├── env.sh                   # Global secrets (gitignored)
└── terraform/
    ├── environments/
    │   ├── _shared/         # Symlinked into each environment
    │   ├── _example/        # Template for new environments
    │   ├── foobar/          # An active environment
    │   └── foobar/env.sh    # Environment specific secrets (gitignored)
    └── modules/
        └── hetzner-environment/  # Reusable environment module
```

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.10
- A secrets manager with CLI support

## Quick Start

```bash
# 1. Set up global secrets
cp env.sh.example env.sh
# Edit env.sh — wire up your secrets manager

# 2. Setup environment specific secrets
cp terraform/environments/foobar/env.sh.example terraform/environments/foobar/env.sh
# Edit environments/foobar/env.sh — wire up your secrets manager

# 3. Initialize the environment
./tf.sh foobar init

# You are done and can use the environment now:
./tf.sh foobar plan
./tf.sh foobar apply
```

## tf.sh

Wrapper around `tofu` that loads secrets and runs commands for a selected environment:

```bash
./tf.sh <environment> <command> [args...]
./tf.sh foobar plan
./tf.sh foobar apply -auto-approve
./tf.sh foobar output server_ip
```

It sources secrets in order: `env.sh` (global) then `terraform/environments/<env>/env.sh`
(overrides).

## Adding New Environment Variables to existing Environments

### Static Environment Variables

New static values, like port numbers and token TTLs can be added either in
`terraform/environments/_shared/global.tfvars` in `base_env_vars` for all environments or in
`terraform/environments/<env>/2_local.auto.tfvars` in `app_env_vars` for a specific environment.

### External Secrets as Environment Variables

If you need to pass API keys, login credentials or other secrets to your application, they need to
be provided through `env.sh`. For global secrets, use the root `env.sh`, for environment-specific
secrets, use the environment-specific `terraform/environments/<env>/env.sh`.

- Define a new `TF_VAR_<name>` in `env.sh.example` and in your local `env.sh`
- Define a new variable in `terraform/environments/_shared/variables.tf`
- Define a new Environment Variable in either `terraform/environments/_shared/global.tfvars` in
  `base_env_vars` for all environments or in `terraform/environments/<env>/2_local.auto.tfvars` in
  `app_env_vars` for a specific environment.

After `./tf.sh apply <env>`, the variable will be available after your next deployment via GitHub.

## Accessing Generated Credentials and Values

Avoid showing secrets in your terminal. Users of macOS can use `pbcopy` to copy the output to the
clipboard. Users of linux can use `xclip --clipboard --input` or `xsel -selection clipboard`
instead:

```bash
./tf.sh foobar output borg_passphrase | pbcopy
./tf.sh foobar output borg_passphrase | xclip --clipboard --input
./tf.sh foobar output borg_passphrase | xsel -selection clipboard
```

Traefik dashboard credentials are auto-generated per environment (username: `admin`):

```bash
./tf.sh foobar output traefik_dashboard_password
```

Dynamic SSH Port:

```bash
./tf.sh foobar output ssh_port
```

IP addresses:

```bash
./tf.sh foobar output server_ip
./tf.sh foobar output server_ip_v6
```

Borg backup passphrase:

```bash
./tf.sh foobar output borg_passphrase
```

Borg database backup passphrase, if enabled:

```bash
./tf.sh foobar output db_borg_passphrase
```

## Providing Secrets

### Shared Secrets for all environments

The root `env.sh` contains shared secrets across all environments. Must export:

| Variable                                      | Description                                                |
| --------------------------------------------- | ---------------------------------------------------------- |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | S3 backend credentials (Hetzner Object Storage)            |
| `TF_VAR_hcloud_token`                         | Hetzner Cloud API token for the used Hetzner Cloud project |
| `TF_VAR_github_token`                         | GitHub fine-grained PAT (see `env.sh.example`)             |
| `TF_VAR_smtp_user` / `TF_VAR_smtp_password`   | SMTP credentials                                           |

### Secrets Per-Environment

Each environment **must** override at minimum in `terraform/environments/<env-name>/env.sh`:

| Variable                             | Description                        |
| ------------------------------------ | ---------------------------------- |
| `STATE_PASSPHRASE` + `TF_ENCRYPTION` | Unique state encryption passphrase |

See `terraform/environments/_example/env.sh.example` for the template. If the environment has its
own Hetzner Cloud project or SMTP server, you can also override these at this level.

## Configuration

### Shared Configuration

Project-wide defaults are stored in `terraform/environments/_shared/global.tfvars`. For example,
server type, volume size, SSH keys, SMTP config, base app env vars. Symlinked as
`1_global.auto.tfvars` into each environment.

### Configuration Per-Environment

Environment-specific overrides are stored in
`terraform/environments/<env-name>/2_local.auto.tfvars`:

```hcl
domain           = "foobar.example.com"
environment_name = "foobar"
deploy_branch    = "foobar"

app_env_vars = {
  MAIL_FROM   = "info@foobar.example.com"
  ADMIN_EMAIL = "sysadmin@example.com"
}

# Optional: Borg backups to Hetzner StorageBox
backup = {
  storage_box_id = 123456  # Hetzner Storage Box ID — subaccount is created automatically
}
```

You could also override the `root_access_ssh_key_names` to narrow down SSH access to certain users
per environment.

#### Dedicated Database Server (Optional)

By default, PostgreSQL runs as a Docker service on the app server. For production environments, you
can optionally run PostgreSQL on a dedicated server that is only accessible via the internal
network.

Benefits:

- Database server can scale independently of the app server
- Database isolated from public-facing app server (reduced blast radius)
- Automatic backup when `backup` is set (shared StorageBox subaccount, separate borg repo)
- DB server has no public IP — only reachable via internal network (`10.0.1.20`)

```hcl
database = {
  server_type = "cx32"
  volume_size = 20
}
```

When `database` is set, the app server's `DB_HOST` is automatically overridden to `10.0.1.20`. SSH
to the DB server via the app server as jump host: `ssh -J deploy@<app-ip> deploy@10.0.1.20`.

DB backup is automatic when both `backup` and `database` are set — the DB server shares the same
StorageBox subaccount (separate borg repo at `./db`).

**Post-apply steps (when database is enabled):**

```bash
# 1. Verify PostgreSQL is running
ssh -J deploy@<app-ip> deploy@10.0.1.20 "docker compose ps"

# 2. Save DB borg passphrase for disaster recovery
./tf.sh prod output -raw db_borg_passphrase
```

#### Delete Protection

Each environment controls whether critical resources can be destroyed via `delete_protection`. This
sets both Hetzner's API-level `delete_protection` and OpenTofu's `prevent_destroy` lifecycle rule.

```hcl
delete_protection = {
  server      = true   # app server (also enables rebuild_protection)
  volume      = true   # persistent storage volume
  floating_ip = true   # IPv4 and IPv6 floating IPs
}
```

The variable has no default — every environment must explicitly set it. For production, enable all
protections. For staging/dev, keep them `false` so you can freely recreate resources.

## Creating a New Environment

### Create the Environment Directory

```bash
cd terraform/environments
cp -a _example <name>
```

Replace all `[REPLACE_ME]` placeholders in:

- [ ] backend.hcl (state storage endpoint, bucket, key)
- [ ] 2_local.auto.tfvars (domain, environment name, deploy branch, etc.)
- [ ] env.sh.example (rename to env.sh, fill in state passphrase)
- [ ] if necessary, customize the environment further

### Setup Checklist

- Do you need backups?
  - [ ] Have a StorageBox setup and ready in the same Hetzner Cloud project.
  - [ ] Enable backups in `2_local.auto.tfvars`.
- Do you need a dedicated database server, or is it okay to run the database on the app server?
  - [ ] Enable the database server in `2_local.auto.tfvars`.
- Do you know which users need SSH access to the app server?
  - [ ] Add the public keys manually to the Hetzner Cloud project if not existing yet.
  - [ ] Set `root_access_ssh_key_names` in `2_local.auto.tfvars`.

### Deploying a New Environment

```bash
# 1. Init, check and apply
./tf.sh foobar init
./tf.sh foobar plan
./tf.sh foobar apply

# 2. Create DNS records pointing to the floating IPs
./tf.sh foobar output server_ip      # → A record
./tf.sh foobar output server_ip_v6   # → AAAA record (use the ::1 address from the /64 block)

# IMPORTANT: Wait until DNS propagates before deploying your application, as Traefik needs to pull TLS certs.
```

## Application Server Structure

- Authorized developers login via their SSH keys as `root`
- User `deploy` can run Docker and can be accessed by user switching `su deploy`
- The Hetzner volume is mounted at `/mnt/storage`
- Docker Compose configuration and `.env` is deployed to `/mnt/storage/app`

## Backups (Borg + Hetzner StorageBox)

Setting the `backup` variable enables automated Borg backups of `/mnt/storage` (PostgreSQL, Docker
volumes, certs).

**Retention:** 48 hourly, 7 daily, 4 weekly, 6 monthly, 1 yearly. 

Runs every hour via cron. Emails on failure.

SSH key installation on the StorageBox happens automatically via cloud-init.

**After deploying the server for the first time, verify that backups are working:**

```bash
# 1. Login as root
ssh root@<foobar-ip> -p <foobar-ssh-port>
# 2. Execute the backup script
/opt/scripts/borg-backup.sh
# 3. Verify the logs show no errors
cat /var/log/borg-backup.log

# The output should look similar to this:
# === Backup started: Mon Feb 23 03:30:01 PM UTC 2026 ===
# === Backup finished: Mon Feb 23 03:30:03 PM UTC 2026 ===

# 4. Save the borg passphrase for disaster recovery
./tf.sh foobar output -raw borg_passphrase
```

Each environment gets its own StorageBox **subaccount** (created automatically), chrooted to
`<project>/<environment>/`. App backups go to `./app`, DB backups to `./db`.

### Borg Helper Script

Every server with backups enabled gets `/opt/scripts/borg.sh` — a wrapper that sets `BORG_REPO`,
`BORG_PASSPHRASE`, and `BORG_RSH`, then passes all arguments to `borg`. This avoids having to export
environment variables manually when interacting with borg:

```bash
# List all archives
sudo /opt/scripts/borg.sh list

# Show details of a specific archive
sudo /opt/scripts/borg.sh info ::archive-name

# Extract a file from an archive
sudo /opt/scripts/borg.sh extract ::archive-name path/to/file

# Any borg command works
sudo /opt/scripts/borg.sh <command> [args...]
```

The automated backup script (`borg-backup.sh`) and the cloud-init `borg init` both use this helper
internally.

### Restoring from a Backup

Backups only cover `/mnt/storage` (application data, compose files, database volumes). Docker images
live on the server's local disk and are not affected by a restore — no need to re-pull them.

```bash
# 1. SSH into the server as root
ssh root@<foobar-ip> -p <foobar-ssh-port>

# 2. List available archives to find the one you want
/opt/scripts/borg.sh list

# 3. Optional: Inspect an archive to see what it contains
/opt/scripts/borg.sh list ::<archive-name>

# 4. Stop the running application
su - deploy -c "cd /mnt/storage/app && docker compose down"

# 5. Optional: Create a backup of the current state before restoring, if not done before (via deployment etc.)
/opt/scripts/borg-backup.sh

# 6. Restore — extract the archive over the existing data
cd / # <- THIS IS IMPORTANT! Because the path in the backup archive is absolute
/opt/scripts/borg.sh extract ::<archive-name>

# 7. Start the application again
su - deploy -c "cd /mnt/storage/app && docker compose up -d"
```

> **Note:** After server recreation (new server = empty disk), trigger a re-deployment from CI to
> pull fresh images.

To restore only specific files or directories (e.g., just the database volume):

```bash
cd /
/opt/scripts/borg.sh extract ::<archive-name> mnt/HC_Volume_<id>/db
```

Note: Paths inside borg archives are relative (no leading `/`). Since the backup resolves the
`/mnt/storage` symlink, paths use the actual volume mount `mnt/HC_Volume_<id>/`. Use
`/opt/scripts/borg.sh list ::<archive-name>` to see the exact paths.

**If the database server is separate**, restore it the same way via the app server as jump host:

```bash
# Connect directly to the database server
ssh -J deploy@<app-ip> root@10.0.1.20

# On the database server:
su - deploy -c "docker compose down"
/opt/scripts/borg-backup.sh
cd /
/opt/scripts/borg.sh extract ::<archive-name>
su - deploy -c "docker compose up -d"
```

## Server Replacement Safety

When changing `server_type` or `location`, the module protects against data corruption and
misconfiguration:

- **Precondition check:** Before destroying the existing server, OpenTofu verifies that the
  requested server type is available and not deprecated at the target location. This catches
  misconfigurations early without touching the existing server.
- **Destroy-then-create (default):** The old server is fully stopped before the volume is detached
  and reattached to the new server. This avoids data corruption from in-flight Docker writes during
  a volume swap. There is a brief downtime window, but server type changes are rare and planned.

On boot, Docker Compose services restart automatically via `restart: always` in the production
compose files, if a deployment has happened before. If the server been replaced, you need to
manually deploy the application again, so it can pull the necessary Docker images.

## Directory Structure

```
├── tf.sh                    # CLI wrapper
├── env.sh                   # Global secrets (gitignored)
└── terraform/
    ├── environments/
    │   ├── _shared/         # Symlinked into each environment
    │   ├── _example/        # Template for new environments
    │   └── foobar/          # An active environment
    └── modules/
        └── hetzner-environment/  # Reusable environment module
```
