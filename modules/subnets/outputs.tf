output "reserved_subnet_ids" {
  description = "IDs of the reserved subnets"
  value       = aws_subnet.reserved[*].id
}

output "db_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.db[*].id
}

output "app_subnet_ids" {
  description = "IDs of the application subnets"
  value       = aws_subnet.app[*].id
}

output "web_subnet_ids" {
  description = "IDs of the web subnets (public)"
  value       = aws_subnet.web[*].id
}