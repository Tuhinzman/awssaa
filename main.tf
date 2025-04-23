### Root Module - main.tf ###

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Local variables
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

# SNS Topic for alarms (at root level to avoid dependency cycles)
resource "aws_sns_topic" "alarms" {
  name = "${var.prefix}-alarms"
  
  tags = local.common_tags
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alarm_email_addresses)
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email_addresses[count.index]
}

# Network Module
module "network" {
  source = "./modules/network"
  
  prefix               = var.prefix
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  web_subnet_cidrs     = var.web_subnet_cidrs
  app_subnet_cidrs     = var.app_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  create_nat_gateway   = var.create_nat_gateway
  create_vpc_endpoints = var.create_vpc_endpoints
  enable_flow_logs     = var.enable_flow_logs
  
  common_tags = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"
  
  prefix            = var.prefix
  aws_region        = var.aws_region
  vpc_id            = module.network.vpc_id
  web_subnet_ids    = module.network.web_subnet_ids
  app_subnet_ids    = module.network.app_subnet_ids
  
  web_instance_type     = var.web_instance_type
  app_instance_type     = var.app_instance_type
  key_name              = var.key_name
  app_port              = var.app_port
  
  web_min_size          = var.web_min_size
  web_max_size          = var.web_max_size
  web_desired_capacity  = var.web_desired_capacity
  app_min_size          = var.app_min_size
  app_max_size          = var.app_max_size
  app_desired_capacity  = var.app_desired_capacity
  
  enable_bastion        = var.enable_bastion
  ssh_allowed_cidrs     = var.ssh_allowed_cidrs
  
  common_tags = local.common_tags
}

# Database Module
module "database" {
  source = "./modules/database"
  
  prefix                = var.prefix
  vpc_id                = module.network.vpc_id
  db_subnet_ids         = module.network.db_subnet_ids
  app_security_group_ids = [module.compute.app_security_group_id]
  
  db_engine             = var.db_engine
  engine_version        = var.db_engine_version
  parameter_group_family = var.db_parameter_group_family
  db_name               = var.db_name
  db_username           = var.db_username
  db_port               = var.db_port
  db_instance_class     = var.db_instance_class
  
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  
  multi_az              = var.db_multi_az
  skip_final_snapshot   = var.db_skip_final_snapshot
  deletion_protection   = var.db_deletion_protection
  
  backup_retention_period = var.db_backup_retention_period
  backup_window         = var.db_backup_window
  maintenance_window    = var.db_maintenance_window
  
  enabled_cloudwatch_logs_exports = var.db_enabled_cloudwatch_logs_exports
  
  performance_insights_enabled = var.db_performance_insights_enabled
  performance_insights_retention_period = var.db_performance_insights_retention_period
  
  enhanced_monitoring_interval = var.db_enhanced_monitoring_interval
  auto_minor_version_upgrade = var.db_auto_minor_version_upgrade
  
  max_connections_threshold = var.db_max_connections_threshold
  cloudwatch_alarm_actions = [aws_sns_topic.alarms.arn]
  cloudwatch_ok_actions = [aws_sns_topic.alarms.arn]
  
  common_tags = local.common_tags
}

# Monitoring and Alarms Module
module "monitoring" {
  source = "./modules/monitoring"
  
  prefix         = var.prefix
  aws_region     = var.aws_region
  enable_alarms  = var.enable_monitoring_alarms
  
  # Resources to monitor
  vpc_id          = module.network.vpc_id
  web_asg_name    = module.compute.web_asg_name
  app_asg_name    = module.compute.app_asg_name
  web_alb_arn     = module.compute.web_alb_arn_suffix
  app_alb_arn     = module.compute.app_alb_arn_suffix
  db_instance_id  = module.database.db_instance_id
  
  # Pass SNS topic ARN to the monitoring module
  sns_topic_arn   = aws_sns_topic.alarms.arn
  
  common_tags = local.common_tags
}

# S3 Bucket for application static assets
resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.prefix}-static-assets-${random_string.bucket_suffix.result}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.prefix}-static-assets"
    }
  )
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_ownership_controls" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Security and compliance related resources
resource "aws_config_configuration_recorder" "config" {
  count = var.enable_aws_config ? 1 : 0
  
  name     = "${var.prefix}-config-recorder"
  role_arn = aws_iam_role.config[0].arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "config" {
  count = var.enable_aws_config ? 1 : 0
  
  name = "${var.prefix}-config-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "config.amazonaws.com"
      }
    }]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_aws_config ? 1 : 0
  
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# CloudTrail for audit and compliance
resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0
  
  name                          = "${var.prefix}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  
  tags = local.common_tags
}

resource "aws_s3_bucket" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = "${var.prefix}-cloudtrail-logs-${random_string.cloudtrail_suffix[0].result}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.prefix}-cloudtrail-logs"
    }
  )
}

resource "random_string" "cloudtrail_suffix" {
  count   = var.enable_cloudtrail ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AWSCloudTrailAclCheck",
      Effect    = "Allow",
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      },
      Action    = "s3:GetBucketAcl",
      Resource  = aws_s3_bucket.cloudtrail[0].arn
    }, {
      Sid       = "AWSCloudTrailWrite",
      Effect    = "Allow",
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      },
      Action    = "s3:PutObject",
      Resource  = "${aws_s3_bucket.cloudtrail[0].arn}/*",
      Condition = {
        StringEquals = {
          "s3:x-amz-acl" = "bucket-owner-full-control"
        }
      }
    }]
  })
}