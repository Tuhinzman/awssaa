# variables.tf - Root variables

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.16.0.0/16"
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "mktc-vpc"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "reserved_subnets" {
  description = "CIDR blocks for reserved subnets"
  type        = list(string)
  default     = ["10.16.0.0/20", "10.16.64.0/20", "10.16.128.0/20"]
}

variable "db_subnets" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.16.16.0/20", "10.16.80.0/20", "10.16.144.0/20"]
}

variable "app_subnets" {
  description = "CIDR blocks for application subnets"
  type        = list(string)
  default     = ["10.16.32.0/20", "10.16.96.0/20", "10.16.160.0/20"]
}

variable "web_subnets" {
  description = "CIDR blocks for web subnets (public)"
  type        = list(string)
  default     = ["10.16.48.0/20", "10.16.112.0/20", "10.16.176.0/20"]
}

variable "key_name" {
  description = "SSH key pair name for EC2 instances"
  type        = string
  default     = "mktc"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}