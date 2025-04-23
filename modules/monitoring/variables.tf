### Monitoring Module - variables.tf ###

variable "prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
  default     = "mktc"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "enable_alarms" {
  description = "Whether to enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "web_asg_name" {
  description = "Name of the web tier auto scaling group"
  type        = string
}

variable "app_asg_name" {
  description = "Name of the application tier auto scaling group"
  type        = string
}

variable "web_alb_arn" {
  description = "ARN suffix of the web tier load balancer"
  type        = string
}

variable "app_alb_arn" {
  description = "ARN suffix of the application tier load balancer"
  type        = string
}

variable "db_instance_id" {
  description = "ID of the RDS instance"
  type        = string
}

variable "alarm_email_addresses" {
  description = "List of email addresses for alarm notifications"
  type        = list(string)
  default     = []
}

variable "enable_cost_budget" {
  description = "Whether to enable AWS Budgets for cost monitoring"
  type        = bool
  default     = false
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 100
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {
    Project     = "MKTC"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}