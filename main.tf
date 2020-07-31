terraform {
	required_version = ">= 0.12"
}

provider "aws" {
	region = "us-east-2"
}

resource "aws_security_group" "instance" {
	name = "terraform-example-instance"

	ingress {
		from_port		= var.server_port
		to_port			= var.server_port
		protocol		= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "example" {
	ami						= "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
	vpc_security_group_ids = [aws_security_group.instance.id]

	user_data = <<-EOF
							#!/bin/bash
							echo "Hello, world!" > index.html
							nohup busybox httpd -f -p "${var.server_port}" &
							EOF


	tags = {
		Name = "terraform-example"
	}
}

resource "aws_launch_configuration" "example" {
	image_id						= "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
	security_groups = [aws_security_group.instance.id]

	user_data = <<-EOF
							#!/bin/bash
							echo "Hello, world!" > index.html
							nohup busybox httpd -f -p "${var.server_port}" &
							EOF
	
	lifecycle {
		create_before_destroy = true
	}
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "example" {
	launch_configuration = aws_launch_configuration.example.id
	availability_zones  = data.aws_availability_zones.all.names

	min_size = 2
	max_size = 10

	load_balancers 		= [aws_elb.example.name]
	health_check_type = "ELB"

	tag {
		key									= "Name"
		value								= "terraform-asg-example"
		propagate_at_launch = true
	}
}

resource "aws_elb" "example" {
	name								= "terraform-asg-example"
	security_groups			= [aws_security_group.elb.id]
	availability_zones	= data.aws_availability_zones.all.names

	health_check {
		target							= "HTTP:${var.server_port}/"
		interval						= 30
		timeout							= 3
		healthy_threshold		= 2
		unhealthy_threshold = 2
	}

	# listeners
	listener {
		lb_port						= var.elb_port
		lb_protocol				= "http"
		instance_port 		= var.server_port
		instance_protocol = "http"
	}
}

resource "aws_security_group" "elb" {
	name = "terraform-example-elb"

	egress {
		from_port			= 0
		to_port				= 0
		protocol			= "-1"
		cidr_blocks		= ["0.0.0.0/0"]
	}

	ingress {
		from_port			= var.elb_port
		to_port				= var.elb_port
		protocol			= "tcp"
		cidr_blocks		= ["0.0.0.0/0"]
	}
}

resource "aws_s3_bucket" "jgipsonterraformstatebackup" {
  bucket = "jgipsonterraformstatebackup"

  # enable versioning, full revision history of state files
  versioning {
    enabled = true
  }

  # enable server side encrytion as default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name                = "terraform-up-and-running-locks"
  billing_mode        = "PAY_PER_REQUEST"
  hash_key            = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_db_instance" "example" {
	identifier_prefix			= "terraform-up-and-running"
	engine							=	"mysql"
	allocated_storage		= 10
	instance_class			= "db.t2.micro"
	name								=	"example_database"
	username						=	"admin"
	password 						= "password"
}

terraform {
  backend "s3" {
    bucket = "jgipsonterraformstatebackup"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}
