### Database Module - main.tf ###

# Security group for the RDS instance
resource "aws_security_group" "database" {
  name        = "${var.prefix}-sg-db"
  description = "Security group for the database tier"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = var.app_security_group_ids
    description     = "Allow database access from application tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-sg-db"
    }
  )
}

# DB subnet group
resource "aws_db_subnet_group" "default" {
  name       = "${var.prefix}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-db-subnet-group"
    }
  )
}

# Random password for the database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# AWS Secrets Manager secret for storing database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.prefix}-db-credentials"
  description = "Database credentials for ${var.prefix} application"
  
  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = var.db_engine
    host     = aws_db_instance.main.address
    port     = var.db_port
    dbname   = var.db_name
  })
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.prefix}-db-parameter-group"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-db-parameter-group"
    }
  )
}

# RDS Option Group
resource "aws_db_option_group" "main" {
  name                     = "${var.prefix}-db-option-group"
  option_group_description = "Option group for ${var.prefix} database"
  engine_name              = var.db_engine
  major_engine_version     = var.engine_version

  dynamic "option" {
    for_each = var.db_options
    content {
      option_name = option.value.option_name

      dynamic "option_settings" {
        for_each = option.value.option_settings != null ? option.value.option_settings : []
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-db-option-group"
    }
  )
}

# RDS DB Instance
resource "aws_db_instance" "main" {
  identifier              = "${var.prefix}-db"
  engine                  = var.db_engine
  engine_version          = var.engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  storage_type            = var.storage_type
  storage_encrypted       = true
  
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.db_password.result
  port                    = var.db_port
  
  vpc_security_group_ids  = [aws_security_group.database.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name
  parameter_group_name    = aws_db_parameter_group.main.name
  option_group_name       = aws_db_option_group.main.name
  
  multi_az                = var.multi_az
  publicly_accessible     = false
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.prefix}-db-final-snapshot"
  deletion_protection     = var.deletion_protection
  
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  
  monitoring_interval    = var.enhanced_monitoring_interval
  monitoring_role_arn    = var.enhanced_monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null
  
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-db"
    }
  )
  
  lifecycle {
    prevent_destroy = false
  }
}

# IAM role for enhanced monitoring
resource "aws_iam_role" "rds_monitoring" {
  count = var.enhanced_monitoring_interval > 0 ? 1 : 0
  
  name = "${var.prefix}-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
  
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enhanced_monitoring_interval > 0 ? 1 : 0
  
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms for Database Monitoring
resource "aws_cloudwatch_metric_alarm" "db_cpu_high" {
  alarm_name          = "${var.prefix}-db-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Database CPU utilization is too high"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_ok_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "db_memory_free_low" {
  alarm_name          = "${var.prefix}-db-memory-free-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 200000000  # 200MB in bytes
  alarm_description   = "Database freeable memory is too low"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_ok_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "db_storage_low" {
  alarm_name          = "${var.prefix}-db-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.allocated_storage * 1024 * 1024 * 1024 * 0.2  # 20% of allocated storage in bytes
  alarm_description   = "Database free storage space is too low"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_ok_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "db_connection_count_high" {
  alarm_name          = "${var.prefix}-db-connection-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.max_connections_threshold
  alarm_description   = "Database connection count is too high"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_ok_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = var.common_tags
}

# Topic creation has been removed and moved to root module