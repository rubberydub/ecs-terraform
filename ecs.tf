#
# ecs.tf
#
# AWS ECS cluster, supporting infrastructure ans services.
#

provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
}

#
# IAM resources.
#

data "aws_iam_policy" "instance-iam-policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy" "autoscale-iam-policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

data "aws_iam_policy" "service-iam-policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role" "instance-iam-role" {
  name               = "ecsInstanceRole"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": ["ecs.amazonaws.com","ec2.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "autoscale-iam-role" {
  name               = "ecsAutoscaleRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "service-iam-role" {
  name               = "ecsServiceRole"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance-iam-role-policy-attachment" {
  role       = "${aws_iam_role.instance-iam-role.name}"
  policy_arn = "${data.aws_iam_policy.instance-iam-policy.arn}"
}

resource "aws_iam_role_policy_attachment" "autoscale-iam-role-policy-attachment" {
  role       = "${aws_iam_role.autoscale-iam-role.name}"
  policy_arn = "${data.aws_iam_policy.autoscale-iam-policy.arn}"
}

resource "aws_iam_role_policy_attachment" "service-iam-role-policy-attachment" {
  role       = "${aws_iam_role.service-iam-role.name}"
  policy_arn = "${data.aws_iam_policy.service-iam-policy.arn}"
}

resource "aws_iam_instance_profile" "instance-profile" {
  name = "ecsInstanceProfile"
  role = "${aws_iam_role.instance-iam-role.name}"
}

resource "aws_key_pair" "key-pair" {
  key_name   = "${var.aws_key_pair_name}"
  public_key = "${file(var.ssh_key)}"
}

#
# VPC resources.
#

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name        = "${var.environment_name}-vpc"
    Environment = "${var.environment_name}"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment_name}-internet-gateway"
    Environment = "${var.environment_name}"
  }
}

resource "aws_subnet" "subnet" {
  count             = "${length(var.aws_availability_zones)}"
  vpc_id            = "${aws_vpc.vpc.id}"
  availability_zone = "${element(var.aws_availability_zones, count.index)}"
  cidr_block        = "${element(var.aws_subnet_cidr_blocks, count.index)}"

  tags {
    Name        = "${var.environment_name}-${element(var.aws_availability_zones, count.index)}-subnet"
    Environment = "${var.environment_name}"
  }
}

resource "aws_route_table" "route-table" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet-gateway.id}"
  }

  tags {
    Name        = "${var.environment_name}-route-table"
    Environment = "${var.environment_name}"
  }
}

resource "aws_route_table_association" "route-table-association" {
  count          = "${length(var.aws_availability_zones)}"
  subnet_id      = "${element(aws_subnet.subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.route-table.id}"
}

resource "aws_security_group" "elb" {
  name   = "${var.environment_name}-elb-security-group"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    description = "Allow TCP port 80 (HTTP) from anywhere."
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }

  ingress {
    description = "Allow TCP port 443 (HTTPS) from anywhere."
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }

  tags {
    Name        = "${var.environment_name}-elb-security-group"
    Environment = "${var.environment_name}"
  }
}

resource "aws_security_group" "ecs-cluster" {
  name   = "${var.environment_name}-ecs-cluster-security-group"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    description = "Allow all traffic from self."
    self        = true
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  ingress {
    description     = "Allow all traffic from ELB security group."
    security_groups = ["${aws_security_group.elb.id}"]
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
  }

  ingress {
    description = "Allow ping from trusted networks."
    cidr_blocks = "${var.trusted_networks_cidr_blocks}"
    protocol    = "icmp"
    from_port   = 8
    to_port     = -1
  }

  ingress {
    description = "Allow pong from trusted networks."
    cidr_blocks = "${var.trusted_networks_cidr_blocks}"
    protocol    = "icmp"
    from_port   = 0
    to_port     = -1
  }

  ingress {
    description = "Allow path MTU discovery from trusted networks."
    cidr_blocks = "${var.trusted_networks_cidr_blocks}"
    protocol    = "icmp"
    from_port   = 3
    to_port     = 4
  }

  ingress {
    description = "Allow TCP port 22 (SSH) from trusted networks."
    cidr_blocks = "${var.trusted_networks_cidr_blocks}"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  egress {
    description = "Allow all traffic."
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags {
    Name        = "${var.environment_name}-ecs-cluster-security-group"
    Environment = "${var.environment_name}"
  }
}

#
# EC2 and ECS resources.
#

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${var.environment_name}-ecs-cluster"

  tags {
    Name        = "${var.environment_name}-ecs-cluster"
    Environment = "${var.environment_name}"
  }
}

data "template_file" "user-data" {
  template = "${file("templates/user-data.tpl")}"

  vars {
    cluster_name = "${var.environment_name}-ecs-cluster"
  }
}

resource "aws_launch_configuration" "launch-configuration" {
  name                        = "${var.environment_name}-launch-configuration"
  instance_type               = "${var.aws_instance_type}"
  image_id                    = "${var.aws_ami}"
  key_name                    = "${aws_key_pair.key-pair.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.instance-profile.name}"
  security_groups             = ["${aws_security_group.ecs-cluster.id}"]
  associate_public_ip_address = true
  user_data                   = "${data.template_file.user-data.rendered}"
}

resource "aws_autoscaling_group" "autoscaling-group" {
  name                 = "${var.environment_name}-autoscaling-group"
  launch_configuration = "${aws_launch_configuration.launch-configuration.name}"
  availability_zones   = "${var.aws_availability_zones}"
  vpc_zone_identifier  = ["${aws_subnet.subnet.*.id}"]
  health_check_type    = "EC2"
  min_size             = "${var.aws_autoscaling_group_min_size}"
  max_size             = "${var.aws_autoscaling_group_max_size}"
  desired_capacity     = "${var.aws_autoscaling_group_desired_capacity}"

  tag {
    key                 = "Name"
    value               = "${var.environment_name}-autoscaling-group"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment_name}"
    propagate_at_launch = true
  }
}

#
# Get the IPs of the ASG instances for the SSH config.
# This must be done in this round about way, see:
# https://github.com/terraform-providers/terraform-provider-aws/issues/511
#

data "aws_instances" "instances" {
  depends_on = [ "aws_autoscaling_group.autoscaling-group" ]

  instance_tags {
    Environment = "${var.environment_name}"
  }
}

data "aws_instance" "autoscaling-group-instances" {
  count       = "${var.aws_autoscaling_group_desired_capacity}"
  depends_on  = ["data.aws_instances.instances"]
  instance_id = "${data.aws_instances.instances.ids[count.index]}"
}

#
# SSH config.
#

data "template_file" "ssh-config-instance" {
  template = "${file("templates/ssh-config-instance.tpl")}"
  count    = "${var.aws_autoscaling_group_desired_capacity}"

  vars {
    index            = "${count.index}"
    ip               = "${element(data.aws_instance.autoscaling-group-instances.*.public_ip, count.index)}"
    environment_name = "${var.environment_name}"
    user             = "${var.aws_default_user}"
  }
}

data "template_file" "ssh-config" {
  template = "$${value}\n"

  vars {
    value = "${join("\n", data.template_file.ssh-config-instance.*.rendered)}"
  }
}

#
# ECS services.
#

resource "aws_cloudwatch_log_group" "log-group" {
  count = "${length(var.log_groups)}"
  name  = "${var.environment_name}-${element(var.log_groups, count.index)}-log-group"

  tags {
    Name        = "${var.environment_name}-${element(var.log_groups, count.index)}-log-group"
    Environment = "${var.environment_name}"
  }
}

resource "aws_ecs_task_definition" "task-definition" {
  count                 = "${length(var.ecs_services)}"
  family                = "${lookup(var.ecs_services[count.index], "family")}"
  container_definitions = "${file(lookup(var.ecs_services[count.index], "container_definitions_file"))}"
}

resource "aws_ecs_service" "service" {
  count           = "${length(var.ecs_services)}"
  name            = "${lookup(var.ecs_services[count.index], "name")}"
  desired_count   = "${lookup(var.ecs_services[count.index], "count")}"
  task_definition = "${element(aws_ecs_task_definition.task-definition.*.arn, count.index)}"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  # iam_role        = "${aws_iam_role.service-iam-role.arn}"
}
