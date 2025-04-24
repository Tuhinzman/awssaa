output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.mktc_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.mktc_vpc.cidr_block
}

output "vpc_ipv6_cidr_id" {
  description = "IPv6 CIDR block of the created VPC"
  value       = aws_vpc.mktc_vpc.ipv6_cidr_block
}

output "internet_gateway_id" {
  description = "ID of the created Internet Gateway"
  value       = aws_internet_gateway.mktc_igw.id
}