locals {
  resource_prefix = "${var.name}-${var.environment}"
  tags = {
    Project     = var.name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Path        = "aws-control/live/aft"
  }
}
