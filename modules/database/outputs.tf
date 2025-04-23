### Database Module - outputs.tf ###

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "db_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = aws_db_subnet_group.default.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "db_parameter_group_id" {
  description = "ID of the database parameter group"
  value       = aws_db_parameter_group.main.id
}

output "db_option_group_id" {
  description = "ID of the database option group"
  value       = aws_db_option_group.main.id
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret for database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_master_username" {
  description = "Master username for the database"
  value       = var.db_username
}

output "db_name" {
  description = "Name of the database"
  value       = var.db_name
}

output "db_monitoring_role_arn" {
  description = "ARN of the IAM role for RDS enhanced monitoring"
  value       = var.enhanced_monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null
}

output "db_cloudwatch_alarms" {
  description = "Map of CloudWatch alarm ARNs"
  value = {
    cpu_high          = aws_cloudwatch_metric_alarm.db_cpu_high.arn
    memory_free_low   = aws_cloudwatch_metric_alarm.db_memory_free_low.arn
    storage_low       = aws_cloudwatch_metric_alarm.db_storage_low.arn
    connection_high   = aws_cloudwatch_metric_alarm.db_connection_count_high.arn
  }
}

output "db_sns_topic_arn" {
  description = "ARN of the SNS topic for database alarms"
  value       = var.create_alarm_sns_topic ? aws_sns_topic.db_alarms[0].arn : null
}