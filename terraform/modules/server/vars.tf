variable "base_labels" {
  type        = map(any)
  default     = {}
  description = "Labels to assign to all resources created by this module"
}