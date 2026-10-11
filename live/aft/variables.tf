variable "name" {
  description = "The name of the project"
  type        = string
  default     = "meridian-payments-ltd"
}

variable "environment" {
  description = "The environment of the project"
  type        = string
  default     = "aft"
}

variable "ct_home_region" {
  description = "Control Tower home region"
  type        = string
  default     = "eu-west-2"
}

variable "tf_backend_secondary_region" {
  description = "Region AFT replicates its Terraform state to"
  type        = string
  default     = "eu-west-1"
}

variable "ct_management_account_id" {
  description = "Control Tower management account ID"
  type        = string
  default     = "790013274466"
}

variable "log_archive_account_id" {
  description = "Log Archive account ID (created by Control Tower)"
  type        = string
  default     = "263953131739"
}

variable "audit_account_id" {
  description = "Audit account ID (created by Control Tower)"
  type        = string
  default     = "783495713938"
}

variable "aft_management_account_id" {
  description = "AFT management account ID"
  type        = string
  default     = "255291985306"
}

variable "github_org" {
  description = "GitHub org holding the AFT repos"
  type        = string
  default     = "Infra-bubble"
}
