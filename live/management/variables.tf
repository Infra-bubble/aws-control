variable "name" {
  description = "The name of the project"
  type        = string
  default     = "meridian-payments-ltd"
}

variable "environment" {
  description = "The environment of the project"
  type        = string
  default     = "management"
}

variable "region" {
  description = "The AWS region for the project"
  type        = string
  default     = "eu-west-2"
}

variable "control_tower_baseline_arn" {
  description = "ARN of AWSControlTowerBaseline (aws controltower list-baselines)"
  type        = string
  default     = "arn:aws:controltower:eu-west-2::baseline/17BSJV3IGJ2QSGA2"
}

variable "identity_center_enabled_baseline_arn" {
  description = "ARN of the enabled IdentityCenterBaseline (aws controltower list-enabled-baselines)"
  type        = string
  default     = "arn:aws:controltower:eu-west-2:790013274466:enabledbaseline/XANFAQVK8ZI6Z05KV"
}
