locals {
    resource_prefix = "${var.name}-${var.environment}"
    tags = {
    Project     = var.name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Path        = "aws-control/live/management"
  }

  root_id             = data.aws_organizations_organization.this.roots[0].id
  top_level_ous       = ["Infrastructure", "Workloads", "Sandbox", "Policy-Staging", "Suspended", "AFT-Management"]
  workloads_child_ous = ["Prod", "NonProd"]
}