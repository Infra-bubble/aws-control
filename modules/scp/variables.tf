variable "name" {
  description = "Name of the SCP"
  type        = string
}

variable "description" {
  description = "What the SCP prevents and why"
  type        = string
}

variable "content" {
  description = "SCP JSON document (max 10,240 characters)"
  type        = string
}

variable "target_ids" {
  description = "Where to attach the SCP: label => root, OU or account ID"
  type        = map(string)
}

variable "tags" {
  description = "Tags applied to the SCP"
  type        = map(string)
  default     = {}
}
