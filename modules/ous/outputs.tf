output "id" {
  description = "ID of the OU"
  value       = aws_organizations_organizational_unit.this.id
}

output "arn" {
  description = "ARN of the OU"
  value       = aws_organizations_organizational_unit.this.arn
}
