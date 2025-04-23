### Compute Module - variables.tf ###

variable "prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
  default     = "mktc"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "web_subnet_ids" {
  description = "List of subnet IDs for the web tier"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "List of subnet IDs for the application tier"
  type        = list(string)
}

variable "web_instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t2.micro"
}

variable "app_instance_type" {
  description = "EC2 instance type for application tier"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the key pair to use for EC2 instances"
  type        = string
  default     = "mktc"
}

variable "app_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 8080
}

variable "web_min_size" {
  description = "Minimum number of instances in the web tier"
  type        = number
  default     = 2
}

variable "web_max_size" {
  description = "Maximum number of instances in the web tier"
  type        = number
  default     = 4
}

variable "web_desired_capacity" {
  description = "Desired number of instances in the web tier"
  type        = number
  default     = 2
}

variable "app_min_size" {
  description = "Minimum number of instances in the application tier"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum number of instances in the application tier"
  type        = number
  default     = 4
}

variable "app_desired_capacity" {
  description = "Desired number of instances in the application tier"
  type        = number
  default     = 2
}

variable "enable_bastion" {
  description = "Whether to create a bastion host"
  type        = bool
  default     = true
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH to the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {
    Project     = "MKTC"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}