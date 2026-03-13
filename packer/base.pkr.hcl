packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
  default   = env("HCLOUD_TOKEN")
}

variable "location" {
  type    = string
  default = "hel1"
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "image_version" {
  type    = string
  default = ""
}

source "hcloud" "base" {
  token = var.hcloud_token

  location    = var.location
  image       = "ubuntu-24.04"
  server_type = var.server_type
  server_name = "packer-base-{{ timestamp }}"

  # Disable partition auto-grow for smaller snapshots
  user_data = <<-EOF
    #cloud-config
    growpart:
      mode: "off"
    resize_rootfs: false
  EOF

  ssh_username = "root"

  snapshot_name = "base-${var.image_version}"
  snapshot_labels = {
    role       = "base"
    os         = "ubuntu-24.04"
    managed-by = "packer"
    version    = var.image_version
  }
}

build {
  sources = ["source.hcloud.base"]

  # Wait for cloud-init to finish (handles user_data above)
  provisioner "shell" {
    inline           = ["cloud-init status --wait --long"]
    valid_exit_codes = [0, 2]
  }

  provisioner "shell" {
    scripts = [
      "${path.root}/scripts/base-setup.sh",
      "${path.root}/scripts/upgrade.sh",
      "${path.root}/scripts/cleanup.sh",
    ]
  }
}
