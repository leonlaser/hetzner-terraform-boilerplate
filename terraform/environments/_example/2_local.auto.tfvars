domain           = "[REPLACE_ME]"
environment_name = "[REPLACE_ME]"
deploy_branch    = "[REPLACE_ME]"

location = "fsn1"
# Optional: If you need to recreate server+volume in another region but want to keep the floating IP
# floating_ip_location = "fsn1

# Optional: Environment specific variables
# app_env_vars = {
#   ENVIRONMENT_SPECIFIC_VARIABLE = "Very specific"
# }

delete_protection = {
  server      = false
  volume      = false
  floating_ip = false
}

# Optional: Borg backups (null = Backups are disabled)
# backup = {
#   storage_box_id = 0 # Hetzner Storage Box ID
# }

# Optional: Dedicated database server (null = DB runs on app server)
# database = {
#   server_type = "cx32"
#   volume_size = 10
# }
