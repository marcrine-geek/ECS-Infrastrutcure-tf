# Application Load Balancer for Backend (Internal)
resource "aws_lb" "backend_alb" {
  name               = "${var.organization_name}-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_alb_sg.id]
  subnets            = [aws_subnet.private-a1.id, aws_subnet.private-b1.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.organization_name}-backend-alb"
  }
}

# Target Group for Backend ALB
resource "aws_lb_target_group" "backend_alb_tg" {
  name        = "${var.organization_name}-backend-alb-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.organization_name}-backend-alb-tg"
  }
}

# ALB Listener for Backend
resource "aws_lb_listener" "backend_alb_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_alb_tg.arn
  }
}

# Output the Backend ALB DNS name
output "backend_alb_dns_name" {
  value       = aws_lb.backend_alb.dns_name
  description = "The DNS name of the backend load balancer"
}
