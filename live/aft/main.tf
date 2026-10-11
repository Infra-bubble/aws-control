module "aft" {
  source  = "aws-ia/control_tower_account_factory/aws"
  version = "1.22.0"

  ct_management_account_id    = var.ct_management_account_id
  log_archive_account_id      = var.log_archive_account_id
  audit_account_id            = var.audit_account_id
  aft_management_account_id   = var.aft_management_account_id
  ct_home_region              = var.ct_home_region
  tf_backend_secondary_region = var.tf_backend_secondary_region

  vcs_provider                                  = "github"
  account_request_repo_name                     = "${var.github_org}/aft-account-request"
  global_customizations_repo_name               = "${var.github_org}/aft-global-customizations"
  account_customizations_repo_name              = "${var.github_org}/aft-account-customizations"
  account_provisioning_customizations_repo_name = "${var.github_org}/aft-account-provisioning-customizations"

  terraform_distribution = "oss"

  # No AFT VPC: avoids NAT gateway / VPC endpoint costs; CodeBuild and Lambda run without a VPC
  aft_enable_vpc    = false
  aft_vpc_endpoints = false

  aft_feature_delete_default_vpcs_enabled = true
  aft_metrics_reporting                   = false

  tags = local.tags
}
