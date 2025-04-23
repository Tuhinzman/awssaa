# Three-Tier AWS Infrastructure with Terraform - Comprehensive Guide

This project provides a production-ready Terraform configuration for deploying a complete three-tier architecture on AWS. This guide is designed for beginners to understand exactly what resources are created, their network configurations, and how they interact.

## Architecture Diagram (Text Format)

```
                                 Internet
                                     |
                                     ▼
                               Internet Gateway
                                     |
                                     ▼
+---------------------------------------------------------------------------------+
|                              VPC (10.16.0.0/16)                                 |
|                                                                                 |
| +-----------------------+  +-----------------------+  +-----------------------+ |
| |    Web Tier (Public)  |  |  App Tier (Private)   |  |   DB Tier (Private)   | |
| |                       |  |                       |  |                       | |
| | +-------------------+ |  | +-------------------+ |  | +-------------------+ |
| | | Subnet A          | |  | | Subnet A          | |  | | Subnet A          | |
| | | 10.16.48.0/20     |◄┼──┼─| 10.16.32.0/20     |◄┼──┼─| 10.16.16.0/20     | |
| | | us-east-1a        | |  | | us-east-1a        | |  | | us-east-1a        | |
| | +-------------------+ |  | +-------------------+ |  | +-------------------+ |
| |                       |  |                       |  |                       | |
| | +-------------------+ |  | +-------------------+ |  | +-------------------+ |
| | | Subnet B          | |  | | Subnet B          | |  | | Subnet B          | |
| | | 10.16.112.0/20    |◄┼──┼─| 10.16.96.0/20     |◄┼──┼─| 10.16.80.0/20     | |
| | | us-east-1b        | |  | | us-east-1b        | |  | | us-east-1b        | |
| | +-------------------+ |  | +-------------------+ |  | +-------------------+ |
| |                       |  |                       |  |                       | |
| | +-------------------+ |  | +-------------------+ |  | +-------------------+ |
| | | Subnet C          | |  | | Subnet C          | |  | | Subnet C          | |
| | | 10.16.176.0/20    |◄┼──┼─| 10.16.160.0/20    |◄┼──┼─| 10.16.144.0/20    | |
| | | us-east-1c        | |  | | us-east-1c        | |  | | us-east-1c        | |
| | +-------------------+ |  | +-------------------+ |  | +-------------------+ |
| |         ▲             |  |         ▲             |  |          ▲            | |
| |         │             |  |         │             |  |          │            | |
| | +-------------------+ |  | +-------------------+ |  | +-------------------+ |
| | | Web Load Balancer | |  | | App Load Balancer | |  | |    RDS Database   | |
| | | (Internet-facing) | |  | |    (Internal)     | |  | |     (MySQL 8.0)   | |
| | +-------------------+ |  | +-------------------+ |  | +-------------------+ |
| |         ▲             |  |         ▲             |  |                       | |
| |         │             |  |         │             |  |                       | |
| | +-------------------+ |  | +-------------------+ |  |                       | |
| | | Auto Scaling Group| |  | | Auto Scaling Group| |  |                       | |
| | | 2-4 EC2 t3.small  | |  | | 2-4 EC2 t3.small  | |  |                       | |
| | +-------------------+ |  | +-------------------+ |  |                       | |
| |                       |  |                       |  |                       | |
| | +-------------------+ |  |                       |  |                       | |
| | | Bastion Host      | |  |                       |  |                       | |
| | | (Optional)        | |  |                       |  |                       | |
| | +-------------------+ |  |                       |  |                       | |
| +-----------------------+  +-----------------------+  +-----------------------+ |
|                                                                                 |
| +------------------+  +------------------+  +----------------------+            |
| | NAT Gateways (3) |  | VPC Endpoints (5)|  | Network ACLs & SGs   |            |
| +------------------+  +------------------+  +----------------------+            |
|                                                                                 |
| +------------------+  +------------------+  +------------------+  +----------+ |
| | CloudWatch Alarms|  | SNS Notifications|  | Flow Logs        |  | S3 Bucket| |
| +------------------+  +------------------+  +------------------+  +----------+ |
+---------------------------------------------------------------------------------+
```

## Detailed Resource Specifications

### 1. Network Resources

#### VPC
- **Resource**: 1 Virtual Private Cloud
- **CIDR Block**: 10.16.0.0/16 (65,536 IP addresses)
- **IPv6 CIDR Block**: Automatically assigned
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled

#### Subnets (9 total)
**Web Tier Subnets (Public)**:
1. **Subnet A**:
   - CIDR: 10.16.48.0/20 (4,096 IP addresses)
   - Availability Zone: us-east-1a
   - Public IP auto-assignment: Enabled
   - IPv6 addressing: Enabled

2. **Subnet B**:
   - CIDR: 10.16.112.0/20 (4,096 IP addresses)
   - Availability Zone: us-east-1b
   - Public IP auto-assignment: Enabled
   - IPv6 addressing: Enabled

3. **Subnet C**:
   - CIDR: 10.16.176.0/20 (4,096 IP addresses)
   - Availability Zone: us-east-1c
   - Public IP auto-assignment: Enabled
   - IPv6 addressing: Enabled

**Application Tier Subnets (Private)**:
1. **Subnet A**:
   - CIDR: 10.16.32.0/20 (4,096 IP addresses)
   - Availability Zone: us-east-1a
   - Public IP auto-assignment: Disabled
   - IPv6 addressing: Disabled

2. **Subnet B**:
   - CIDR: 10.16.96.0/20 (4,096 IP addresses)
   - Availability Zone: us-east-1b
   - Public IP auto-assignment: Disabled
   - IPv6 addressing: Disabled

3. **Subnet C**:
   - CIDR: 10.16.160.0/20 (4,096 IP addresses)
   - Availability Zone: us-east-1c
   - Public IP auto-assignment: Disabled
   - IPv6 addressing: Disabled

**Database Tier Subnets (Private)**:
1. **Subnet A**:
   - CIDR: 10.16.16.0/20 (4,096 IP addresses)
   - Availability Zone: us-east-1a
   - Public IP auto-assignment: Disabled
   - IPv6 addressing: Disabled

2. **Subnet B**:
   - CIDR: 10.16.80.0/20 (4,096 IP addresses)
   - Availability Zone: us-east-1b
   - Public IP auto-assignment: Disabled
   - IPv6 addressing: Disabled

3. **Subnet C**:
   - CIDR: 10.16.144.0/20 (4,096 IP addresses)
   - Availability Zone: us-east-1c
   - Public IP auto-assignment: Disabled
   - IPv6 addressing: Disabled

#### Internet Gateway
- **Resource**: 1 Internet Gateway
- **Purpose**: Allows communication between VPC and internet
- **Attached to**: The VPC

#### NAT Gateways
- **Resource**: 3 NAT Gateways (one per AZ)
- **Purpose**: Enable private subnets to access internet
- **Elastic IPs**: 3 (one per NAT Gateway)
- **Placement**: One in each web tier subnet

#### Route Tables
- **Web Tier Route Table**: 
  - Default route (0.0.0.0/0) → Internet Gateway
  - IPv6 default route (::/0) → Internet Gateway
  - Local VPC routes

- **App Tier Route Tables** (3 - one per AZ): 
  - Default route (0.0.0.0/0) → NAT Gateway in same AZ
  - Local VPC routes
  - VPC Endpoint routes

- **DB Tier Route Tables** (3 - one per AZ):
  - Default route (0.0.0.0/0) → NAT Gateway in same AZ
  - Local VPC routes
  - VPC Endpoint routes

#### VPC Endpoints
- **S3 Gateway Endpoint**:
  - Type: Gateway
  - Service: S3
  - Route Tables: All private route tables

- **DynamoDB Gateway Endpoint**:
  - Type: Gateway
  - Service: DynamoDB
  - Route Tables: All private route tables

- **SSM Endpoints** (3 - Optional):
  - Type: Interface
  - Services: SSM, SSMMessages, EC2Messages
  - Subnets: App tier
  - Private DNS: Enabled

#### Network ACLs
- **Web Tier NACL**:
  - Inbound: Allow HTTP, HTTPS, SSH, ephemeral ports
  - Outbound: Allow HTTP, HTTPS, VPC CIDR, ephemeral ports

- **App Tier NACL**:
  - Inbound: Allow from VPC CIDR
  - Outbound: Allow to VPC CIDR, HTTPS to internet

- **DB Tier NACL**:
  - Inbound: Allow from VPC CIDR
  - Outbound: Allow responses to VPC CIDR

#### Flow Logs
- **Resource**: VPC Flow Logs
- **Destination**: CloudWatch Logs
- **Retention**: 7 days
- **Traffic Type**: ALL

### 2. Compute Resources

#### Web Tier

**Application Load Balancer**:
- **Resource**: 1 Internet-facing ALB
- **Subnets**: Web tier (public)
- **Security Group**: Allow HTTP/HTTPS from internet
- **Listener**: HTTP on port 80
- **Target Group**: Web instances
- **Health Check**: HTTP on path "/"

**Auto Scaling Group**:
- **Min Size**: 2 instances
- **Max Size**: 4 instances
- **Desired Capacity**: 2 instances
- **Health Check Type**: ELB
- **Termination Policy**: Oldest Instance

**Launch Template**:
- **AMI**: Latest Amazon Linux 2
- **Instance Type**: t3.small
- **Storage**: 8 GB gp2 (encrypted)
- **Security Group**: Web tier security group
- **User Data**: Installs and configures Apache, CloudWatch agent
- **IAM Role**: EC2 role with SSM and CloudWatch permissions
- **Key Pair**: mktc.pem

**Auto Scaling Policies**:
- **Scale Up**: When CPU > 70% for 4 minutes
- **Scale Down**: When CPU < 30% for 4 minutes

#### Application Tier

**Internal Application Load Balancer**:
- **Resource**: 1 Internal ALB
- **Subnets**: App tier (private)
- **Security Group**: Allow traffic from web tier
- **Listener**: HTTP on port 8080
- **Target Group**: App instances
- **Health Check**: HTTP on path "/"

**Auto Scaling Group**:
- **Min Size**: 2 instances
- **Max Size**: 4 instances
- **Desired Capacity**: 2 instances
- **Health Check Type**: ELB
- **Termination Policy**: Oldest Instance

**Launch Template**:
- **AMI**: Latest Amazon Linux 2
- **Instance Type**: t3.small
- **Storage**: 8 GB gp2 (encrypted)
- **Security Group**: App tier security group
- **User Data**: Installs Java 11, CloudWatch agent
- **IAM Role**: EC2 role with SSM and CloudWatch permissions
- **Key Pair**: mktc.pem

**Auto Scaling Policies**:
- **Scale Up**: When CPU > 70% for 4 minutes
- **Scale Down**: When CPU < 30% for 4 minutes

#### Bastion Host (Optional)
- **Resource**: 1 EC2 Instance
- **Subnet**: Web Tier (public)
- **Instance Type**: t2.micro
- **AMI**: Latest Amazon Linux 2
- **Security Group**: Allow SSH from specified CIDRs
- **Public IP**: Yes

### 3. Database Resources

**RDS Instance**:
- **Resource**: 1 MySQL RDS Instance
- **Engine**: MySQL 8.0
- **Instance Class**: db.t3.small
- **Storage**: 20 GB gp2 (encrypted), autoscaling to 100 GB
- **Multi-AZ**: Optional (disabled by default)
- **Subnet Group**: DB subnets across all AZs
- **Security Group**: Allow MySQL port from app tier
- **Backup Retention**: 7 days
- **Backup Window**: 03:00-04:00 UTC
- **Maintenance Window**: Sunday 05:00-06:00 UTC

**Parameter Group**:
- **Family**: mysql8.0
- **Parameters**:
  - max_connections: 500
  - character_set_server: utf8mb4
  - collation_server: utf8mb4_unicode_ci

**DB Monitoring**:
- **Performance Insights**: Enabled (7-day retention)
- **Enhanced Monitoring**: 60-second intervals
- **CloudWatch Logs**: Error, general, slowquery logs

**Credentials Management**:
- **Resource**: AWS Secrets Manager secret
- **Content**: DB credentials (username, password, endpoint, etc.)

### 4. Security Resources

**Security Groups**:
- **ALB Security Group**:
  - Inbound: HTTP/HTTPS from internet
  - Outbound: All traffic

- **Web Tier Security Group**:
  - Inbound: HTTP/HTTPS from ALB, SSH from bastion (optional)
  - Outbound: All traffic

- **App Tier Security Group**:
  - Inbound: 8080 from web tier, SSH from bastion (optional)
  - Outbound: All traffic

- **DB Tier Security Group**:
  - Inbound: 3306 from app tier
  - Outbound: All traffic

- **VPC Endpoints Security Group**:
  - Inbound: HTTPS from VPC CIDR
  - Outbound: All traffic

- **Bastion Security Group**:
  - Inbound: SSH from allowed CIDRs
  - Outbound: All traffic

**IAM Roles**:
- **EC2 Role**:
  - SSM Managed Instance Core
  - CloudWatch Agent Server Policy

- **RDS Monitoring Role**:
  - RDS Enhanced Monitoring

- **Flow Logs Role**:
  - CloudWatch Logs permissions

**AWS Config** (Optional):
- **Resource**: Configuration Recorder
- **Recording**: All resource types
- **IAM Role**: Config service role

**CloudTrail** (Optional):
- **Resource**: Trail
- **Multi-region**: Yes
- **Log Validation**: Enabled
- **S3 Bucket**: For CloudTrail logs

### 5. Monitoring Resources

**CloudWatch Dashboard**:
- **Resource**: Custom dashboard
- **Widgets**: EC2 CPU/Network, ALB metrics, RDS performance

**CloudWatch Alarms**:
- **Web Tier**:
  - High CPU utilization
  - 5XX errors from ALB
  - Composite health alarm

- **App Tier**:
  - High CPU utilization
  - High memory usage
  - Composite health alarm

- **DB Tier**:
  - High CPU utilization
  - Low freeable memory
  - Low storage space
  - High connection count

- **Security**:
  - Rejected SSH connections

**SNS Topic for Notifications**:
- **Email Subscription**: mktechcorp@gmail.com

**CloudWatch Log Groups**:
- **Web Tier**: Access logs, error logs
- **App Tier**: System logs
- **DB Tier**: Database logs
- **VPC**: Flow logs

**AWS Budgets** (Optional):
- **Resource**: Monthly budget
- **Notifications**: 80% forecast, 100% actual

### 6. Storage Resources

**S3 Bucket**:
- **Resource**: Static assets bucket
- **Versioning**: Enabled
- **Encryption**: AES-256
- **Public Access**: Blocked
- **Object Ownership**: Bucket owner preferred

## Benefits of This Architecture

### 1. High Availability and Fault Tolerance
- **Multi-AZ Design**: All tiers span 3 availability zones
- **Auto Scaling**: Automatically replaces failed instances
- **Load Balancing**: Distributes traffic to healthy instances only
- **RDS with optional Multi-AZ**: Automated failover for database

### 2. Enhanced Security
- **Defense in Depth**: Multiple security layers (VPC, subnets, security groups, NACLs)
- **Network Isolation**: Private subnets for application and database
- **Secure Administrative Access**: Systems Manager for instance management
- **Least Privilege**: Granular IAM permissions
- **Encrypted Data**: All sensitive data and storage is encrypted
- **Centralized Secrets**: Database credentials in AWS Secrets Manager

### 3. Scalability
- **Horizontal Scaling**: Auto Scaling Groups adjust capacity based on load
- **Independent Tier Scaling**: Each tier can scale independently
- **Storage Scaling**: Database storage grows automatically

### 4. Complete Monitoring
- **Comprehensive Dashboard**: Single pane of glass for all metrics
- **Proactive Alerting**: Email notifications for critical events
- **Performance Insights**: Deep visibility into database performance
- **Centralized Logging**: All system and application logs in CloudWatch

### 5. Cost Efficiency
- **Right-sized Resources**: Appropriate instance types for each tier
- **Auto Scaling**: Pay only for what you need, when you need it
- **Spot Instances**: Option to use Spot for non-critical workloads
- **Budget Alerts**: Proactive cost management

### 6. Operational Excellence
- **Infrastructure as Code**: Consistent, repeatable deployments
- **Modular Design**: Each component can be modified independently
- **Automated Compliance**: Optional AWS Config for compliance monitoring
- **Detailed Audit Trail**: Optional CloudTrail for all API activities

## Getting Started

### Prerequisites
1. **AWS Account**: You need an active AWS account
2. **AWS CLI**: Install and configure with your AWS credentials
   ```bash
   aws configure
   ```
3. **Terraform**: Install version 1.0.0 or newer
   ```bash
   # Download and install from https://www.terraform.io/downloads.html
   terraform -v  # Verify installation
   ```
4. **SSH Key Pair**: Create a key pair named "mktc.pem" in AWS console
   ```bash
   # AWS Management Console > EC2 > Key Pairs > Create key pair
   # Name: mktc
   # File format: .pem
   ```

### Step-by-Step Deployment

#### 1. Set up directory structure
Run the provided setup script:
```bash
chmod +x setup.sh
./setup.sh
```

This creates the necessary directories:
```
.
├── modules/
│   ├── network/      # VPC, subnets, etc.
│   ├── compute/      # EC2, ASG, ALB
│   ├── database/     # RDS, parameter groups
│   └── monitoring/   # CloudWatch, alarms
```

#### 2. Copy the Terraform files
Place all files in their correct locations:

**Root directory**:
- main.tf
- variables.tf
- outputs.tf
- terraform.tfvars

**Network module**:
- modules/network/main.tf
- modules/network/variables.tf
- modules/network/outputs.tf

**Compute module**:
- modules/compute/main.tf
- modules/compute/variables.tf
- modules/compute/outputs.tf

**Database module**:
- modules/database/main.tf
- modules/database/variables.tf
- modules/database/outputs.tf

**Monitoring module**:
- modules/monitoring/main.tf
- modules/monitoring/variables.tf
- modules/monitoring/outputs.tf

#### 3. Update key permissions
```bash
chmod 400 mktc.pem
```

#### 4. Initialize Terraform
```bash
terraform init
```

This command:
- Initializes the working directory
- Downloads providers (AWS provider)
- Sets up module structure

#### 5. Validate configuration
```bash
terraform validate
```

This checks for syntax errors and invalid resource configurations.

#### 6. Plan deployment
```bash
terraform plan
```

You'll see a detailed list of all resources Terraform will create:
- 1 VPC
- 9 Subnets
- 1 Internet Gateway
- 3 NAT Gateways (if enabled)
- Multiple security groups
- Auto Scaling Groups
- Load Balancers
- RDS Instance
- And many more resources

#### 7. Deploy infrastructure
```bash
terraform apply
```

Type "yes" when prompted to confirm.

Deployment takes approximately 15-20 minutes, mainly due to:
- NAT Gateway creation (~4 minutes)
- RDS provisioning (~10 minutes)
- Load Balancer creation (~3 minutes)

#### 8. Access your infrastructure
After deployment completes, you'll see outputs including:
- **Web Application URL**: http://<web_alb_dns_name>
- **SSH Command**: For bastion access
- **Database Endpoint**: For application configuration

## Understanding the Three-Tier Architecture

### Web Tier (Presentation Layer)
**Purpose**: Handles user interface and client requests

**Key Components**:
- **Load Balancer**: Entry point for all user traffic
- **EC2 Instances**: Run web servers (Apache)
- **Auto Scaling Group**: Maintains availability and performance

**Traffic Flow**:
1. User request comes to the Internet Gateway
2. Load Balancer receives the request
3. Request is forwarded to a healthy web instance
4. Web server processes the request and may call the application tier

### Application Tier (Logic Layer)
**Purpose**: Contains business logic and application processing

**Key Components**:
- **Internal Load Balancer**: Distributes requests from web tier
- **EC2 Instances**: Run application servers (Java)
- **Auto Scaling Group**: Scales with processing demands

**Traffic Flow**:
1. Web tier sends request to the app tier load balancer
2. Load balancer routes to a healthy app instance
3. Application processes the request
4. If data is needed, app tier queries database tier

### Database Tier (Data Layer)
**Purpose**: Stores and manages application data

**Key Components**:
- **RDS Instance**: Managed MySQL database
- **Parameter Group**: Optimized database settings
- **Subnet Group**: Spans multiple AZs for availability

**Traffic Flow**:
1. App tier sends query to database
2. Database processes query and returns results
3. App tier receives data and continues processing
4. Results eventually flow back to the web tier and user

## Security Walkthrough

### Network Security
- **Public vs. Private Subnets**: Only web tier is public
- **Network ACLs**: Control traffic at subnet level
- **Security Groups**: Control traffic at instance level
- **Flow Logs**: Monitor and audit network traffic

### Access Security
- **Bastion Host**: Single entry point for SSH access
- **Systems Manager**: Agent-based administration without SSH
- **VPC Endpoints**: Private access to AWS services
- **IAM Roles**: Temporary credentials for instances

### Data Security
- **Encryption at Rest**: All storage is encrypted
- **Encryption in Transit**: TLS for all connections
- **Secrets Manager**: Secure storage for sensitive credentials
- **Audit Logging**: Track all changes and access

## Customization Guide

Edit `terraform.tfvars` to customize your deployment:

### Network Customization
```hcl
# Change region
aws_region = "eu-west-1"

# Use different VPC CIDR
vpc_cidr = "172.16.0.0/16"

# Disable NAT Gateways for development/testing
create_nat_gateway = false
```

### Compute Customization
```hcl
# Change instance types
web_instance_type = "t3.medium"
app_instance_type = "t3.large"

# Adjust Auto Scaling settings
web_min_size = 3
web_max_size = 6
```

### Database Customization
```hcl
# Upgrade database
db_instance_class = "db.t3.medium"
db_allocated_storage = 50

# Enable Multi-AZ for production
db_multi_az = true
```

### Security Customization
```hcl
# Restrict SSH access
ssh_allowed_cidrs = ["203.0.113.0/24"]  # Your office IP range

# Enable security features
enable_aws_config = true
enable_cloudtrail = true
```

## Troubleshooting Guide

### Common Issues

#### Terraform Initialization Errors
```
Error: Failed to get existing workspaces: error listing workspaces: error running "terraform workspace list": exit status 1
```
**Solution**: Check your AWS credentials are properly configured
```bash
aws configure
```

#### Resource Creation Failures
```
Error: Error creating DB Instance: InvalidParameterCombination: RDS does not support creating a DB instance with the following combination
```
**Solution**: Check RDS instance type and engine version compatibility

#### Instance Access Issues
```
Error: timeout - last error: ssh: connect to host X.X.X.X port 22: Connection timed out
```
**Solution**: Verify security group rules and network ACLs

#### Dependency Errors
```
Error: Cycle: module.database, module.monitoring
```
**Solution**: Check for circular dependencies between modules

### Debugging Tips
1. **Check CloudTrail**: For API errors
2. **Examine CloudWatch Logs**: For instance issues
3. **Use AWS Console**: Verify resource creation
4. **Run with Logging**: `TF_LOG=DEBUG terraform apply`

## Cleaning Up

When you no longer need the infrastructure, destroy it to avoid ongoing costs:

```bash
terraform destroy
```

Type "yes" when prompted.

**Important**: This will delete all resources including:
- All EC2 instances
- Load balancers
- Database (including data)
- S3 buckets (and their contents)

## Advanced Topics

### Adding a CDN
Enhance your web tier with CloudFront for content delivery:
```hcl
module "cdn" {
  source = "./modules/cdn"
  web_alb_dns_name = module.compute.web_alb_dns_name
}
```

### Database Read Replicas
Improve database read performance:
```hcl
resource "aws_db_instance" "read_replica" {
  replicate_source_db = module.database.db_instance_id
  instance_class      = "db.t3.small"
}
```

### Private Networking
Use AWS Transit Gateway for secure multi-VPC connectivity:
```hcl
resource "aws_ec2_transit_gateway" "tgw" {
  description = "Transit Gateway for secure connectivity"
}
```

This three-tier infrastructure provides a comprehensive foundation for hosting applications on AWS, following best practices for security, reliability, and scalability. Whether you're deploying a simple website or a complex enterprise application, this architecture can scale to meet your needs.