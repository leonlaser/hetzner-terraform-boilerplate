# Hetzner Terraform Boilerplate

A boilerplate for deploying containerized applications on Hetzner Cloud with Docker. It is the result of extracting the most basic parts of multiple production environments.

The aim is to:

- document a way of bootstrapping and deploying infrastructure and applications
- provide some utility scripts to help backup and restore tasks
- keep the complexity as low as possible, so it can be understood more easily and adapted to your own needs

## Prerequisites

While the boilerplate should be adapted to your own needs, it is designed to be used with:

- [Hetzner Cloud](https://www.hetzner.com/cloud)
- [Hetzner S3](https://www.hetzner.com/de/storage/object-storage/) as a Terraform state storage
- [Hetzner StorageBox](https://www.hetzner.com/de/storage/storage-box/) for storing backups
- [GitHub](https://github.com/) for CI/CD
- Any SMTP E-Mail server for sending status emails
- [OpenTofu](https://opentofu.org/) as a drop-in replacement for `terraform` to make use local state encryption
- [Docker Compose](https://docs.docker.com/compose/) for configuring and running the application
- [PostgreSQL](https://www.postgresql.org/) as the application database
- [Borg](https://www.borgbackup.org/) for automated backups
- [Traefik](https://github.com/traefik/traefik) as a reverse proxy and for TLS termination
- Bash for executing the `tf.sh` and `env.sh` helper scripts

#### Disclaimer

While this boilerplate will set up and provision servers with some security aspects in mind, **it does not claim to give you a production-ready and fully hardened setup**.

The boilerplate **does not cover** topics like:

- Centralized logging
- Monitoring (besides rudimentary status emails for security updates)
- IDS/IPS (besides a very basic `fail2ban` SSH configuration)
- Advanced Firewalling (e.g. WAF, DDoS protection)
- Advanced Network security (e.g. mTLS, VPN)
- Performance tuning
- Supply chain security
- Hardening of the application itself

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
    - [PostgreSQL Backups (pg_dump)](#postgresql-backups-pg_dump)
    - [Restoring from a Backup](#restoring-from-a-backup)
    - [Disaster Recovery](#disaster-recovery)
- [Server Replacement Safety](#server-replacement-safety)
- [Directory Structure](#directory-structure)

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
  - [ ] Set `admin_ssh_key_names` in `2_local.auto.tfvars`.

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

## tf.sh

Wrapper around `tofu` that loads secrets and runs commands for a selected environment:

```bash
./tf.sh <environment> <command> [args...]
./tf.sh foobar plan
./tf.sh foobar apply
./tf.sh foobar output server_ip
```

## Providing Secrets

### Shared Secrets for all environments

The root `env.sh` contains shared secrets across all environments. Look at `env.sh.example` for the template and adjust which secrets are required for all environments.

The boilerplate assumes you will:

- deploy multiple environments to a single Hetzner Cloud project
- store your Terraform in a single Hetzner S3 bucket
- use the same Email server for all environments
- use the same GitHub PAT for alle environments

### Secrets Per-Environment

Each environment can override ar add environment variables defined in the root `env.sh` by setting those in `terraform/environments/<env-name>/env.sh`.

The boilerplate suggests defining at least `STATE_PASSPHRASE` / `TF_ENCRYPTION` per environment. By doing so, a leaked state passphrase for a staging environment cannot be used to gain access to production secrets.

## Configuration

### Shared Configuration

Project-wide defaults are stored in `terraform/environments/_shared/global.tfvars`. For example, server type, SSH keys, SMTP config, base app env vars. Symlinked as
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

All variables set in `terraform/environments/_shared/global.tfvars` can be overidden. For example to set a more cost-efficent `server_type` for a staging environment and a more performant `server_type` for a production environment.

#### Dedicated Database Server (Optional)

By default, PostgreSQL runs as a Docker service on the app server. For production environments, you can optionally run PostgreSQL on a dedicated server that is only accessible via the internal network.

Benefits:

- Database server can scale independently of the app server
- Database isolated from public-facing app server (reduced blast radius)
- Automatic backup when `backup` is set (shared StorageBox subaccount, separate borg repo)
- DB server has no public IP — only reachable via internal network (`10.0.1.20`)

```hcl
database = {
  server_type = "cx32"
}
```

When `database` is set, the app server's `DB_HOST` is automatically overridden to `10.0.1.20`. SSH to the DB server via the app server as jump host: `ssh -J ops@<app-ip>:<ssh-port> ops@10.0.1.20`.

DB backup is automatic when both `backup` and `database` are set — the DB server shares the same StorageBox subaccount (separate borg repo at `./db`).

**Post-apply steps (when database is enabled):**

```bash
ssh -J ops@<app-ip>:<ssh-port> ops@10.0.1.20 "cd /home/app/current && sudo -u app docker compose ps"
```

#### Delete Protection

Each environment controls whether critical resources can be destroyed via `delete_protection`. This sets both Hetzner's API-level `delete_protection` and OpenTofu's `prevent_destroy` lifecycle rule.

```hcl
delete_protection = {
  server = true        # app server (also enables rebuild_protection)
  floating_ip = true   # IPv4 and IPv6 floating IPs
}
```

The variable has no default — every environment must explicitly set it. For production, enable all protections. For staging/dev, keep them `false` so you can freely recreate resources.

## Adding New Environment Variables to existing Environments

### Static Environment Variables

New static values, like port numbers and token TTLs can be added either in
`terraform/environments/_shared/global.tfvars` in `base_env_vars` for all environments or in
`terraform/environments/<env>/2_local.auto.tfvars` in `app_env_vars` for a specific environment.

### External Secrets as Environment Variables

If you need to pass API keys, login credentials or other secrets to your application, they need to be provided through `env.sh`. For global secrets, use the root `env.sh`, for environment-specific secrets, use the environment-specific `terraform/environments/<env>/env.sh`.

- Define a new `TF_VAR_<name>` in `env.sh.example` and in your local `env.sh`
- Define a new variable in `terraform/environments/_shared/variables.tf`
- Define a new Environment Variable in either `terraform/environments/_shared/global.tfvars` in
  `base_env_vars` for all environments or in `terraform/environments/<env>/2_local.auto.tfvars` in
  `app_env_vars` for a specific environment.

After `./tf.sh apply <env>`, the variable will be available after your next deployment via GitHub.

## Accessing Generated Credentials and Values

Avoid showing secrets in your terminal. Users of macOS can use `pbcopy` to copy the output to the clipboard. Users of linux can use `xclip --clipboard --input` or `xsel -selection clipboard`
instead:

```bash
./tf.sh foobar output --raw borg_passphrase | pbcopy
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

## Application Server Structure

Three users with distinct roles:

| User       | Purpose                        | SSH access                       |
|------------|--------------------------------|----------------------------------|
| **ops**    | Admin SSH, backups, monitoring | Admin SSH keys (Hetzner project) |
| **app**    | Docker, app runtime            | Deploy key (CI/CD only)          |
| **root**   | System services only           | Disabled (`PermitRootLogin no`)  |

- Authorized developers login via their SSH keys as `ops`
- The `app` shell function (defined in `~/.bash_aliases`) runs commands as the `app` user from `/home/app/current`. For example: `app docker compose ps`. It is a shortcut for `cd /home/app/current && sudo -u app`.
- Secrets are **not** in cloud-init — they are pushed via Terraform provisioners after cloud-init completes
- Backups, monitoring scripts, and crontabs are owned by `ops` under `~/scripts/` and `~/logs/`
- Compose files, `.env`, traefik config, and letsencrypt certs live in `/home/app/current`
- Database data is stored separately at `/home/app/postgresql` (not backed up directly — `pg_dump` handles it)

## Backups (Borg + Hetzner StorageBox)

Setting the `backup` variable enables automated Borg backups of `/home/app/current`. When a PostgreSQL database is present (dedicated DB server or app-local), `pg_dump` runs automatically before Borg to create a consistent dump. Database data lives at `/home/app/postgresql` — outside the backup path, so only the dump is archived.

**Retention:** 48 hourly, 7 daily, 4 weekly, 6 monthly, 1 yearly.

Runs every hour via the `ops` user's crontab. Emails on failure.

SSH key installation on the StorageBox and borg repository initialization happen automatically via Terraform provisioners after cloud-init completes.

**After deploying the server for the first time, verify that backups are working:**

```bash
# 1. Login as ops
ssh ops@<foobar-ip> -p <foobar-ssh-port>
# 2. Execute the backup script
sudo ~/scripts/borg-backup.sh
# 3. Verify the logs show no errors
cat ~/logs/borg-backup.log

# The output should look similar to this:
# === Backup started: Mon Feb 23 03:30:01 PM UTC 2026 ===
# === Backup finished: Mon Feb 23 03:30:03 PM UTC 2026 ===

# 4. Save the borg passphrase for disaster recovery
./tf.sh foobar output -raw borg_passphrase
```

Each environment gets its own StorageBox **subaccount** (created automatically), chrooted to
`<project>/<environment>/`. App backups go to `./app`, DB backups to `./db`.

### Borg Helper Script

Every server with backups enabled gets `~/scripts/borg.sh` (owned by `ops`) — a wrapper that sets
`BORG_REPO`, `BORG_PASSPHRASE`, and `BORG_RSH`, then passes all arguments to `borg`. This avoids having to export environment variables manually when interacting with borg:

```bash
# Login as ops
ssh ops@<foobar-ip> -p <foobar-ssh-port>

# List all archives
~/scripts/borg.sh list

# Show details of a specific archive
~/scripts/borg.sh info ::archive-name

# Any borg command works
~/scripts/borg.sh <command> [args...]
```

The automated backup script (`borg-backup.sh`) and the provisioner's `borg init` both use this helper internally.

> **Note:** For extracting archives, use `sudo ~/scripts/borg-restore.sh` instead of `borg.sh extract`.
> The restore script runs as root via sudo, which is required to write to `app`-owned directories
> and to restore correct file ownership.

### PostgreSQL Backups (pg_dump)

When backups are enabled and a PostgreSQL database is present, a `pg-dump.sh` script is deployed alongside the Borg backup scripts. It runs automatically as a pre-backup hook. `borg-backup.sh`
checks for an executable `~/scripts/pg-dump.sh` and calls it before creating the archive.

**How it works:**

1. `pg-dump.sh` runs `pg_dump --format=directory` inside the database container
2. The dump is tar-streamed to `/home/ops/pgdump/` on local disk
3. Borg archives the dump directory (raw DB data at `/home/app/postgresql` is outside the backup path)
4. After Borg completes, the dump is cleaned up

The directory format creates one file per table, which helps borg to only back up changed tables.

**Your Docker Compose file must name the PostgreSQL service `database`** to match the boilerplate convention. 

**If `pg-dump.sh` fails** (database not running, disk full, etc.), the backup is aborted and an alert email is sent. This is intentional — a failed dump means no consistent backup is possible.

**Until the first CI/CD deployment, `pg-dump.sh` will fail**, when the database is on the same server (no running database service yet). The backup script will abort and send an alert email. This is expected and resolves after the first deployment.


### Restoring from a Backup

Backups cover `/home/app/current` (compose files, `.env`, traefik config, letsencrypt certs) plus `pg_dump` output
(if a database is present). Docker images are not included — re-pull them after a restore via CI/CD deployment.

#### How to restore a full backup

```bash
# 1. SSH into the server as ops
ssh ops@<foobar-ip> -p <foobar-ssh-port>

# 2. Pause automatic backups
touch ~/.backup-paused

# 3. List available archives to find the one you want
sudo ~/scripts/borg-restore.sh

# 4. Stop the running application
app docker compose down

# 5. Optional: Create a backup of the current state before restoring, if not done before (via deployment etc.)
sudo ~/scripts/borg-backup.sh

# 6. Extract the archive over the existing data - this will also extract the database dump to /home/ops/pgdump
sudo ~/scripts/borg-restore.sh <archive-name>

# 7. Either start and restore the database ...
app docker compose up -d database
~/scripts/pg-restore.sh

# ... or delete the extracted database dump
rm -rf /home/ops/pgdump

# 8. Start the application again
app docker compose up -d

# 9. Resume automatic backups
rm ~/.backup-paused
```

> **Note:** After server recreation (new server = empty disk), trigger a re-deployment from CI to pull the necessary docker images. The image tag you need to deploy for the restored backup is available in the restored `.env` file.

#### Restoring only specific files or directories

Use `~/scripts/borg.sh list ::<archive-name>` to see the exact paths, then extract only what you need:

```bash
sudo ~/scripts/borg-restore.sh <archive-name> home/app/current/letsencrypt
```

#### Restoring the PostgreSQL dump from a borg archive

The `pg_dump` output is stored at `home/ops/pgdump/` in the archive (relative path, on local disk). The following procedure applies for both dedicated DB servers and app servers with a local database.

```bash
# 1. List all available backups to select what want to restore
sudo ~/scripts/borg-restore.sh

# 2. Extract the pg_dump from the archive
#    If you already extracted the whole archive, you can skip this
sudo ~/scripts/borg-restore.sh <archive-name> home/ops/pgdump

# 3. Restore the whole database
~/scripts/pg-restore.sh
```

If you want to restore only specific tables, you can do the restore process manually:

```bash
# 1. List dumps and extract a dump from a backup archive
sudo ~/scripts/borg-restore.sh
sudo ~/scripts/borg-restore.sh <archive-name> home/ops/pgdump

# 2. Copy the database dump into the container and ...
app docker compose exec -T database bash -c 'rm -rf /tmp/pgdump && mkdir -p /tmp/pgdump'
tar cf - -C /home/ops/pgdump . | app docker compose exec -T database bash -c 'tar xf - -C /tmp/pgdump'

# 3. Restore a single table
app docker compose exec -T database pg_restore --list /tmp/pgdump | grep 'TABLE DATA'
app docker compose exec -T database bash -c 'pg_restore\
  --dbname="$POSTGRES_DB" --username="$POSTGRES_USER" \
  --table=<table-name> --clean \
  /tmp/pgdump'

# 4. Cleanup
rm -rf /home/ops/pgdump
app docker compose exec database rm -rf /tmp/pgdump
```

### Disaster Recovery

Full recovery procedure after server loss:

1. Provision new server(s): `./tf.sh <env> apply`
2. Wait for the setup to be done
3. Follow the [restore procedure](#how-to-restore-a-full-backup) but skip the final `app docker compose up -d`
4. Look up the deployed image tag in `.env` and deploy the image tag again via CI/CD

## Server Replacement Safety

When changing `server_type` or `location`, the module protects against data corruption and misconfiguration. Before destroying the existing server, OpenTofu verifies that the requested server type is available and not deprecated at the target location.

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
