# main.tf - Root configuration

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr_block = var.vpc_cidr_block
  vpc_name       = var.vpc_name
}

module "subnets" {
  source = "./modules/subnets"
  
  vpc_id           = module.vpc.vpc_id
  vpc_ipv6_cidr_id = module.vpc.vpc_ipv6_cidr_id
  
  az_count         = var.az_count
  reserved_subnets = var.reserved_subnets
  db_subnets       = var.db_subnets
  app_subnets      = var.app_subnets
  web_subnets      = var.web_subnets
}

module "routing" {
  source = "./modules/routing"
  
  vpc_id            = module.vpc.vpc_id
  internet_gateway_id = module.vpc.internet_gateway_id
  web_subnet_ids    = module.subnets.web_subnet_ids
}

module "ec2" {
  source = "./modules/ec2"
  
  web_subnet_ids  = module.subnets.web_subnet_ids
  app_subnet_ids  = module.subnets.app_subnet_ids
  db_subnet_ids   = module.subnets.db_subnet_ids
  vpc_id          = module.vpc.vpc_id
  
  key_name        = var.key_name
  instance_type   = var.instance_type
  enable_nat_instance = true
  web_security_group_id = module.ec2.web_security_group_id
}