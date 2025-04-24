variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "web_subnet_ids" {
  description = "IDs of the web subnets"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "IDs of the application subnets"
  type        = list(string)
}

variable "db_subnet_ids" {
  description = "IDs of the database subnets"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "enable_nat_instance" {
  description = "Whether to create a NAT instance"
  type        = bool
  default     = false
}

variable "web_security_group_id" {
  description = "ID of the web security group"
  type        = string
  default     = ""
}
