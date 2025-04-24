output "web_instance_id" {
  description = "ID of the web EC2 instance"
  value       = aws_instance.mktc_web.id
}

output "app_instance_id" {
  description = "ID of the application EC2 instance"
  value       = aws_instance.mktc_app.id
}

output "db_instance_id" {
  description = "ID of the database EC2 instance"
  value       = aws_instance.mktc_db.id
}

output "nat_instance_id" {
  description = "ID of the NAT instance"
  value       = var.enable_nat_instance ? aws_instance.mktc_nat[0].id : null
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.mktc_sg_web.id
}

output "app_security_group_id" {
  description = "ID of the app security group"
  value       = aws_security_group.mktc_sg_app.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.mktc_sg_db.id
}

output "nat_security_group_id" {
  description = "ID of the NAT security group"
  value       = var.enable_nat_instance ? aws_security_group.mktc_sg_nat[0].id : null
}