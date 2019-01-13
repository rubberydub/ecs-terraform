#
# ecs-service.tf
#
# Example ECS service.
#

resource "aws_cloudwatch_log_group" "kong-postgres-log-group" {
  name  = "${var.environment_name}-kong-postgres-log-group"

  tags {
    Name        = "${var.environment_name}-kong-postgres-log-group"
    Environment = "${var.environment_name}"
  }
}

resource "aws_cloudwatch_log_group" "kong-log-group" {
  name  = "${var.environment_name}-kong-log-group"

  tags {
    Name        = "${var.environment_name}-kong-log-group"
    Environment = "${var.environment_name}"
  }
}

resource "aws_ecs_task_definition" "task-definition" {
  family                = "kong"
  container_definitions = "${file("container-definitions.json")}"
  network_mode          = "host"
}

resource "aws_ecs_service" "service" {
  name            = "kong-service"
  desired_count   = "1"
  task_definition = "${aws_ecs_task_definition.task-definition.arn}"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
}

resource "aws_elb" "kong_elb" {
  name                      = "${var.environment_name}-kong-elb"
  subnets                   = ["${aws_subnet.subnet.*.id}"]
  instances                 = ["${data.aws_instance.autoscaling-group-instances.*.id}"]
  cross_zone_load_balancing = true
  security_groups           = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = "8000"
    instance_protocol = "http"
    lb_port           = "80"
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    timeout             = "3"
    interval            = "10"
    target              = "HTTP:8001/status"
  }

  tags {
    Name        = "${var.environment_name}-kong-elb"
    Environment = "${var.environment_name}"
  }
}

resource "aws_elb" "kong_admin_elb" {
  name                      = "${var.environment_name}-kong-admin-elb"
  subnets                   = ["${aws_subnet.subnet.*.id}"]
  instances                 = ["${data.aws_instance.autoscaling-group-instances.*.id}"]
  cross_zone_load_balancing = true
  security_groups           = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = "8001"
    instance_protocol = "http"
    lb_port           = "80"
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    timeout             = "3"
    interval            = "10"
    target              = "HTTP:8001/status"
  }

  tags {
    Name        = "${var.environment_name}-kong-elb"
    Environment = "${var.environment_name}"
  }
}

output "kong-dns" {
  value = "${aws_elb.kong_elb.dns_name}"
}

output "kong-admin-dns" {
  value = "${aws_elb.kong_admin_elb.dns_name}"
}
