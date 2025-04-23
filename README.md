# Three-Tier Architecture with Terraform for AWS

This project implements a complete three-tier architecture on AWS using Terraform, following best practices for a development environment. The architecture includes web, application, and database tiers with auto-scaling, monitoring, and security features.

## Architecture Overview

![Three-Tier Architecture](architecture-diagram.png)

The infrastructure consists of:

### Network Layer
- VPC with IPv4 and IPv6 CIDR blocks
- 9 Subnets across 3 availability zones (Web, Application, and Database tiers)
- Internet Gateway for public internet access
- NAT Gateways for private subnets' outbound connectivity
- VPC Endpoints for secure AWS service access
- Network ACLs for additional security
- VPC Flow Logs for network monitoring

### Web Tier (Public)
- Auto Scaling Group with EC2 instances
- Application Load Balancer
- Auto-scaling policies based on CPU utilization
- Security Groups allowing HTTP/HTTPS traffic

### Application Tier (Private)
- Auto Scaling Group with EC2 instances
- Internal Application Load Balancer
- Auto-scaling policies based on CPU utilization
- Security Groups allowing only traffic from the web tier

### Database Tier (Private)
- RDS MySQL instance
- Multi-AZ option (configurable)
- Automated backups
- Parameter and Option Groups
- Performance Insights and Enhanced Monitoring
- Credentials stored in AWS Secrets Manager

### Additional Resources
- S3 bucket for application static assets
- CloudWatch Dashboards and Alarms
- SNS Topic for alarm notifications
- Optional AWS Config and CloudTrail for compliance
- IAM roles and policies with least privilege
- Optional Bastion Host for secure SSH access

## Module Structure

```
.
├── README.md
├── main.tf             # Root module
├── variables.tf        # Root variables
├── outputs.tf          # Root outputs
├── terraform.tfvars    # Variable values
└── modules/
    ├── network/        # Network module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── compute/        # Compute module (Web & App tiers)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── database/       # Database module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── monitoring/     # Monitoring and alerting module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

- AWS account
- AWS CLI configured with appropriate credentials
- Terraform v1.0.0 or newer
- SSH key pair named "mktc.pem" already created in AWS

## Key Pair Permissions

Before using this Terraform configuration, ensure your key pair has the correct permissions:

```bash
chmod 400 mktc.pem
```

## Usage

1. Clone this repository
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. Create the directory structure and copy the files
   ```bash
   mkdir -p modules/{network,compute,database,monitoring}
   # Copy all .tf files to their respective directories
   ```

3. Initialize Terraform
   ```bash
   terraform init
   ```

4. Review the execution plan
   ```bash
   terraform plan
   ```

5. Apply the configuration
   ```bash
   terraform apply
   ```

6. To destroy the infrastructure when no longer needed
   ```bash
   terraform destroy
   ```

## Development vs. Production Configuration

The default configuration is optimized for a development environment. For a production environment, consider the following changes in terraform.tfvars:

```terraform
# Production Configuration Changes
environment              = "Production"
db_multi_az              = true
db_skip_final_snapshot   = false  
db_deletion_protection   = true
db_instance_class        = "db.t3.medium"  # or larger
web_instance_type        = "t3.medium"     # or larger
app_instance_type        = "t3.medium"     # or larger
ssh_allowed_cidrs        = ["YOUR.OFFICE.IP.CIDR"]  # restrict access
enable_aws_config        = true
enable_cloudtrail        = true
```

## Best Practices Implemented

1. **Modularity** - Separated by function for reusability and maintenance
2. **Least Privilege** - IAM roles with minimal permissions
3. **Security** - Security groups, NACLs, private subnets, encryption
4. **High Availability** - Multiple AZs, load balancing, auto-scaling
5. **Scalability** - Auto-scaling groups, configurable instance types
6. **Monitoring** - CloudWatch dashboards, alarms, logs
7. **Cost Optimization** - Right-sized resources for development
8. **Compliance** - Optional AWS Config and CloudTrail
9. **Documentation** - Comprehensive README and code comments
10. **State Management** - Use of variables, outputs, and dependencies

## Security Considerations

- In a production environment, restrict SSH access to specific IP addresses
- Consider using AWS Systems Manager Session Manager for secure shell access
- Implement encryption for data in transit and at rest (implemented by default)
- Use AWS Config and CloudTrail for compliance and auditing
- Consider adding a Web Application Firewall (WAF) for the web tier
- Implement regular backups and disaster recovery procedures

## Accessing Resources

Web application: http://<web_alb_dns_name> (available in outputs)

Bastion host: ssh -i mktc.pem ec2-user@<bastion_public_ip> (available in outputs)

## Customization

Edit the `terraform.tfvars` file to customize:
- AWS region
- VPC and subnet CIDR blocks
- Instance types
- Database configurations
- Auto-scaling settings
- Monitoring options

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.