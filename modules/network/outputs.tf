### Network Module - outputs.tf ###

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.mktc_vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.mktc_vpc.cidr_block
}

output "vpc_ipv6_cidr" {
  description = "IPv6 CIDR block of the created VPC"
  value       = aws_vpc.mktc_vpc.ipv6_cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.mktc_igw.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = var.create_nat_gateway ? aws_nat_gateway.mktc_nat[*].id : []
}

output "web_subnet_ids" {
  description = "IDs of the web subnets"
  value       = aws_subnet.web[*].id
}

output "web_subnet_cidrs" {
  description = "CIDR blocks of the web subnets"
  value       = aws_subnet.web[*].cidr_block
}

output "app_subnet_ids" {
  description = "IDs of the application subnets"
  value       = aws_subnet.app[*].id
}

output "app_subnet_cidrs" {
  description = "CIDR blocks of the application subnets"
  value       = aws_subnet.app[*].cidr_block
}

output "db_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.db[*].id
}

output "db_subnet_cidrs" {
  description = "CIDR blocks of the database subnets"
  value       = aws_subnet.db[*].cidr_block
}

output "web_route_table_id" {
  description = "ID of the web route table"
  value       = aws_route_table.web.id
}

output "app_route_table_ids" {
  description = "IDs of the application route tables"
  value       = aws_route_table.app[*].id
}

output "db_route_table_ids" {
  description = "IDs of the database route tables"
  value       = aws_route_table.db[*].id
}

output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "ssm_endpoints_security_group_id" {
  description = "ID of the security group for SSM endpoints"
  value       = var.create_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}