# Route Table for Web (Public) Subnets
resource "aws_route_table" "mktc_rtb_web" {
  vpc_id = var.vpc_id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }
  
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = var.internet_gateway_id
  }
  
  tags = {
    Name = "mktc-rtb-web"
  }
}

# Associate Route Table with Web Subnets
resource "aws_route_table_association" "web" {
  count          = length(var.web_subnet_ids)
  subnet_id      = var.web_subnet_ids[count.index]
  route_table_id = aws_route_table.mktc_rtb_web.id
}
