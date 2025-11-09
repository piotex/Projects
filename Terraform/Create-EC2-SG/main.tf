

resource "aws_security_group" "web_ec2_sg" {
  name   = "web_ec2_sg"
  vpc_id = var.vpc_id

  # Allow HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_ec2" {
    ami                 = var.ec2_ami
    instance_type       = var.ec2_instance_type
    security_groups     = [ aws_security_group.web_ec2_sg.name ]
    key_name            = var.ec2_key_name
    
    user_data = <<-EOF
            #!/bin/bash
            yum update -y
            yum install -y httpd
            systemctl enable httpd
            systemctl start httpd
            echo "<h1>Subscribe KubonTech :D</h1>" > /var/www/html/index.html
            EOF
}


