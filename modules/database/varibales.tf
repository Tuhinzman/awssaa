### Database Module - variables.tf ###

variable "prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
  default     = "mktc"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "db_subnet_ids" {
  description = "List of subnet IDs for the database subnet group"
  type        = list(string)
}

variable "app_security_group_ids" {
  description = "List of security group IDs for the application tier"
  type        = list(string)
}

variable "db_engine" {
  description = "Database engine to use"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "parameter_group_family" {
  description = "Parameter group family for the database engine"
  type        = string
  default     = "mysql8.0"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "mktcdb"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "mktcadmin"
  sensitive   = true
}

variable "db_port" {
  description = "Port for the database instance"
  type        = number
  default     = 3306
}

variable "db_instance_class" {
  description = "Instance class for the database"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "Allocated storage for the database (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for storage autoscaling (GB)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type for the database"
  type        = string
  default     = "gp2"
}

variable "multi_az" {
  description = "Whether to deploy the database in multiple availability zones"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot when destroying the database"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the database"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Sun:05:00-Sun:06:00"
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["error", "general", "slowquery"]
}

variable "performance_insights_enabled" {
  description = "Whether to enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "enhanced_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 60
}

variable "auto_minor_version_upgrade" {
  description = "Whether to automatically upgrade minor versions"
  type        = bool
  default     = true
}

variable "max_connections_threshold" {
  description = "Threshold for database connection count alarm"
  type        = number
  default     = 100
}

variable "cloudwatch_alarm_actions" {
  description = "List of ARNs for CloudWatch alarm actions"
  type        = list(string)
  default     = []
}

variable "cloudwatch_ok_actions" {
  description = "List of ARNs for CloudWatch ok actions"
  type        = list(string)
  default     = []
}

variable "create_alarm_sns_topic" {
  description = "Whether to create an SNS topic for database alarms"
  type        = bool
  default     = false
}

variable "alarm_email_addresses" {
  description = "List of email addresses for database alarm notifications"
  type        = list(string)
  default     = null
}

variable "db_parameters" {
  description = "List of database parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "max_connections"
      value = "500"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    },
    {
      name  = "collation_server"
      value = "utf8mb4_unicode_ci"
    }
  ]
}

variable "db_options" {
  description = "List of database options to apply"
  type = list(object({
    option_name = string
    option_settings = list(object({
      name  = string
      value = string
    }))
  }))
  default = []
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