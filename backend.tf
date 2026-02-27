# CloudWatch Log Group for Backend ECS
resource "aws_cloudwatch_log_group" "backend_ecs_log_group" {
  name              = "/ecs/${var.organization_name}-backend"
  retention_in_days = 7

  tags = {
    Name = "${var.organization_name}-backend-ecs-logs"
  }
}

# IAM Role for Backend ECS Task Execution
resource "aws_iam_role" "backend_ecsTaskExecutionRole" {
  name = "${var.organization_name}-backend-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.organization_name}-backend-ecsTaskExecutionRole"
  }
}

# Attach the default ECS task execution policy for backend
resource "aws_iam_role_policy_attachment" "backend_ecsTaskExecutionRolePolicy" {
  role       = aws_iam_role.backend_ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for Backend ECS Task
resource "aws_iam_role" "backend_ecsTaskRole" {
  name = "${var.organization_name}-backend-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.organization_name}-backend-ecsTaskRole"
  }
}

# ECS Cluster for Backend
resource "aws_ecs_cluster" "backend_cluster" {
  name = "${var.organization_name}-backend-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.organization_name}-backend-cluster"
  }
}

# Backend ECS Task Definition
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "${var.organization_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.backend_ecsTaskExecutionRole.arn
  task_role_arn      = aws_iam_role.backend_ecsTaskRole.arn

  container_definitions = jsonencode([
    {
      name      = "${var.organization_name}-backend-container"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_ecs_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = []
    }
  ])

  tags = {
    Name = "${var.organization_name}-backend-task"
  }
}

# Backend ECS Service
resource "aws_ecs_service" "backend_service" {
  name            = "${var.organization_name}-backend-service"
  cluster         = aws_ecs_cluster.backend_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private-a2.id, aws_subnet.private-b2.id]
    security_groups  = [aws_security_group.backend_ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_alb_tg.arn
    container_name   = "${var.organization_name}-backend-container"
    container_port   = 8080
  }

  depends_on = [
    aws_lb_listener.backend_alb_listener,
    aws_iam_role_policy_attachment.backend_ecsTaskExecutionRolePolicy
  ]

  tags = {
    Name = "${var.organization_name}-backend-service"
  }
}

# Auto Scaling Target for Backend ECS Service
resource "aws_appautoscaling_target" "backend_ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.backend_cluster.name}/${aws_ecs_service.backend_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - CPU for Backend
resource "aws_appautoscaling_policy" "backend_ecs_policy_cpu" {
  name               = "${var.organization_name}-backend-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling Policy - Memory for Backend
resource "aws_appautoscaling_policy" "backend_ecs_policy_memory" {
  name               = "${var.organization_name}-backend-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}
