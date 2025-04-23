### Network Module - main.tf ###

# VPC
resource "aws_vpc" "mktc_vpc" {
  cidr_block                       = var.vpc_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "mktc_igw" {
  vpc_id = aws_vpc.mktc_vpc.id
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-igw"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.create_nat_gateway ? length(var.availability_zones) : 0
  domain = "vpc"
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-eip-nat-${count.index + 1}"
    }
  )
}

# NAT Gateways
resource "aws_nat_gateway" "mktc_nat" {
  count         = var.create_nat_gateway ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.web[count.index].id
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-nat-${count.index + 1}"
    }
  )
  
  depends_on = [aws_internet_gateway.mktc_igw]
}

# Subnets
# Web/Public subnets
resource "aws_subnet" "web" {
  count                           = length(var.availability_zones)
  vpc_id                          = aws_vpc.mktc_vpc.id
  cidr_block                      = var.web_subnet_cidrs[count.index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.mktc_vpc.ipv6_cidr_block, 8, count.index)
  availability_zone               = var.availability_zones[count.index]
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-sn-web-${substr(var.availability_zones[count.index], -1, 1)}"
      Tier = "Web"
    }
  )
}

# Application subnets
resource "aws_subnet" "app" {
  count                           = length(var.availability_zones)
  vpc_id                          = aws_vpc.mktc_vpc.id
  cidr_block                      = var.app_subnet_cidrs[count.index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.mktc_vpc.ipv6_cidr_block, 8, count.index + 3)
  availability_zone               = var.availability_zones[count.index]
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = false
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-sn-app-${substr(var.availability_zones[count.index], -1, 1)}"
      Tier = "Application"
    }
  )
}

# Database subnets
resource "aws_subnet" "db" {
  count                           = length(var.availability_zones)
  vpc_id                          = aws_vpc.mktc_vpc.id
  cidr_block                      = var.db_subnet_cidrs[count.index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.mktc_vpc.ipv6_cidr_block, 8, count.index + 6)
  availability_zone               = var.availability_zones[count.index]
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = false
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-sn-db-${substr(var.availability_zones[count.index], -1, 1)}"
      Tier = "Database"
    }
  )
}

# Public Route Table (for web tier)
resource "aws_route_table" "web" {
  vpc_id = aws_vpc.mktc_vpc.id
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-rt-web"
      Tier = "Web"
    }
  )
}

# Public Routes
resource "aws_route" "web_internet_ipv4" {
  route_table_id         = aws_route_table.web.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mktc_igw.id
}

resource "aws_route" "web_internet_ipv6" {
  route_table_id              = aws_route_table.web.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.mktc_igw.id
}

# Private Route Tables (for app tier)
resource "aws_route_table" "app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.mktc_vpc.id
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-rt-app-${substr(var.availability_zones[count.index], -1, 1)}"
      Tier = "Application"
    }
  )
}

# Add routes to NAT Gateway for app tier (if enabled)
resource "aws_route" "app_nat_gateway" {
  count                  = var.create_nat_gateway ? length(var.availability_zones) : 0
  route_table_id         = aws_route_table.app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.mktc_nat[count.index].id
}

# Private Route Tables (for db tier)
resource "aws_route_table" "db" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.mktc_vpc.id
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-rt-db-${substr(var.availability_zones[count.index], -1, 1)}"
      Tier = "Database"
    }
  )
}

# Add routes to NAT Gateway for db tier (if enabled)
resource "aws_route" "db_nat_gateway" {
  count                  = var.create_nat_gateway ? length(var.availability_zones) : 0
  route_table_id         = aws_route_table.db[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.mktc_nat[count.index].id
}

# Route Table Associations
# Public
resource "aws_route_table_association" "web" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.web[count.index].id
  route_table_id = aws_route_table.web.id
}

# App tier
resource "aws_route_table_association" "app" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

# Database tier
resource "aws_route_table_association" "db" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[count.index].id
}

# VPC Endpoints for private connectivity (S3 and DynamoDB)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.mktc_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [for rt in aws_route_table.app : rt.id],
    [for rt in aws_route_table.db : rt.id]
  )
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-vpce-s3"
    }
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.mktc_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [for rt in aws_route_table.app : rt.id],
    [for rt in aws_route_table.db : rt.id]
  )
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-vpce-dynamodb"
    }
  )
}

# Optional SSM endpoints for secure EC2 access without internet
resource "aws_security_group" "vpc_endpoints" {
  count       = var.create_vpc_endpoints ? 1 : 0
  name        = "${var.prefix}-sg-vpc-endpoints"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.mktc_vpc.id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow HTTPS from VPC CIDR"
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
      Name = "${var.prefix}-sg-vpc-endpoints"
    }
  )
}

resource "aws_vpc_endpoint" "ssm" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.mktc_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-vpce-ssm"
    }
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.mktc_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-vpce-ssmmessages"
    }
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.mktc_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-vpce-ec2messages"
    }
  )
}

# Flow Logs for network monitoring
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/${var.prefix}-flow-logs"
  retention_in_days = 7
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-flow-logs"
    }
  )
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.prefix}-flow-logs-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
  
  tags = var.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.prefix}-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "vpc_flow_log" {
  count                = var.enable_flow_logs ? 1 : 0
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.mktc_vpc.id
  iam_role_arn         = aws_iam_role.flow_logs[0].arn
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-flow-log"
    }
  )
}

# Network ACLs for added security layer
resource "aws_network_acl" "web" {
  vpc_id     = aws_vpc.mktc_vpc.id
  subnet_ids = aws_subnet.web[*].id
  
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }
  
  egress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-nacl-web"
    }
  )
}

resource "aws_network_acl" "app" {
  vpc_id     = aws_vpc.mktc_vpc.id
  subnet_ids = aws_subnet.app[*].id
  
  # Allow inbound traffic from web tier
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }
  
  # Allow all outbound traffic to web and db tiers
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }
  
  # Allow outbound internet access if NAT is enabled
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-nacl-app"
    }
  )
}

resource "aws_network_acl" "db" {
  vpc_id     = aws_vpc.mktc_vpc.id
  subnet_ids = aws_subnet.db[*].id
  
  # Allow inbound traffic from app tier
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }
  
  # Allow outbound responses
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-nacl-db"
    }
  )
}