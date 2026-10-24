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

  # Controls register: optional Control Tower controls and the mechanism that implements each.
  # ARNs and mechanisms come from the Control Catalog (aws controlcatalog get-control).
  controls = {
    restrict-root-user = {
      arn       = "arn:aws:controlcatalog:::control/5kvme4m5d2b4d7if2fs5yg2ui" # AWS-GR_RESTRICT_ROOT_USER
      behavior  = "PREVENTIVE"
      mechanism = "SCP"
      name      = "Disallow actions as a root user"
    }
    s3-public-read-detect = {
      arn       = "arn:aws:controlcatalog:::control/8sw3pbid15t9cbww8d2w2qwgf" # AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED
      behavior  = "DETECTIVE"
      mechanism = "AWS Config rule"
      name      = "Detect public read access to S3 buckets"
    }
    s3-block-public-access-proactive = {
      arn       = "arn:aws:controlcatalog:::control/8uk3vrotlr08jfb0cbxp5klbs" # CT.S3.PR.1
      behavior  = "PROACTIVE"
      mechanism = "CloudFormation hook"
      name      = "Require S3 buckets to have block public access configured"
    }
  }

  # OU name => controls from local.controls to enable on it.
  # Enabled on Sandbox first to test; add other OUs once verified.
  ou_controls = {
    Sandbox = ["restrict-root-user", "s3-public-read-detect", "s3-block-public-access-proactive"]
  }
}