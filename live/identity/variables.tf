variable "name" {
  description = "The name of the project"
  type        = string
  default     = "meridian-payments-ltd"
}

variable "environment" {
  description = "The environment of the project"
  type        = string
  default     = "identity"
}

variable "session_duration" {
  description = "Default session length for permission sets (ISO 8601)"
  type        = string
  default     = "PT1H"
}

variable "account_owner_email" {
  description = "Email of the non-person user set as SSOUserEmail on every AFT-vended account"
  type        = string
  default     = "diamondnicholas179+aws-owner@gmail.com"
}
