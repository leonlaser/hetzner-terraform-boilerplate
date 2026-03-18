# -----------------------------------------------------------------------------
# Temporary SSH key file for Ansible to connect to the server
# -----------------------------------------------------------------------------
resource "local_sensitive_file" "ansible_ssh_key" {
  content         = tls_private_key.ops_user.private_key_openssh
  filename        = "${path.root}/.ansible-tmp/${var.server_name}-ops.key"
  file_permission = "0600"
}

locals {
  ansible_target = coalesce(var.ansible_host, hcloud_server.server.ipv4_address)

  ansible_ssh_common_args = var.ansible_bastion_host != null ? join(" ", [
    "-o StrictHostKeyChecking=no",
    "-o UserKnownHostsFile=/dev/null",
    "-o ProxyCommand=\"ssh -W %h:%p -p ${var.ansible_bastion_port} -i ${var.ansible_bastion_private_key_file} -o StrictHostKeyChecking=accept-new ${var.ansible_bastion_user}@${var.ansible_bastion_host}\"",
  ]) : "-o StrictHostKeyChecking=accept-new"

  # File hashes for change detection — triggers Ansible re-runs when scripts change
  provision_files_hash = sha256(join("", [
    filesha256("${path.module}/ansible/provision.yml"),
    filesha256("${path.module}/ansible/files/check-reboot-required.sh"),
    filesha256("${path.module}/ansible/files/check-disk-space.sh"),
    filesha256("${path.module}/ansible/files/docker-cleanup.sh"),
  ]))

  backup_files_hash = sha256(join("", [
    filesha256("${path.module}/ansible/backup.yml"),
    filesha256("${path.module}/ansible/files/backup.sh"),
    filesha256("${path.module}/ansible/files/restore.sh"),
    filesha256("${path.module}/ansible/files/borg.sh"),
  ]))

  additional_playbooks_hash = sha256(join("", flatten([
    for pb in var.ansible_playbooks : concat([filesha256(pb.playbook)], pb.file_hashes)
  ])))
}

# -----------------------------------------------------------------------------
# Change detection: trigger Ansible re-runs when playbook or script files change
# -----------------------------------------------------------------------------
resource "terraform_data" "provision_files_hash" {
  input = local.provision_files_hash
}

resource "terraform_data" "backup_files_hash" {
  count = var.backup_enabled ? 1 : 0
  input = local.backup_files_hash
}

resource "terraform_data" "additional_playbooks_hash" {
  count = length(var.ansible_playbooks) > 0 ? 1 : 0
  input = local.additional_playbooks_hash
}

# -----------------------------------------------------------------------------
# Base provisioning: cloud-init wait, SMTP password, ops internal key
# -----------------------------------------------------------------------------
resource "ansible_playbook" "provision" {
  playbook   = "${path.module}/ansible/provision.yml"
  name       = local.ansible_target
  replayable = false

  extra_vars = {
    ansible_user                 = "ops"
    ansible_port                 = tostring(var.server_ssh_port)
    ansible_ssh_private_key_file = local_sensitive_file.ansible_ssh_key.filename
    ansible_ssh_common_args      = local.ansible_ssh_common_args
    smtp_password                = var.smtp_password
    ops_internal_key             = tls_private_key.ops_user.private_key_openssh
  }

  depends_on = [
    hcloud_server.server,
    hcloud_floating_ip_assignment.server,
    hcloud_server_network.private,
  ]

  lifecycle {
    replace_triggered_by = [
      hcloud_server.server.id,
      terraform_data.provision_files_hash,
    ]
  }
}

# -----------------------------------------------------------------------------
# Additional playbooks (role-specific provisioning)
# -----------------------------------------------------------------------------
resource "ansible_playbook" "additional" {
  for_each = { for pb in var.ansible_playbooks : basename(pb.playbook) => pb }

  playbook   = each.value.playbook
  name       = local.ansible_target
  replayable = false

  extra_vars = merge({
    ansible_user                 = "ops"
    ansible_port                 = tostring(var.server_ssh_port)
    ansible_ssh_private_key_file = local_sensitive_file.ansible_ssh_key.filename
    ansible_ssh_common_args      = local.ansible_ssh_common_args
  }, each.value.extra_vars)

  depends_on = [ansible_playbook.provision]

  lifecycle {
    replace_triggered_by = [
      hcloud_server.server.id,
      terraform_data.additional_playbooks_hash,
    ]
  }
}

# -----------------------------------------------------------------------------
# Backup provisioning: borg env, backup key, StorageBox setup, borg init
# -----------------------------------------------------------------------------
resource "ansible_playbook" "backup" {
  count = var.backup_enabled ? 1 : 0

  playbook   = "${path.module}/ansible/backup.yml"
  name       = local.ansible_target
  replayable = false

  extra_vars = {
    ansible_user                 = "ops"
    ansible_port                 = tostring(var.server_ssh_port)
    ansible_ssh_private_key_file = local_sensitive_file.ansible_ssh_key.filename
    ansible_ssh_common_args      = local.ansible_ssh_common_args
    borg_env_content = templatefile("${path.module}/templates/files/borg-env.tftpl", {
      storagebox_host = hcloud_storage_box_subaccount.backup[0].server
      storagebox_user = hcloud_storage_box_subaccount.backup[0].username
      storagebox_path = "./borg"
      borg_passphrase = var.backup_passphrase
    })
    backup_private_key  = tls_private_key.backup[0].private_key_openssh
    backup_public_key   = tls_private_key.backup[0].public_key_openssh
    storagebox_host     = hcloud_storage_box_subaccount.backup[0].server
    storagebox_user     = hcloud_storage_box_subaccount.backup[0].username
    storagebox_password = hcloud_storage_box_subaccount.backup[0].password
  }

  depends_on = [ansible_playbook.provision, ansible_playbook.additional]

  lifecycle {
    replace_triggered_by = [
      hcloud_server.server.id,
      terraform_data.backup_files_hash,
    ]
  }
}
