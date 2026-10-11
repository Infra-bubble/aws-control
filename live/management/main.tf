data "aws_organizations_organization" "this" {}

module "top_level_ous" {
  source   = "../../modules/ous"
  for_each = toset(local.top_level_ous)

  name                                 = each.key
  parent_id                            = local.root_id
  baseline_identifier                  = var.control_tower_baseline_arn
  identity_center_enabled_baseline_arn = var.identity_center_enabled_baseline_arn
  tags                                 = local.tags
}

module "workloads_child_ous" {
  source   = "../../modules/ous"
  for_each = toset(local.workloads_child_ous)

  name                                 = each.key
  parent_id                            = module.top_level_ous["Workloads"].id
  baseline_identifier                  = var.control_tower_baseline_arn
  identity_center_enabled_baseline_arn = var.identity_center_enabled_baseline_arn
  tags                                 = local.tags

  # Control Tower requires the parent OU to be registered first
  depends_on = [module.top_level_ous]
}
