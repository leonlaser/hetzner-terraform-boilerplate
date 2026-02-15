# As this resource will be saved in the Terraform state, it
# should only be used for automatically generated, short lived environments.
# Production and staging environments, the private keys should be
# created and deployed manually.
resource "tls_private_key" "default" {
  algorithm = "ED25519"
}
