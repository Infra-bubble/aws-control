# Adopts the Identity Center resources created in the console before this
# module existed, so Terraform manages them instead of recreating them.
# Safe to delete this file once the first apply has succeeded.

locals {
  import_instance_arn      = "arn:aws:sso:::instance/ssoins-75359051b774ea1d"
  import_identity_store_id = "d-9c67b48b57"
  import_management_group  = "167292f4-50b1-707e-c2a6-8c1e3d61bd5b"

  import_permission_sets = {
    AdministratorAccess = "arn:aws:sso:::permissionSet/ssoins-75359051b774ea1d/ps-7535f083f09e72d9"
    ViewOnlyAccess      = "arn:aws:sso:::permissionSet/ssoins-75359051b774ea1d/ps-753572a107b8822e"
  }
}

import {
  to = aws_identitystore_group.this["Management"]
  id = "${local.import_identity_store_id}/${local.import_management_group}"
}

import {
  to = aws_identitystore_group_membership.this["Management/Nick"]
  id = "${local.import_identity_store_id}/96a22284-e061-70b5-a5ec-469e69c1a554"
}

import {
  for_each = local.import_permission_sets
  to       = aws_ssoadmin_permission_set.this[each.key]
  id       = "${each.value},${local.import_instance_arn}"
}

import {
  to = aws_ssoadmin_managed_policy_attachment.this["AdministratorAccess/arn:aws:iam::aws:policy/AdministratorAccess"]
  id = "arn:aws:iam::aws:policy/AdministratorAccess,${local.import_permission_sets.AdministratorAccess},${local.import_instance_arn}"
}

import {
  to = aws_ssoadmin_managed_policy_attachment.this["ViewOnlyAccess/arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"]
  id = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess,${local.import_permission_sets.ViewOnlyAccess},${local.import_instance_arn}"
}

import {
  for_each = local.import_permission_sets
  to       = aws_ssoadmin_account_assignment.this["Management/${each.key}/nickchuks"]
  id       = "${local.import_management_group},GROUP,790013274466,AWS_ACCOUNT,${each.value},${local.import_instance_arn}"
}
