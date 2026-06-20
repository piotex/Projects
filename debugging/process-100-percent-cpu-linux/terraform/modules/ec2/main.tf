data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["137112412989"]       # Amazon Linux 2023 AMI owner ID

  filter {
    name = "name"
    values = ["al2023-ami-*"]
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  key_name = var.key_name

  tags = {
    Name = "${var.environment}-app"
  }
}