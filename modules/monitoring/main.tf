### Monitoring Module - main.tf ###

# SNS Topic for alerts
resource "aws_sns_topic" "alarms" {
  name = "${var.prefix}-alarms"
  
  tags = var.common_tags
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alarm_email_addresses)
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email_addresses[count.index]
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.prefix}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.web_asg_name, { label = "Web Tier CPU" }],
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.app_asg_name, { label = "App Tier CPU" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", var.web_asg_name, { label = "Web Tier NetworkIn" }],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", var.web_asg_name, { label = "Web Tier NetworkOut" }],
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", var.app_asg_name, { label = "App Tier NetworkIn" }],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", var.app_asg_name, { label = "App Tier NetworkOut" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Network Traffic"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", var.web_alb_arn, { label = "Web ALB 2XX" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", var.web_alb_arn, { label = "Web ALB 4XX" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.web_alb_arn, { label = "Web ALB 5XX" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Web ALB HTTP Response Codes"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.web_alb_arn, { label = "Web ALB Requests" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.web_alb_arn, { label = "Web ALB Response Time" }]
          ]
          period = 300
          stat   = ["Sum", "Average"]
          region = var.aws_region
          title  = "Web ALB Performance"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id, { label = "DB CPU" }],
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", var.db_instance_id, { label = "DB Free Memory" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_instance_id, { label = "DB Free Storage" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Performance"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_id, { label = "DB Connections" }],
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", var.db_instance_id, { label = "Read IOPS" }],
            ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", var.db_instance_id, { label = "Write IOPS" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Connections and IOPS"
        }
      }
    ]
  })
}

# CloudWatch Alarms
# Web tier alarms
resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.prefix}-web-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Average CPU utilization is too high for Web tier"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  
  dimensions = {
    AutoScalingGroupName = var.web_asg_name
  }
  
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "web_5xx_errors" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.prefix}-web-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Too many 5XX errors from Web tier targets"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  
  dimensions = {
    LoadBalancer = var.web_alb_arn
  }
  
  tags = var.common_tags
}

# App tier alarms
resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.prefix}-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Average CPU utilization is too high for App tier"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  
  dimensions = {
    AutoScalingGroupName = var.app_asg_name
  }
  
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "app_memory_high" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.prefix}-app-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Average memory utilization is too high for App tier"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  
  dimensions = {
    AutoScalingGroupName = var.app_asg_name
  }
  
  tags = var.common_tags
}

# VPC Flow Logs Metric Filter and Alarm (for suspicious activities)
resource "aws_cloudwatch_log_metric_filter" "rejected_connections" {
  count          = var.enable_alarms ? 1 : 0
  name           = "${var.prefix}-rejected-connections"
  pattern        = "[version, account, eni, source, destination, srcport, destport=\"22\", protocol=\"6\", packets, bytes, windowstart, windowend, action=\"REJECT\", flowlogstatus]"
  log_group_name = "/aws/vpc/${var.prefix}-flow-logs"
  
  metric_transformation {
    name      = "RejectedSSHConnections"
    namespace = "${var.prefix}VPCFlowLogs"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "rejected_ssh_connections" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.prefix}-rejected-ssh-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RejectedSSHConnections"
  namespace           = "${var.prefix}VPCFlowLogs"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "High number of rejected SSH connections detected"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  
  tags = var.common_tags
}

# CloudWatch Composite Alarms (requires AWS provider >= 3.15.0)
resource "aws_cloudwatch_composite_alarm" "web_tier_health" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.prefix}-web-tier-health"
  alarm_description   = "Composite alarm for web tier health"
  alarm_rule          = "ALARM(${aws_cloudwatch_metric_alarm.web_cpu_high[0].alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.web_5xx_errors[0].alarm_name})"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  
  tags = var.common_tags
}

resource "aws_cloudwatch_composite_alarm" "app_tier_health" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.prefix}-app-tier-health"
  alarm_description   = "Composite alarm for application tier health"
  alarm_rule          = "ALARM(${aws_cloudwatch_metric_alarm.app_cpu_high[0].alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.app_memory_high[0].alarm_name})"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  
  tags = var.common_tags
}

# AWS Budget for cost monitoring (optional)
resource "aws_budgets_budget" "monthly" {
  count             = var.enable_cost_budget ? 1 : 0
  name              = "${var.prefix}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alarm_email_addresses
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alarm_email_addresses
  }
}