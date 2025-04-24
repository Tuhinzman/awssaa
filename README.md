# AWS Multi-Tier Infrastructure (Development Environment)

This repository contains Terraform code for deploying a multi-tier infrastructure in AWS designed for development environments.

## Architecture Overview

This infrastructure implements a traditional three-tier architecture (web, application, database) with additional reserved subnets for future use. It's designed to be cost-effective for development environments while maintaining good security practices.

+-----------------------------------------------------------------------+
|                                INTERNET                                |
+-------------------------------+---+-----------------------------------+
                                |
                                |
                                v
+-------------------------------+-----------------------------------+
|                         INTERNET GATEWAY                          |
+-------------------------------+-----------------------------------+
                                |
                                |
+-------------------------------v-----------------------------------+
|                                                                   |
|                         VPC (10.16.0.0/16)                       |
|                                                                   |
| +-----------------------------------------------------------+    |
| |                      ROUTE TABLES                          |    |
| |                                                           |    |
| | +---------------------+     +------------------------+    |    |
| | |     PUBLIC RT       |     |       PRIVATE RT       |    |    |
| | | 0.0.0.0/0 -> IGW    |     | 0.0.0.0/0 -> NAT Inst. |    |    |
| | | ::/0 -> IGW         |     |                        |    |    |
| | +-------+-------------+     +-------------+----------+    |    |
| +---------|----------------------------|-------------------+    |
|           |                            |                        |
|           v                            v                        |
|                                                                 |
| +-----------------+ +-----------------+ +-----------------+     |
| |     AZ - A      | |     AZ - B      | |     AZ - C      |     |
| |                 | |                 | |                 |     |
| | +---------+     | | +---------+     | | +---------+     |     |
| | |   Web   | <---+ | |   Web   | <---+ | |   Web   | <---+     |
| | | 10.16.48.0/20 | | | 10.16.112.0/20| | | 10.16.176.0/20|     |
| | +----+----+     | | +---------+     | | +---------+     |     |
| |      |    |     | |                 | |                 |     |
| |      |    |     | |                 | |                 |     |
| |      |    v     | |                 | |                 |     |
| |      | +--+---+ | |                 | |                 |     |
| |      | |NAT   | | |                 | |                 |     |
| |      | |Inst. | | |                 | |                 |     |
| |      | +--+---+ | |                 | |                 |     |
| |      |    |     | |                 | |                 |     |
| |      v    |     | |                 | |                 |     |
| | +---------+     | | +---------+     | | +---------+     |     |
| | |   App   | <---+ | |   App   | <---+ | |   App   | <---+     |
| | | 10.16.32.0/20 | | | 10.16.96.0/20 | | | 10.16.160.0/20|     |
| | +----+----+     | | +---------+     | | +---------+     |     |
| |      |          | |                 | |                 |     |
| |      v          | |                 | |                 |     |
| | +---------+     | | +---------+     | | +---------+     |     |
| | |   DB    | <---+ | |   DB    | <---+ | |   DB    | <---+     |
| | | 10.16.16.0/20 | | | 10.16.80.0/20 | | | 10.16.144.0/20|     |
| | +---------+     | | +---------+     | | +---------+     |     |
| |                 | |                 | |                 |     |
| | +---------+     | | +---------+     | | +---------+     |     |
| | |Reserved | <---+ | |Reserved | <---+ | |Reserved | <---+     |
| | | 10.16.0.0/20  | | | 10.16.64.0/20 | | | 10.16.128.0/20|     |
| | +---------+     | | +---------+     | | +---------+     |     |
| +-----------------+ +-----------------+ +-----------------+     |
|                                                                 |
| LEGEND:                  EC2 INSTANCES:                         |
| -------                  --------------                         |
| -> Public Route          Web: mktc-web-instance  (Public)       |
| --> Private Route        App: mktc-app-instance  (Private)      |
|                          DB:  mktc-db-instance   (Private)      |
|                          NAT: mktc-nat-instance  (Public)       |
+-----------------------------------------------------------------+

### Infrastructure Components

#### Network Layer
- **VPC**: Single VPC with both IPv4 (10.16.0.0/16) and IPv6 CIDR blocks
- **Internet Gateway**: Provides public internet access
- **Subnets**: 12 subnets across 3 Availability Zones:
  - 3 Reserved subnets (for future use)
  - 3 Database subnets (private)
  - 3 Application subnets (private)
  - 3 Web subnets (public)
- **Route Tables**:
  - Public route table for web tier
  - Private route table for app and database tiers

#### Compute Layer
- **NAT Instance**: EC2-based NAT for outbound internet access from private subnets
- **Web Tier**: EC2 instance in public subnet for web services
- **Application Tier**: EC2 instance in private subnet for application services
- **Database Tier**: EC2 instance in private subnet for database services

#### Security Layer
- **Security Groups**:
  - Web security group: HTTP, HTTPS, SSH from internet
  - App security group: Custom ports from web tier, SSH from VPC
  - Database security group: Database ports from app tier, SSH from VPC
  - NAT security group: HTTP, HTTPS from private subnets, SSH from internet

## CIDR Allocation

### VPC CIDR
- **IPv4**: 10.16.0.0/16 (65,536 addresses)
- **IPv6**: Automatically assigned by AWS

### Subnet CIDRs

| Subnet Name | Availability Zone | IPv4 CIDR | IPv6 CIDR |
|-------------|-------------------|-----------|-----------|
| sn-reserved-A | us-east-1a | 10.16.0.0/20 | Auto-assigned /72 |
| sn-reserved-B | us-east-1b | 10.16.64.0/20 | Auto-assigned /72 |
| sn-reserved-C | us-east-1c | 10.16.128.0/20 | Auto-assigned /72 |
| sn-db-A | us-east-1a | 10.16.16.0/20 | Auto-assigned /72 |
| sn-db-B | us-east-1b | 10.16.80.0/20 | Auto-assigned /72 |
| sn-db-C | us-east-1c | 10.16.144.0/20 | Auto-assigned /72 |
| sn-app-A | us-east-1a | 10.16.32.0/20 | Auto-assigned /72 |
| sn-app-B | us-east-1b | 10.16.96.0/20 | Auto-assigned /72 |
| sn-app-C | us-east-1c | 10.16.160.0/20 | Auto-assigned /72 |
| sn-web-A | us-east-1a | 10.16.48.0/20 | Auto-assigned /72 |
| sn-web-B | us-east-1b | 10.16.112.0/20 | Auto-assigned /72 |
| sn-web-C | us-east-1c | 10.16.176.0/20 | Auto-assigned /72 |

Each subnet has a /20 CIDR block, providing 4,096 IP addresses per subnet.

## Resources Created

The Terraform code creates the following AWS resources:

| Resource Type | Count | Description |
|---------------|-------|-------------|
| aws_vpc | 1 | Main VPC for all resources |
| aws_internet_gateway | 1 | Internet Gateway for public subnets |
| aws_subnet | 12 | Subnets across 3 availability zones |
| aws_route_table | 2 | Route tables for public and private subnets |
| aws_route_table_association | 9 | Associates subnets with route tables |
| aws_instance | 4 | EC2 instances (NAT, Web, App, DB) |
| aws_security_group | 4 | Security groups for different tiers |

## Benefits of This Infrastructure

1. **Cost-Effective for Development**: 
   - Uses NAT instance instead of more expensive NAT Gateways
   - Minimizes number of resources while maintaining multi-tier architecture

2. **High Availability Design**:
   - Resources spread across 3 Availability Zones
   - Framework in place for scaling to a production-ready architecture

3. **Security Best Practices**:
   - Proper network segmentation
   - Principle of least privilege for security groups
   - Web, application, and database tiers properly isolated

4. **IPv6 Ready**:
   - Dual-stack networking with both IPv4 and IPv6 support
   - Future-proofs the infrastructure

5. **Modularity and Reusability**:
   - Terraform code organized in reusable modules
   - Easy to extend or customize for different environments

6. **Clear Resource Organization**:
   - Consistent naming scheme (mktc-resource-type)
   - Logical subnet allocation with room for growth

## Deployment Instructions

1. Ensure you have Terraform installed:
   ```
   terraform version
   ```

2. Initialize the Terraform working directory:
   ```
   terraform init
   ```

3. Review the planned changes:
   ```
   terraform plan
   ```

4. Apply the configuration:
   ```
   terraform apply
   ```

5. When finished, you can destroy all resources:
   ```
   terraform destroy
   ```

## Customization

The infrastructure can be customized by modifying the variables in `terraform.tfvars`:

- Change the AWS region
- Adjust CIDR blocks
- Modify instance types
- Customize the VPC name
- Change the availability zone count

## Notes

- This setup uses the SSH key named `mktc.pem` - make sure this key exists in your AWS account
- EC2 instances use Amazon Linux 2 AMIs
- The NAT instance is configured with user data to enable IP forwarding and set up iptables rules