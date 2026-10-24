variable "name" {
  description = "Name of the organizational unit"
  type        = string
}

variable "parent_id" {
  description = "Org root ID (r-xxxx) or parent OU ID (ou-xxxx)"
  type        = string
}

variable "baseline_identifier" {
  description = "ARN of AWSControlTowerBaseline"
  type        = string
}

variable "baseline_version" {
  description = "AWSControlTowerBaseline version; 5.0 matches landing zone 4.0"
  type        = string
  default     = "5.0"
}

variable "identity_center_enabled_baseline_arn" {
  description = "ARN of the enabled IdentityCenterBaseline"
  type        = string
}

variable "controls" {
  description = "Optional Control Tower controls to enable on this OU: short name => control ARN"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the OU and its baseline"
  type        = map(string)
  default     = {}
}
