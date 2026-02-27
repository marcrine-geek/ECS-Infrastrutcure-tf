# SQS Dead Letter Queue (DLQ)
resource "aws_sqs_queue" "dlq" {
  name                       = "${var.organization_name}-queue-dlq"
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 300     # 5 minutes

  tags = {
    Name = "${var.organization_name}-dlq"
  }
}

# Main SQS Queue
resource "aws_sqs_queue" "main_queue" {
  name                       = "${var.organization_name}-queue"
  visibility_timeout_seconds = 300    # 5 minutes
  message_retention_seconds  = 345600 # 4 days

  # Redrive policy - link to DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3 # Move to DLQ after 3 failed attempts
  })

  # Enable message content encryption
  kms_master_key_id = "alias/aws/sqs"

  tags = {
    Name = "${var.organization_name}-main-queue"
  }

  depends_on = [aws_sqs_queue.dlq]
}

# Queue Policy for main queue - Allow backend ECS tasks to access
resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.main_queue.arn
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = aws_vpc.vpc.id
          }
        }
      }
    ]
  })
}

# SQS Queue for Notifications (Optional secondary queue)
resource "aws_sqs_queue" "notification_dlq" {
  name                       = "${var.organization_name}-notification-queue-dlq"
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 300     # 5 minutes

  tags = {
    Name = "${var.organization_name}-notification-dlq"
  }
}

resource "aws_sqs_queue" "notification_queue" {
  name                       = "${var.organization_name}-notification-queue"
  visibility_timeout_seconds = 300    # 5 minutes
  message_retention_seconds  = 345600 # 4 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = 3
  })

  kms_master_key_id = "alias/aws/sqs"

  tags = {
    Name = "${var.organization_name}-notification-queue"
  }

  depends_on = [aws_sqs_queue.notification_dlq]
}

# Queue Policy for notification queue
resource "aws_sqs_queue_policy" "notification_queue_policy" {
  queue_url = aws_sqs_queue.notification_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.notification_queue.arn
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = aws_vpc.vpc.id
          }
        }
      }
    ]
  })
}

# CloudWatch Alarms for DLQ monitoring
resource "aws_cloudwatch_metric_alarm" "dlq_message_count" {
  alarm_name          = "${var.organization_name}-dlq-message-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when messages appear in DLQ"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  tags = {
    Name = "${var.organization_name}-dlq-alarm"
  }
}

# Outputs
output "main_queue_url" {
  value       = aws_sqs_queue.main_queue.url
  description = "The URL of the main SQS queue"
}

output "main_queue_arn" {
  value       = aws_sqs_queue.main_queue.arn
  description = "The ARN of the main SQS queue"
}

output "dlq_url" {
  value       = aws_sqs_queue.dlq.url
  description = "The URL of the DLQ"
}

output "dlq_arn" {
  value       = aws_sqs_queue.dlq.arn
  description = "The ARN of the DLQ"
}

output "notification_queue_url" {
  value       = aws_sqs_queue.notification_queue.url
  description = "The URL of the notification SQS queue"
}

output "notification_queue_arn" {
  value       = aws_sqs_queue.notification_queue.arn
  description = "The ARN of the notification SQS queue"
}

output "notification_dlq_url" {
  value       = aws_sqs_queue.notification_dlq.url
  description = "The URL of the notification DLQ"
}

output "notification_dlq_arn" {
  value       = aws_sqs_queue.notification_dlq.arn
  description = "The ARN of the notification DLQ"
}
