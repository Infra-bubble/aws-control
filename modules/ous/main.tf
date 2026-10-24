resource "aws_organizations_organizational_unit" "this" {
  name      = var.name
  parent_id = var.parent_id
  tags      = var.tags
}

# Registers the OU with Control Tower
resource "aws_controltower_baseline" "this" {
  baseline_identifier = var.baseline_identifier
  baseline_version    = var.baseline_version
  target_identifier   = aws_organizations_organizational_unit.this.arn
  tags                = var.tags

  parameters {
    key   = "IdentityCenterEnabledBaselineArn"
    value = var.identity_center_enabled_baseline_arn
  }
}

# Optional controls; Control Tower can only enable them once the OU is registered
resource "aws_controltower_control" "this" {
  for_each = var.controls

  control_identifier = each.value
  target_identifier  = aws_organizations_organizational_unit.this.arn

  depends_on = [aws_controltower_baseline.this]
}
