### Root Module - outputs.tf ###

# VPC and Network Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = module.network.vpc_cidr
}

output "web_subnet_ids" {
  description = "IDs of the web subnets"
  value       = module.network.web_subnet_ids
}

output "app_subnet_ids" {
  description = "IDs of the application subnets"
  value       = module.network.app_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.network.db_subnet_ids
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.network.availability_zones
}

# Compute and Load Balancer Outputs
output "web_security_group_id" {
  description = "ID of the web tier security group"
  value       = module.compute.web_security_group_id
}

output "app_security_group_id" {
  description = "ID of the application tier security group"
  value       = module.compute.app_security_group_id
}

output "web_alb_dns_name" {
  description = "DNS name of the web tier load balancer"
  value       = module.compute.web_alb_dns_name
}

output "app_alb_dns_name" {
  description = "DNS name of the application tier load balancer"
  value       = module.compute.app_alb_dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.compute.bastion_public_ip
}

output "web_asg_name" {
  description = "Name of the web tier auto scaling group"
  value       = module.compute.web_asg_name
}

output "app_asg_name" {
  description = "Name of the application tier auto scaling group"
  value       = module.compute.app_asg_name
}

# Database Outputs
output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.db_instance_endpoint
}

output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = module.database.db_instance_address
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = module.database.db_instance_port
}

output "db_name" {
  description = "Name of the database"
  value       = module.database.db_name
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret for database credentials"
  value       = module.database.db_credentials_secret_arn
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.database.db_security_group_id
}

# SNS Topic Output
output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

# S3 Bucket Outputs
output "static_assets_bucket_name" {
  description = "Name of the S3 bucket for static assets"
  value       = aws_s3_bucket.static_assets.bucket
}

output "static_assets_bucket_domain_name" {
  description = "Domain name of the S3 bucket for static assets"
  value       = aws_s3_bucket.static_assets.bucket_domain_name
}

# Connection Instructions
output "ssh_to_bastion" {
  description = "Command to SSH to the bastion host"
  value       = var.enable_bastion ? "ssh -i ${var.key_name}.pem ec2-user@${module.compute.bastion_public_ip}" : "Bastion host is disabled"
}

output "application_url" {
  description = "URL to access the web application"
  value       = "http://${module.compute.web_alb_dns_name}"
}

# Dashboard URL
output "cloudwatch_dashboard_url" {
  description = "URL to access the CloudWatch dashboard"
  value       = module.monitoring.dashboard_url
}

# Additional Infrastructure Information
output "created_resources" {
  description = "Summary of created resources"
  value = {
    network = {
      vpc               = 1
      subnets           = length(var.availability_zones) * 3  # Web, App, DB subnets across AZs
      nat_gateways      = var.create_nat_gateway ? length(var.availability_zones) : 0
      vpc_endpoints     = var.create_vpc_endpoints ? 5 : 2  # S3, DynamoDB + optional SSM endpoints
    }
    compute = {
      auto_scaling_groups = 2  # Web and App ASGs
      load_balancers      = 2  # Web ALB and App ALB
      bastion_hosts       = var.enable_bastion ? 1 : 0
    }
    database = {
      rds_instances = 1
    }
    storage = {
      s3_buckets = 1 + (var.enable_cloudtrail ? 1 : 0)  # Static assets + optional CloudTrail bucket
    }
    security = {
      security_groups  = 4 + (var.enable_bastion ? 1 : 0)  # ALB, Web, App, DB + optional Bastion
      aws_config       = var.enable_aws_config
      cloudtrail       = var.enable_cloudtrail
    }
  }
}