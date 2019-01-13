#
# variables.tf
#
# Terraform variables.
#

variable "ssh_key" {
  description = "Public SSH key for AWS key pair."
}

variable "trusted_networks_cidr_blocks" {
  description = "Trusted networks to be allowed to ingress with ICMP and SSH into the environment."
  type        = "list"
}

variable "aws_key_pair_name" {
  description = "AWS key pair name."
}

variable "aws_access_key_id" {
  description = "AWS access key id."
}

variable "aws_secret_access_key" {
  description = "AWS secret access key."
}


variable "aws_region" {
  description = "AWS region."
}

variable "aws_availability_zones" {
  description = "AWS availability zones."
  type        = "list"
}

variable "aws_vpc_cidr_block" {
  description = "AWS VPC CIDR block."
}

variable "aws_subnet_cidr_blocks" {
  description = "AWS subnet CIDR blocks. Each availability zone has one subnet."
  type        = "list"
}

variable "aws_ami" {
  description = "AWS AMI for EC2 instances."
}

variable "aws_instance_type" {
  description = "AWS EC2 instance type."
}

variable "aws_autoscaling_group_min_size" {
  description = "AWS EC2 autoscaling group minimum size."
}

variable "aws_autoscaling_group_max_size" {
  description = "AWS EC2 autoscaling group maximum size."
}

variable "aws_autoscaling_group_desired_capacity" {
  description = "AWS EC2 autoscaling group desired capacity."
}

variable "environment_name" {
  description = "A general purpose name for the environment."
}
