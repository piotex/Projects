# === AMI =====================================================================
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["137112412989"]       # Amazon Linux 2023 AMI owner ID

  filter {
    name = "name"
    values = ["al2023-ami-*"]
  }
}


# === IAM =====================================================================
resource "aws_iam_role" "ec2_ecr_role" {
  name = "${var.environment}-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-ec2-ecr-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "ecr_pull" {
  name = "${var.environment}-ecr-pull-policy"
  role = aws_iam_role.ec2_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_ecr_role.name
}


# === SECURITY GROUP =====================================================================
resource "aws_security_group" "this" {
  name   = "${var.environment}-ec2-sg"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5000
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  key_name = var.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"

    delete_on_termination = true
  }

  tags = {
    Name = "${var.environment}-app"
  }
}