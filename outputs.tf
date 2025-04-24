# outputs.tf - Root outputs

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "reserved_subnet_ids" {
  description = "IDs of the reserved subnets"
  value       = module.subnets.reserved_subnet_ids
}

output "db_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.subnets.db_subnet_ids
}

output "app_subnet_ids" {
  description = "IDs of the application subnets"
  value       = module.subnets.app_subnet_ids
}

output "web_subnet_ids" {
  description = "IDs of the web subnets (public)"
  value       = module.subnets.web_subnet_ids
}

output "web_route_table_id" {
  description = "ID of the web route table"
  value       = module.routing.web_route_table_id
}

output "web_instance_id" {
  description = "ID of the web EC2 instance"
  value       = module.ec2.web_instance_id
}

output "app_instance_id" {
  description = "ID of the application EC2 instance"
  value       = module.ec2.app_instance_id
}

output "db_instance_id" {
  description = "ID of the database EC2 instance"
  value       = module.ec2.db_instance_id
}

output "nat_instance_id" {
  description = "ID of the NAT instance"
  value       = module.ec2.nat_instance_id
}