variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_ipv6_cidr_id" {
  description = "IPv6 CIDR block of the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "reserved_subnets" {
  description = "CIDR blocks for reserved subnets"
  type        = list(string)
}

variable "db_subnets" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
}

variable "app_subnets" {
  description = "CIDR blocks for application subnets"
  type        = list(string)
}

variable "web_subnets" {
  description = "CIDR blocks for web subnets (public)"
  type        = list(string)
}
