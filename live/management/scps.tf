# Custom SCPs (written here, not managed by Control Tower).
# Each one uses a slot of the target's 10-SCP limit.

# Platform automation keeps working: Control Tower and AFT run as these roles
locals {
  scp_exempt_role_arns = [
    "arn:aws:iam::*:role/AWSControlTowerExecution",
    "arn:aws:iam::*:role/AWSAFTExecution",
  ]
}

data "aws_iam_policy_document" "deny_s3_create_bucket" {
  statement {
    sid       = "DenyS3CreateBucket"
    effect    = "Deny"
    actions   = ["s3:CreateBucket"]
    resources = ["*"]

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = local.scp_exempt_role_arns
    }
  }
}

module "scp_prod_deny_s3_create_bucket" {
  source = "../../modules/scp"

  name        = "scp-prod-deny-s3-create-bucket"
  description = "Prevents creating S3 buckets in Prod accounts, except by Control Tower and AFT roles"
  content     = data.aws_iam_policy_document.deny_s3_create_bucket.minified_json
  target_ids  = { Prod = module.workloads_child_ous["Prod"].id }
  tags        = local.tags
}
