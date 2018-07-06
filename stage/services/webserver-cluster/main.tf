provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "all" {}

#defining template_file data source which as two parameters; the template parameter, 
#which is a string, and the vars parameters whic is map of variables

data "template_file" "user_data" {
  template = "${file("user-data.sh")}"

  vars {
    server_port = "${var.server_port}"
    db_address  = "${data.terraform_remote_state.db.address}"
    db_port     = "${data.terraform_remote_state.db.port}"
  }
}

resource "aws_launch_configuration" "web_example" {
  #count         = 3
  image_id      = "ami-2d39803a"
  instance_type = "t2.micro"

  #interpolation implicitly calling security group
  security_groups = ["${aws_security_group.instance-sg.id}"]

  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance-sg" {
  name = "terraform-web-example-instance-sg"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_example" {
  launch_configuration = "${aws_launch_configuration.web_example.id}"

  #availability_zones = ["${data.aws_availability_zones.all.names}"]
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  load_balancers     = ["${aws_elb.web_example.name}"]
  health_check_type  = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-web-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "web_example" {
  name               = "terraform-asg-web-example"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.elb-sg.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb-sg" {
  name = "terraform-web-example-elb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Get the web server cluster code to read the data from this state file
#by adding the terraform_remote_state data source

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "gb1-master-tf-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-1"
  }
}

terraform {
  backend "s3" {
    bucket         = "gb1-master-tf-state"
    key            = "stage/services/webserver-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
