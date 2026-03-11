# ---------------------------------------------------------------------------
# Context
# ---------------------------------------------------------------------------
# The context the server is created in. The project name and environment name
# are used to prefix resource names. 
#
# project_name: myapp
# environment_name: staging
# server_name: database
#
# Resource name would become myapp-staging-database
#
variable "project_name" {
  type        = string
  description = "Short project identifier used for naming resources (e.g. 'myapp')"
}

variable "environment_name" {
  type        = string
  description = "Environment name (e.g. 'prod', 'stage', 'demo')"
}
