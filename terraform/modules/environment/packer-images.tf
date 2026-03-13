data "hcloud_image" "docker" {
  with_selector = "role=docker,managed-by=packer"
  most_recent   = true
  with_status   = ["available"]
}
