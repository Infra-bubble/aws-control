output "id" {
  description = "ID of the OU"
  value       = aws_organizations_organizational_unit.this.id
}

output "arn" {
  description = "ARN of the OU"
  value       = aws_organizations_organizational_unit.this.arn
}

output "enabled_controls" {
  description = "Optional controls enabled on this OU: short name => enabled control ARN"
  value       = { for k, c in aws_controltower_control.this : k => c.arn }
}
