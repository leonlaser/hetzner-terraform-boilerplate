variable "ansible_playbooks" {
  description = "Additional Ansible playbooks to run after base provisioning"
  type = list(object({
    playbook   = string
    extra_vars = optional(map(string), {})
  }))
  default = []
}