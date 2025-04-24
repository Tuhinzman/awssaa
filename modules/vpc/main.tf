resource "aws_vpc" "mktc_vpc" {
  cidr_block                       = var.vpc_cidr_block
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true
  
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "mktc_igw" {
  tags = {
    Name = "mktc-igw"
  }
}

resource "aws_internet_gateway_attachment" "mktc_igw_attachment" {
  internet_gateway_id = aws_internet_gateway.mktc_igw.id
  vpc_id              = aws_vpc.mktc_vpc.id
}