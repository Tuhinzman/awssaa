variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  type        = string
}

variable "web_subnet_ids" {
  description = "IDs of the web subnets"
  type        = list(string)
}
