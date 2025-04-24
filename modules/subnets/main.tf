data "aws_availability_zones" "available" {
  state = "available"
}

# Reserved Subnets
resource "aws_subnet" "reserved" {
  count                           = var.az_count
  vpc_id                          = var.vpc_id
  cidr_block                      = var.reserved_subnets[count.index]
  ipv6_cidr_block                 = cidrsubnet(var.vpc_ipv6_cidr_id, 8, count.index)
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  assign_ipv6_address_on_creation = true
  
  tags = {
    Name = "sn-reserved-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}"
  }
}

# Database Subnets
resource "aws_subnet" "db" {
  count                           = var.az_count
  vpc_id                          = var.vpc_id
  cidr_block                      = var.db_subnets[count.index]
  ipv6_cidr_block                 = cidrsubnet(var.vpc_ipv6_cidr_id, 8, var.az_count + count.index)
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  assign_ipv6_address_on_creation = true
  
  tags = {
    Name = "sn-db-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}"
  }
}

# Application Subnets
resource "aws_subnet" "app" {
  count                           = var.az_count
  vpc_id                          = var.vpc_id
  cidr_block                      = var.app_subnets[count.index]
  ipv6_cidr_block                 = cidrsubnet(var.vpc_ipv6_cidr_id, 8, 2*var.az_count + count.index)
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  assign_ipv6_address_on_creation = true
  
  tags = {
    Name = "sn-app-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}"
  }
}

# Web Subnets (Public)
resource "aws_subnet" "web" {
  count                           = var.az_count
  vpc_id                          = var.vpc_id
  cidr_block                      = var.web_subnets[count.index]
  ipv6_cidr_block                 = cidrsubnet(var.vpc_ipv6_cidr_id, 8, 3*var.az_count + count.index)
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true
  
  tags = {
    Name = "sn-web-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}"
  }
}