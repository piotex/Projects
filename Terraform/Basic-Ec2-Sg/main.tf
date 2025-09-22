provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-kubon-tech"
    key            = "terraform/states/test.tfstate"
    region         = "eu-central-1"
    # dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}


variable "vpc_id" {
    default = "vpc-0bc74542e890accc2"
}

variable "ec2_ami" {
    default = "ami-0444794b421ec32e4"
}


resource "aws_security_group" "http_security_group" {
    name        = "http-sg"
    vpc_id      = var.vpc_id

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

resource "aws_instance" "http_ec2" {
    ami                 = var.ec2_ami
    instance_type       = "t3.micro"
    security_groups     = [ aws_security_group.http_security_group.name ]

    user_data = <<-EOF
            #!/bin/bash
            yum update -y
            yum install -y httpd
            systemctl enable httpd
            systemctl start httpd
            echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
            EOF
}


output "instance_public_ip" {
  value       = aws_instance.http_ec2.public_ip
}

output "instance_id" {
  value       = aws_instance.http_ec2.id
}