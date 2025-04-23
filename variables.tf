### Root Module - variables.tf ###

# General Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "MKTC"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Development"
}

variable "prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
  default     = "mktc"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "Infrastructure Team"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.16.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "web_subnet_cidrs" {
  description = "CIDR blocks for web (public) subnets"
  type        = list(string)
  default     = ["10.16.48.0/20", "10.16.112.0/20", "10.16.176.0/20"]
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for application subnets"
  type        = list(string)
  default     = ["10.16.32.0/20", "10.16.96.0/20", "10.16.160.0/20"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.16.16.0/20", "10.16.80.0/20", "10.16.144.0/20"]
}

variable "create_nat_gateway" {
  description = "Whether to create NAT Gateways for private subnet internet access"
  type        = bool
  default     = true
}

variable "create_vpc_endpoints" {
  description = "Whether to create VPC Endpoints for AWS services"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs"
  type        = bool
  default     = true
}

# Compute Configuration
variable "web_instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t3.small"
}

variable "app_instance_type" {
  description = "EC2 instance type for application tier"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the key pair to use for EC2 instances"
  type        = string
  default     = "mktc"
}

variable "app_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 8080
}

variable "web_min_size" {
  description = "Minimum number of instances in the web tier"
  type        = number
  default     = 2
}

variable "web_max_size" {
  description = "Maximum number of instances in the web tier"
  type        = number
  default     = 4
}

variable "web_desired_capacity" {
  description = "Desired number of instances in the web tier"
  type        = number
  default     = 2
}

variable "app_min_size" {
  description = "Minimum number of instances in the application tier"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum number of instances in the application tier"
  type        = number
  default     = 4
}

variable "app_desired_capacity" {
  description = "Desired number of instances in the application tier"
  type        = number
  default     = 2
}

variable "enable_bastion" {
  description = "Whether to create a bastion host"
  type        = bool
  default     = true
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH to the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Database Configuration
variable "db_engine" {
  description = "Database engine to use"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_parameter_group_family" {
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

variable "db_allocated_storage" {
  description = "Allocated storage for the database (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for storage autoscaling (GB)"
  type        = number
  default     = 100
}

variable "db_storage_type" {
  description = "Storage type for the database"
  type        = string
  default     = "gp2"
}

variable "db_multi_az" {
  description = "Whether to deploy the database in multiple availability zones"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip final snapshot when destroying the database"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Whether to enable deletion protection for the database"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Sun:05:00-Sun:06:00"
}

variable "db_enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["error", "general", "slowquery"]
}

variable "db_performance_insights_enabled" {
  description = "Whether to enable Performance Insights"
  type        = bool
  default     = true
}

variable "db_performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "db_enhanced_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 60
}

variable "db_auto_minor_version_upgrade" {
  description = "Whether to automatically upgrade minor versions"
  type        = bool
  default     = true
}

variable "db_max_connections_threshold" {
  description = "Threshold for database connection count alarm"
  type        = number
  default     = 100
}

# Monitoring and Alerting
variable "enable_monitoring_alarms" {
  description = "Whether to enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "create_alarm_sns_topic" {
  description = "Whether to create an SNS topic for alarms"
  type        = bool
  default     = true
}

variable "alarm_email_addresses" {
  description = "List of email addresses for alarm notifications"
  type        = list(string)
  default     = []
}

# Security and Compliance
variable "enable_aws_config" {
  description = "Whether to enable AWS Config"
  type        = bool
  default     = false
}

variable "enable_cloudtrail" {
  description = "Whether to enable CloudTrail"
  type        = bool
  default     = false
}