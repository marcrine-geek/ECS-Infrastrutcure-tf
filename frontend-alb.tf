# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.organization_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public-a.id, aws_subnet.public-b.id]

  enable_deletion_protection = true

  tags = {
    Name = "${var.organization_name}-alb"
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.organization_name}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name = "${var.organization_name}-frontend-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}



# Output the ALB DNS name
output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "The DNS name of the load balancer"
}
