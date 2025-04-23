### Monitoring Module - outputs.tf ###

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "web_tier_alarms" {
  description = "Map of CloudWatch alarm ARNs for web tier"
  value = var.enable_alarms ? {
    cpu_high   = aws_cloudwatch_metric_alarm.web_cpu_high[0].arn
    http_5xx   = aws_cloudwatch_metric_alarm.web_5xx_errors[0].arn
    composite  = aws_cloudwatch_composite_alarm.web_tier_health[0].arn
  } : null
}

output "app_tier_alarms" {
  description = "Map of CloudWatch alarm ARNs for application tier"
  value = var.enable_alarms ? {
    cpu_high     = aws_cloudwatch_metric_alarm.app_cpu_high[0].arn
    memory_high  = aws_cloudwatch_metric_alarm.app_memory_high[0].arn
    composite    = aws_cloudwatch_composite_alarm.app_tier_health[0].arn
  } : null
}

output "security_alarms" {
  description = "Map of CloudWatch alarm ARNs for security"
  value = var.enable_alarms ? {
    rejected_ssh = aws_cloudwatch_metric_alarm.rejected_ssh_connections[0].arn
  } : null
}

output "budget_notifications" {
  description = "AWS Budget notifications configuration"
  value = var.enable_cost_budget ? {
    forecast_80_percent = "Email when forecasted cost exceeds 80% of monthly budget"
    actual_100_percent  = "Email when actual cost exceeds 100% of monthly budget"
  } : null
}