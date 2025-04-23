### Compute Module - outputs.tf ###

output "web_security_group_id" {
  description = "ID of the web tier security group"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID of the application tier security group"
  value       = aws_security_group.app.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "web_alb_dns_name" {
  description = "DNS name of the web tier load balancer"
  value       = aws_lb.web.dns_name
}

output "web_alb_arn_suffix" {
  description = "ARN suffix of the web tier load balancer"
  value       = aws_lb.web.arn_suffix
}

output "app_alb_dns_name" {
  description = "DNS name of the application tier load balancer"
  value       = aws_lb.app.dns_name
}

output "app_alb_arn_suffix" {
  description = "ARN suffix of the application tier load balancer"
  value       = aws_lb.app.arn_suffix
}

output "web_asg_name" {
  description = "Name of the web tier auto scaling group"
  value       = aws_autoscaling_group.web.name
}

output "app_asg_name" {
  description = "Name of the application tier auto scaling group"
  value       = aws_autoscaling_group.app.name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = var.enable_bastion ? aws_instance.bastion[0].public_ip : null
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  value       = var.enable_bastion ? aws_security_group.bastion[0].id : null
}

output "web_launch_template_id" {
  description = "ID of the web tier launch template"
  value       = aws_launch_template.web.id
}

output "app_launch_template_id" {
  description = "ID of the application tier launch template"
  value       = aws_launch_template.app.id
}

output "ec2_iam_role_name" {
  description = "Name of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}