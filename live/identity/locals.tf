locals {
  resource_prefix = "${var.name}-${var.environment}"
  tags = {
    Project     = var.name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Path        = "aws-control/live/identity"
  }

  # Permission set name => AWS managed policies attached to it.
  # Control Tower's own AWS* permission sets are not managed here.
  permission_sets = {
    AdministratorAccess = {
      description      = "Full administrator access"
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    ViewOnlyAccess = {
      description      = "View resources and metadata without reading data"
      managed_policies = ["arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"]
    }
    Developer = {
      description      = "Build and run workloads; no IAM or Organizations administration"
      managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
    ReadOnly = {
      description      = "Read-only access to resources and data"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  # Group name => description. Control Tower's own AWS* groups are not managed here.
  groups = {
    Management           = "Administrators of the management account"
    platform-admins      = "Platform team: admin on all workload, sandbox, policy-staging and AFT accounts"
    network-admins       = "Admin on the network account, read-only on shared-service"
    payments-developers  = "Build in payment-dev, read-only in payment-prod"
    payments-operators   = "Admin on payment-prod"
    analytics-developers = "Build in analytics-dev, read-only in analytics-prod"
    analytics-operators  = "Admin on analytics-prod"
    sandbox-users        = "Admin on every account in the Sandbox OU"
    policy-testers       = "Admin on scp-test, to test SCPs against an administrator"
  }

  # Group name => Identity Center usernames
  group_members = {
    Management      = ["Nick"]
    platform-admins = ["Nick"]
  }

  # Access to every ACTIVE account under an OU (including nested OUs).
  # Re-apply after AFT vends an account to give it access.
  ou_assignments = [
    {
      group          = "platform-admins"
      permission_set = "AdministratorAccess"
      ous            = ["Infrastructure", "Workloads", "Sandbox", "Policy-Staging", "AFT-Management"]
    },
    {
      group          = "sandbox-users"
      permission_set = "AdministratorAccess"
      ous            = ["Sandbox"]
    },
  ]

  # Access to specific accounts by name. Accounts that don't exist yet are skipped.
  account_assignments = [
    { group = "Management", permission_set = "AdministratorAccess", accounts = ["nickchuks"] },
    { group = "Management", permission_set = "ViewOnlyAccess", accounts = ["nickchuks"] },
    { group = "network-admins", permission_set = "AdministratorAccess", accounts = ["network"] },
    { group = "network-admins", permission_set = "ReadOnly", accounts = ["shared-service"] },
    { group = "payments-developers", permission_set = "Developer", accounts = ["payment-dev"] },
    { group = "payments-developers", permission_set = "ReadOnly", accounts = ["payment-prod"] },
    { group = "payments-operators", permission_set = "AdministratorAccess", accounts = ["payment-prod"] },
    { group = "analytics-developers", permission_set = "Developer", accounts = ["analytics-dev"] },
    { group = "analytics-developers", permission_set = "ReadOnly", accounts = ["analytics-prod"] },
    { group = "analytics-operators", permission_set = "AdministratorAccess", accounts = ["analytics-prod"] },
    { group = "policy-testers", permission_set = "AdministratorAccess", accounts = ["scp-test"] },
  ]
}
