data "aws_ssoadmin_instances" "this" {}

data "aws_organizations_organization" "this" {}

locals {
  instance_arn      = one(data.aws_ssoadmin_instances.this.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)
  root_id           = data.aws_organizations_organization.this.roots[0].id
}

# ---------------------------------------------------------------------------
# Lookups: OU names => IDs, account names => IDs
# ---------------------------------------------------------------------------

data "aws_organizations_organizational_units" "root" {
  parent_id = local.root_id
}

data "aws_organizations_organizational_units" "workloads" {
  parent_id = local.top_level_ou_ids["Workloads"]
}

locals {
  top_level_ou_ids = { for ou in data.aws_organizations_organizational_units.root.children : ou.name => ou.id }
  ou_ids = merge(
    local.top_level_ou_ids,
    { for ou in data.aws_organizations_organizational_units.workloads.children : ou.name => ou.id },
  )

  active_accounts = {
    for a in data.aws_organizations_organization.this.accounts : a.name => a.id if a.state == "ACTIVE"
  }
}

data "aws_organizations_organizational_unit_descendant_accounts" "this" {
  for_each  = toset(flatten(local.ou_assignments[*].ous))
  parent_id = local.ou_ids[each.key]
}

# ---------------------------------------------------------------------------
# Users and groups
# ---------------------------------------------------------------------------

data "aws_identitystore_user" "member" {
  for_each          = toset(flatten(values(local.group_members)))
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.key
    }
  }
}

# Non-person user set as SSOUserEmail on AFT-vended accounts. Nobody signs in as it;
# people get access through groups instead.
resource "aws_identitystore_user" "account_owner" {
  identity_store_id = local.identity_store_id
  user_name         = "aws-account-owner"
  display_name      = "AWS Account Owner"

  name {
    given_name  = "AWS"
    family_name = "Account Owner"
  }

  emails {
    value   = var.account_owner_email
    primary = true
  }
}

resource "aws_identitystore_group" "this" {
  for_each          = local.groups
  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = each.value
}

resource "aws_identitystore_group_membership" "this" {
  for_each = merge([
    for group, users in local.group_members : { for user in users : "${group}/${user}" => { group = group, user = user } }
  ]...)

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.this[each.value.group].group_id
  member_id         = data.aws_identitystore_user.member[each.value.user].user_id
}

# ---------------------------------------------------------------------------
# Permission sets
# ---------------------------------------------------------------------------

resource "aws_ssoadmin_permission_set" "this" {
  for_each         = local.permission_sets
  instance_arn     = local.instance_arn
  name             = each.key
  description      = each.value.description
  session_duration = var.session_duration
  tags             = local.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = merge([
    for ps, cfg in local.permission_sets : { for arn in cfg.managed_policies : "${ps}/${arn}" => { ps = ps, arn = arn } }
  ]...)

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.ps].arn
  managed_policy_arn = each.value.arn
}

# ---------------------------------------------------------------------------
# Account assignments: group + permission set + account
# ---------------------------------------------------------------------------

locals {
  assignment_list = concat(
    flatten([
      for a in local.ou_assignments : [
        for ou in a.ous : [
          for acct in data.aws_organizations_organizational_unit_descendant_accounts.this[ou].accounts : {
            group = a.group, permission_set = a.permission_set, account_name = acct.name, account_id = acct.id
          } if acct.state == "ACTIVE"
        ]
      ]
    ]),
    flatten([
      for a in local.account_assignments : [
        for name in a.accounts : {
          group = a.group, permission_set = a.permission_set, account_name = name, account_id = local.active_accounts[name]
        } if contains(keys(local.active_accounts), name)
      ]
    ]),
  )

  # Keyed group/permission-set/account; duplicates (OU + account rules) collapse to one
  assignments = {
    for k, v in { for a in local.assignment_list : "${a.group}/${a.permission_set}/${a.account_name}" => a... } : k => v[0]
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.assignments

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
  principal_type     = "GROUP"
  principal_id       = aws_identitystore_group.this[each.value.group].group_id
  target_type        = "AWS_ACCOUNT"
  target_id          = each.value.account_id

  # A permission set's policies must be attached before it is provisioned to an account
  depends_on = [aws_ssoadmin_managed_policy_attachment.this]
}
