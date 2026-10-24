output "group_ids" {
  description = "Group name => Identity Center group ID"
  value       = { for k, g in aws_identitystore_group.this : k => g.group_id }
}

output "account_owner_email" {
  description = "Set this as sso_user.email in aft-account-request"
  value       = var.account_owner_email
}

output "assignments" {
  description = "Group/permission-set/account assignments currently managed"
  value       = sort(keys(local.assignments))
}
