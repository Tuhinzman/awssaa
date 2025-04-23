# Three-Tier Application Infrastructure for AWS - Beginner's Guide

This project provides a complete three-tier infrastructure on AWS using Terraform. It's designed to be beginner-friendly while following AWS best practices.

## Architecture Diagram (Text Format)

```
                                 Internet
                                     |
                                     ▼
                               Internet Gateway
                                     |
                                     ▼
+---------------------------------------------------------------------------------+
|                              VPC (10.16.0.0/16)                                  |
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
| | +-------------------+ |  | +-------------------+ |  | +-------------------+ |
| |         ▲             |  |         ▲             |  |                       | |
| |         │             |  |         │             |  |                       | |
| | +-------------------+ |  | +-------------------+ |  |                       | |
| | | Auto Scaling Group| |  | | Auto Scaling Group| |  |                       | |
| | |  (2-4 EC2 t3.small)| |  | |  (2-4 EC2 t3.small)| |  |                       | |
| | +-------------------+ |  | +-------------------+ |  |                       | |
| +-----------------------+  +-----------------------+  +-----------------------+ |
|                                                                                 |
| +----------------------------------------------------------------------------+ |
| |                       Security Groups & NACLs                               | |
| +----------------------------------------------------------------------------+ |
|                                                                                 |
| +------------------+  +------------------+  +------------------+  +----------+ |
| |  NAT Gateways    |  |   VPC Endpoints  |  |   CloudWatch     |  |    S3    | |
| +------------------+  +------------------+  +------------------+  +----------+ |
+---------------------------------------------------------------------------------+
```

## Detailed Infrastructure Specifications

### VPC Configuration
- **Number of VPCs**: 1
- **VPC CIDR Block**: 10.16.0.0/16
- **IPv6 CIDR Block**: Automatically assigned
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled

### Subnet Configuration
- **Total Number of Subnets**: 9 (3 tiers across 3 availability zones)

#### Web Tier Subnets (Public)
1. **Web Subnet A**:
   - CIDR: 10.16.48.0/20
   - Availability Zone: us-east-1a
   - Public IP on Launch: Yes
   - IPv6 Assigned: Yes
   
2. **Web Subnet B**:
   - CIDR: 10.16.112.0/20
   - Availability Zone: us-east-1b
   - Public IP on Launch: Yes
   - IPv6 Assigned: Yes
   
3. **Web Subnet C**:
   - CIDR: 10.16.176.0/20
   - Availability Zone: us-east-1c
   - Public IP on Launch: Yes
   - IPv6 Assigned: Yes

#### Application Tier Subnets (Private)
1. **App Subnet A**:
   - CIDR: 10.16.32.0/20
   - Availability Zone: us-east-1a
   - Public IP on Launch: No
   - IPv6 Assigned: No
   
2. **App Subnet B**:
   - CIDR: 10.16.96.0/20
   - Availability Zone: us-east-1b
   - Public IP on Launch: No
   - IPv6 Assigned: No
   
3. **App Subnet C**:
   - CIDR: 10.16.160.0/20
   - Availability Zone: us-east-1c
   - Public IP on Launch: No
   - IPv6 Assigned: No

#### Database Tier Subnets (Private)
1. **DB Subnet A**:
   - CIDR: 10.16.16.0/20
   - Availability Zone: us-east-1a
   - Public IP on Launch: No
   - IPv6 Assigned: No
   
2. **DB Subnet B**:
   - CIDR: 10.16.80.0/20
   - Availability Zone: us-east-1b
   - Public IP on Launch: No
   - IPv6 Assigned: No
   
3. **DB Subnet C**:
   - CIDR: 10.16.144.0/20
   - Availability Zone: us-east-1c
   - Public IP on Launch: No
   - IPv6 Assigned: No

### Network Components
- **Internet Gateway**: 1
- **NAT Gateways**: 3 (one per AZ)
- **Elastic IPs**: 3 (one for each NAT Gateway)
- **Route Tables**: 7 (1 for web tier, 3 for app tier, 3 for db tier)
- **VPC Endpoints**: At least 2 (S3, DynamoDB) + optional SSM endpoints
- **Network ACLs**: 3 (one per tier)
- **VPC Flow Logs**: Enabled (7-day retention)

### EC2 Instances and Compute
- **Web Tier**:
  - Auto Scaling Group: 2-4 instances (desired: 2)
  - Instance Type: t3.small
  - AMI: Latest Amazon Linux 2
  - User Data: Apache web server setup
  - Placement: Distributed across 3 AZs
  
- **Application Tier**:
  - Auto Scaling Group: 2-4 instances (desired: 2)
  - Instance Type: t3.small
  - AMI: Latest Amazon Linux 2
  - User Data: Java application setup
  - Placement: Distributed across 3 AZs
  
- **Bastion Host** (Optional):
  - Count: 1 
  - Instance Type: t2.micro
  - AMI: Latest Amazon Linux 2
  - Placement: Web Subnet A
  - Public IP: Yes

### Load Balancers
- **Web Tier ALB**:
  - Type: Application Load Balancer
  - Scheme: Internet-facing
  - Listeners: HTTP (80)
  - Target Group: EC2 instances in web tier
  
- **App Tier ALB**:
  - Type: Application Load Balancer
  - Scheme: Internal
  - Listeners: HTTP (8080)
  - Target Group: EC2 instances in app tier

### Database
- **RDS Instance**:
  - Engine: MySQL 8.0
  - Instance Class: db.t3.small
  - Storage: 20GB GP2 (auto-scaling to 100GB)
  - Multi-AZ: Optional (disabled by default)
  - Backup Retention: 7 days
  - Backup Window: 03:00-04:00 UTC
  - Maintenance Window: Sunday 05:00-06:00 UTC
  - Performance Insights: Enabled
  - Enhanced Monitoring: 60-second intervals

### Security Components
- **Security Groups**: 5 (ALB, Web, App, DB, VPC Endpoints)
- **IAM Roles**: Minimum 2 (EC2, RDS Monitoring)
- **Secret Management**: Database credentials in AWS Secrets Manager
- **S3 Bucket**: 1 (for static assets)
- **Optional AWS Config**: Configuration recorder
- **Optional CloudTrail**: Multi-region trail with S3 bucket

### Monitoring and Alerting
- **CloudWatch Dashboard**: Comprehensive dashboard with all components
- **CloudWatch Alarms**: CPU, memory, error rates, database metrics
- **SNS Topic**: For alarm notifications
- **Log Groups**: Web, application, and database logs
- **Optional Cost Budgets**: Monthly budget with notifications

## Getting Started for Beginners

### Prerequisites
1. **AWS Account**: You need an active AWS account
2. **AWS CLI**: Install and configure with your credentials
3. **Terraform**: Install version 1.0.0 or newer
4. **SSH Key Pair**: Create a key pair named "mktc.pem" in AWS console

### Step 1: Setting up your directory structure
```bash
# Create the main directory
mkdir mktc-three-tier-app
cd mktc-three-tier-app

# Create module directories
mkdir -p modules/network
mkdir -p modules/compute
mkdir -p modules/database
mkdir -p modules/monitoring
```

### Step 2: Copy the Terraform files
Create each file as shown in the provided artifacts. Here's what to create:

1. **Root Module Files**:
   - main.tf
   - variables.tf
   - outputs.tf
   - terraform.tfvars

2. **Network Module Files**:
   - modules/network/main.tf
   - modules/network/variables.tf
   - modules/network/outputs.tf

3. **Compute Module Files**:
   - modules/compute/main.tf
   - modules/compute/variables.tf
   - modules/compute/outputs.tf

4. **Database Module Files**:
   - modules/database/main.tf
   - modules/database/variables.tf
   - modules/database/outputs.tf

5. **Monitoring Module Files**:
   - modules/monitoring/main.tf
   - modules/monitoring/variables.tf
   - modules/monitoring/outputs.tf

### Step 3: Setting up your SSH key
Change the key file permissions:
```bash
chmod 400 mktc.pem
```

### Step 4: Initializing and applying Terraform
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# See what resources will be created
terraform plan

# Create the infrastructure
terraform apply

# When prompted, type "yes" to confirm
```

### Step 5: Understanding what's being created
When you run `terraform apply`, the following happens:

1. **VPC and Network** is created first
2. **Compute Resources** (EC2, load balancers) are created next
3. **Database** is provisioned
4. **Monitoring** resources are set up last

The process takes about 15-20 minutes to complete.

### Step 6: Accessing your application
After creation completes, Terraform outputs will show:
- Web Load Balancer URL
- Bastion host IP (if enabled)
- Database endpoint
- Dashboard URL

To access the web application:
```
http://<web_alb_dns_name>
```

To SSH to the bastion host:
```
ssh -i mktc.pem ec2-user@<bastion_public_ip>
```

### Step 7: Cleaning up
When you're done, destroy all resources to avoid ongoing charges:
```bash
terraform destroy
```

## Common Terraform Commands for Beginners

```bash
# Format your Terraform files for proper syntax
terraform fmt

# Show the current state
terraform state list

# Refresh state without making changes
terraform refresh

# Create a visual graph of dependencies
terraform graph

# Only plan and apply specific resources
terraform apply -target=module.compute
```

## Understanding the Module Structure

- **Network Module**: Creates the foundation (VPC, subnets, etc.)
- **Compute Module**: Provisions web and app tier resources
- **Database Module**: Sets up the database tier
- **Monitoring Module**: Creates CloudWatch resources

Each module follows a standard format:
- **main.tf**: Core resource definitions
- **variables.tf**: Input variables
- **outputs.tf**: Values returned by the module

## Security Considerations

1. **Public Access Restriction**:
   - In production, restrict `ssh_allowed_cidrs` to your specific IP
   - Consider removing direct SSH access and using AWS Systems Manager

2. **Database Security**:
   - Enable `db_deletion_protection` in production
   - Consider using `db_multi_az` for high availability

3. **Logging and Monitoring**:
   - Enable all suggested CloudWatch alarms
   - Consider enabling `enable_aws_config` and `enable_cloudtrail` in production

## Customizing Your Deployment

Edit the `terraform.tfvars` file to change:
- Region, availability zones
- Instance types and sizes
- Auto-scaling parameters
- Database configuration

## Troubleshooting Tips for Beginners

1. **"No such file or directory" error**:
   - Check your directory structure matches exactly
   - Ensure all module files are in the correct location

2. **"Failed to load state" error**:
   - Re-run `terraform init`
   - Check AWS permissions

3. **"Error creating resource" messages**:
   - Check AWS service quotas
   - Verify IAM permissions are sufficient

4. **Load balancer health check failures**:
   - Wait a few minutes for instances to initialize
   - Check security group rules

## Next Steps and Learning

1. Add a Route53 domain name
2. Implement SSL/TLS with ACM
3. Add a Content Delivery Network (CloudFront)
4. Implement CI/CD with AWS CodePipeline
5. Explore adding containers with ECS or EKS

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)