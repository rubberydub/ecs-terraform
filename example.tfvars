#
# test.tfvars
#

aws_region             = "ap-southeast-2"
aws_availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

aws_vpc_cidr_block     = "10.0.0.0/16"
aws_subnet_cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

aws_ami           = "ami-00f815702af6b8889" # ECS optimised Amazon Linux.
aws_instance_type = "t2.micro"

aws_autoscaling_group_min_size         = 1
aws_autoscaling_group_max_size         = 3
aws_autoscaling_group_desired_capacity = 3

environment_name = "example"
