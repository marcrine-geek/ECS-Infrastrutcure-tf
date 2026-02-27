# Security Group for frontend ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.organization_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.organization_name}-alb-sg"
  }
}

# Security Group for Frontend ECS Tasks
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.organization_name}-frontend-ecs-tasks-sg"
  description = "Security group for frontend ECS tasks"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.organization_name}-frontend-ecs-tasks-sg"
  }
}

# Security Group for Backend ALB
resource "aws_security_group" "backend_alb_sg" {
  name        = "${var.organization_name}-backend-alb-sg"
  description = "Security group for backend ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.organization_name}-backend-alb-sg"
  }
}

# Security Group for Backend ECS Tasks
resource "aws_security_group" "backend_ecs_tasks_sg" {
  name        = "${var.organization_name}-backend-ecs-tasks-sg"
  description = "Security group for backend ECS tasks"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.organization_name}-backend-ecs-tasks-sg"
  }
}

# Security Group for RDS Database
resource "aws_security_group" "rds_sg" {
  name        = "${var.organization_name}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id, aws_security_group.backend_ecs_tasks_sg.id]
    description     = "MySQL access from ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.organization_name}-rds-sg"
  }
}