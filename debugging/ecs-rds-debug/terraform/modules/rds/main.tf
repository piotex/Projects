# Subnet group (wymaga co najmniej 2 AZ)
resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-${var.project_name}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.environment}-db-subnet-group" }
}

# Parameter group – tu kontrolujemy max_connections
resource "aws_db_parameter_group" "this" {
  name   = "${var.environment}-${var.project_name}-pg15"
  family = "postgres15"

  parameter {
    name         = "max_connections"
    value        = tostring(var.max_connections)
    apply_method = "pending-reboot"
  }

  # log_min_duration_statement: loguj zapytania > 500ms → widoczne w CloudWatch
  parameter {
    name         = "log_min_duration_statement"
    value        = "500"
    apply_method = "immediate"
  }

  tags = { Name = "${var.environment}-pg-params" }
}

# Security group – tylko z ECS tasks SG
resource "aws_security_group" "rds" {
  name   = "${var.environment}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "PostgreSQL from ECS tasks"
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [var.ecs_sg_id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-rds-sg" }
}

# RDS instance
resource "aws_db_instance" "this" {
  identifier        = "${var.environment}-${var.project_name}"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  # Brak publicznego dostępu – tylko przez VPC (jak w produkcji)
  publicly_accessible = false

  skip_final_snapshot       = true
  deletion_protection       = false
  backup_retention_period   = 0

  # CloudWatch – logi zapytań i błędów
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = { Name = "${var.environment}-postgres" }
}
