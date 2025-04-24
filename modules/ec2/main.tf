# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Web instances
resource "aws_security_group" "mktc_sg_web" {
  name        = "mktc-sg-web"
  description = "Security group for web instances"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = {
    Name = "mktc-sg-web"
  }
}

# Security Group for App instances
resource "aws_security_group" "mktc_sg_app" {
  name        = "mktc-sg-app"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.mktc_sg_web.id]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.16.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = {
    Name = "mktc-sg-app"
  }
}

# Security Group for DB instances
resource "aws_security_group" "mktc_sg_db" {
  name        = "mktc-sg-db"
  description = "Security group for database instances"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.mktc_sg_app.id]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.16.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = {
    Name = "mktc-sg-db"
  }
}

# Security Group for NAT Instance
resource "aws_security_group" "mktc_sg_nat" {
  count       = var.enable_nat_instance ? 1 : 0
  name        = "mktc-sg-nat"
  description = "Security group for NAT instance"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.16.0.0/16"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.16.0.0/16"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = {
    Name = "mktc-sg-nat"
  }
}

# NAT Instance - Using Amazon Linux 2 with NAT configuration
resource "aws_instance" "mktc_nat" {
  count                       = var.enable_nat_instance ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id  # Using standard Amazon Linux 2
  instance_type               = var.instance_type
  subnet_id                   = var.web_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.mktc_sg_nat[0].id]
  associate_public_ip_address = true
  source_dest_check           = false  # Required for NAT functionality
  key_name                    = var.key_name
  
  user_data = <<-EOF
    #!/bin/bash
    # Enable IP forwarding
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p
    
    # Configure NAT with iptables
    yum install -y iptables-services
    systemctl enable iptables
    systemctl start iptables
    
    # Configure NAT
    iptables -t nat -A POSTROUTING -o eth0 -s 0.0.0.0/0 -j MASQUERADE
    
    # Save iptables rules
    service iptables save
  EOF
  
  tags = {
    Name = "mktc-nat-instance"
  }
}

# Web EC2 Instance
resource "aws_instance" "mktc_web" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = var.web_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.mktc_sg_web.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  
  tags = {
    Name = "mktc-web-instance"
  }
}

# App EC2 Instance
resource "aws_instance" "mktc_app" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.app_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.mktc_sg_app.id]
  key_name               = var.key_name
  
  tags = {
    Name = "mktc-app-instance"
  }
}

# DB EC2 Instance
resource "aws_instance" "mktc_db" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.db_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.mktc_sg_db.id]
  key_name               = var.key_name
  
  tags = {
    Name = "mktc-db-instance"
  }
}

# Route Table for private subnets using NAT instance
resource "aws_route_table" "mktc_rtb_private" {
  count  = var.enable_nat_instance ? 1 : 0
  vpc_id = var.vpc_id
  
  route {
    cidr_block  = "0.0.0.0/0"
    network_interface_id = aws_instance.mktc_nat[0].primary_network_interface_id
  }
  
  tags = {
    Name = "mktc-rtb-private"
  }
}

# Associate private route table with app subnets
resource "aws_route_table_association" "app" {
  count          = var.enable_nat_instance ? length(var.app_subnet_ids) : 0
  subnet_id      = var.app_subnet_ids[count.index]
  route_table_id = aws_route_table.mktc_rtb_private[0].id
}

# Associate private route table with db subnets
resource "aws_route_table_association" "db" {
  count          = var.enable_nat_instance ? length(var.db_subnet_ids) : 0
  subnet_id      = var.db_subnet_ids[count.index]
  route_table_id = aws_route_table.mktc_rtb_private[0].id
}
