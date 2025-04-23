### Compute Module - main.tf ###

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.prefix}-sg-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
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
      Name = "${var.prefix}-sg-alb"
    }
  )
}

resource "aws_security_group" "web" {
  name        = "${var.prefix}-sg-web"
  description = "Security group for web tier instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow HTTP from ALB"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow HTTPS from ALB"
  }

  dynamic "ingress" {
    for_each = var.enable_bastion ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
      description = "Allow SSH from allowed CIDRs"
    }
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
      Name = "${var.prefix}-sg-web"
    }
  )
}

resource "aws_security_group" "app" {
  name        = "${var.prefix}-sg-app"
  description = "Security group for application tier instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "Allow application traffic from web tier"
  }

  dynamic "ingress" {
    for_each = var.enable_bastion ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
      description = "Allow SSH from allowed CIDRs"
    }
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
      Name = "${var.prefix}-sg-app"
    }
  )
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.prefix}-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
  
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template for Web tier
resource "aws_launch_template" "web" {
  name                   = "${var.prefix}-lt-web"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = var.web_instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Install required packages
    yum update -y
    yum install -y httpd amazon-cloudwatch-agent
    
    # Start and enable Apache
    systemctl start httpd
    systemctl enable httpd
    
    # Install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    yum install -y unzip
    unzip awscliv2.zip
    ./aws/install
    
    # Add a basic index page
    cat > /var/www/html/index.html << 'EOT'
    <!DOCTYPE html>
    <html>
    <head>
        <title>${var.prefix} Web Server</title>
        <style>
            body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
            h1 { color: #333; }
        </style>
    </head>
    <body>
        <h1>${var.prefix} Three-Tier Web Server</h1>
        <p>This is the web tier of the three-tier architecture.</p>
        <p>Hostname: $(hostname)</p>
    </body>
    </html>
    EOT
    
    # Configure CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOT'
    {
      "metrics": {
        "metrics_collected": {
          "cpu": {
            "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
            "metrics_collection_interval": 60,
            "totalcpu": true
          },
          "mem": {
            "measurement": ["mem_used_percent"],
            "metrics_collection_interval": 60
          }
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/httpd/access_log",
                "log_group_name": "${var.prefix}-web-access-logs",
                "log_stream_name": "{instance_id}"
              },
              {
                "file_path": "/var/log/httpd/error_log",
                "log_group_name": "${var.prefix}-web-error-logs",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      }
    }
    EOT
    
    # Start CloudWatch agent
    systemctl start amazon-cloudwatch-agent
    systemctl enable amazon-cloudwatch-agent
    
    # Tag the instance (additional metadata)
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Tier,Value=Web --region $REGION
  EOF
  )
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name = "${var.prefix}-web"
        Tier = "Web"
      }
    )
  }
  
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.common_tags,
      {
        Name = "${var.prefix}-web-volume"
      }
    )
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-lt-web"
    }
  )
}

# Launch Template for App tier
resource "aws_launch_template" "app" {
  name                   = "${var.prefix}-lt-app"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = var.app_instance_type
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_name
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Install required packages
    yum update -y
    yum install -y java-11-amazon-corretto amazon-cloudwatch-agent
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    
    # Create a simple application
    mkdir -p /opt/app
    
    # Create a simple Spring Boot application
    cat > /opt/app/app.sh << 'EOT'
    #!/bin/bash
    while true; do
      echo "Application tier is running on $(hostname) at $(date)" > /opt/app/status.html
      sleep 10
    done
    EOT
    
    chmod +x /opt/app/app.sh
    
    # Create a systemd service
    cat > /etc/systemd/system/app.service << 'EOT'
    [Unit]
    Description=Simple App Service
    After=network.target
    
    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/app
    ExecStart=/opt/app/app.sh
    Restart=on-failure
    
    [Install]
    WantedBy=multi-user.target
    EOT
    
    # Enable and start the service
    systemctl enable app.service
    systemctl start app.service
    
    # Configure CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOT'
    {
      "metrics": {
        "metrics_collected": {
          "cpu": {
            "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
            "metrics_collection_interval": 60,
            "totalcpu": true
          },
          "mem": {
            "measurement": ["mem_used_percent"],
            "metrics_collection_interval": 60
          }
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "${var.prefix}-app-system-logs",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      }
    }
    EOT
    
    # Start CloudWatch agent
    systemctl start amazon-cloudwatch-agent
    systemctl enable amazon-cloudwatch-agent
    
    # Tag the instance (additional metadata)
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Tier,Value=App --region $REGION
  EOF
  )
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name = "${var.prefix}-app"
        Tier = "App"
      }
    )
  }
  
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.common_tags,
      {
        Name = "${var.prefix}-app-volume"
      }
    )
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-lt-app"
    }
  )
}

# Auto Scaling Groups
resource "aws_autoscaling_group" "web" {
  name                = "${var.prefix}-asg-web"
  min_size            = var.web_min_size
  max_size            = var.web_max_size
  desired_capacity    = var.web_desired_capacity
  vpc_zone_identifier = var.web_subnet_ids
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  target_group_arns = [aws_lb_target_group.web.arn]
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  termination_policies = ["OldestInstance"]
  
  tag {
    key                 = "Name"
    value               = "${var.prefix}-web"
    propagate_at_launch = true
  }
  
  dynamic "tag" {
    for_each = var.common_tags
    
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.prefix}-asg-app"
  min_size            = var.app_min_size
  max_size            = var.app_max_size
  desired_capacity    = var.app_desired_capacity
  vpc_zone_identifier = var.app_subnet_ids
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  target_group_arns = [aws_lb_target_group.app.arn]
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  termination_policies = ["OldestInstance"]
  
  tag {
    key                 = "Name"
    value               = "${var.prefix}-app"
    propagate_at_launch = true
  }
  
  dynamic "tag" {
    for_each = var.common_tags
    
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "web_scale_up" {
  name                   = "${var.prefix}-web-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "web_scale_down" {
  name                   = "${var.prefix}-web-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "app_scale_up" {
  name                   = "${var.prefix}-app-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "app_scale_down" {
  name                   = "${var.prefix}-app-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name          = "${var.prefix}-web-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
  
  alarm_description = "Scale up if CPU utilization is above 70% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.web_scale_up.arn]
  
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_low" {
  alarm_name          = "${var.prefix}-web-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
  
  alarm_description = "Scale down if CPU utilization is below 30% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.web_scale_down.arn]
  
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  alarm_name          = "${var.prefix}-app-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
  
  alarm_description = "Scale up if CPU utilization is above 70% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.app_scale_up.arn]
  
  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "app_cpu_low" {
  alarm_name          = "${var.prefix}-app-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
  
  alarm_description = "Scale down if CPU utilization is below 30% for 4 minutes"
  alarm_actions     = [aws_autoscaling_policy.app_scale_down.arn]
  
  tags = var.common_tags
}

# Web Load Balancer
resource "aws_lb" "web" {
  name                       = "${var.prefix}-alb-web"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.web_subnet_ids
  enable_deletion_protection = false
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-alb-web"
    }
  )
}

resource "aws_lb_target_group" "web" {
  name     = "${var.prefix}-tg-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-tg-web"
    }
  )
}

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# App Load Balancer (internal)
resource "aws_lb" "app" {
  name                       = "${var.prefix}-alb-app"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.app.id]
  subnets                    = var.app_subnet_ids
  enable_deletion_protection = false
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-alb-app"
    }
  )
}

resource "aws_lb_target_group" "app" {
  name     = "${var.prefix}-tg-app"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-tg-app"
    }
  )
}

resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = var.app_port
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Bastion host (optional)
resource "aws_instance" "bastion" {
  count                       = var.enable_bastion ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  subnet_id                   = var.web_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion[0].id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
  }
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Install required packages
    yum update -y
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    
    # Set up SSH key forwarding for bastion
    echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config
    systemctl restart sshd
  EOF
  )
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-bastion"
    }
  )
}

resource "aws_security_group" "bastion" {
  count       = var.enable_bastion ? 1 : 0
  name        = "${var.prefix}-sg-bastion"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
    description = "Allow SSH from allowed CIDRs"
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
      Name = "${var.prefix}-sg-bastion"
    }
  )
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "web_access" {
  name              = "${var.prefix}-web-access-logs"
  retention_in_days = 7
  
  tags = var.common_tags
}

resource "aws_cloudwatch_log_group" "web_error" {
  name              = "${var.prefix}-web-error-logs"
  retention_in_days = 7
  
  tags = var.common_tags
}

resource "aws_cloudwatch_log_group" "app_system" {
  name              = "${var.prefix}-app-system-logs"
  retention_in_days = 7
  
  tags = var.common_tags
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
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web.name],
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.app.name]
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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.web.arn_suffix],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Load Balancer Request Count"
        }
      }
    ]
  })
}