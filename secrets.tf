# Random password generation
resource "random_password" "db_password" {
  length  = 32
  special = true
  # Exclude problematic characters that may cause issues
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# AWS Secrets Manager secret for RDS password
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.organization_name}/rds/mysql/admin-password"
  description             = "RDS MySQL admin password for ${var.organization_name}"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.organization_name}-db-password"
  }
}

# Store the password in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# Secrets Manager secret for RDS connection string
resource "aws_secretsmanager_secret" "db_connection" {
  name                    = "${var.organization_name}/rds/mysql/connection"
  description             = "RDS MySQL connection string for ${var.organization_name}"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.organization_name}-db-connection"
  }

  depends_on = [aws_secretsmanager_secret_version.db_password]
}

# Store the connection string in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_connection" {
  secret_id = aws_secretsmanager_secret.db_connection.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
    engine   = "mysql"
    host     = aws_db_instance.mysql_db.address
    port     = 3306
    dbname   = "myappdb"
  })

  depends_on = [aws_db_instance.mysql_db]
}

# Outputs
output "db_password_secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "ARN of the RDS password secret"
}

output "db_password_secret_id" {
  value       = aws_secretsmanager_secret.db_password.id
  description = "ID of the RDS password secret"
}

output "db_connection_secret_arn" {
  value       = aws_secretsmanager_secret.db_connection.arn
  description = "ARN of the RDS connection string secret"
}

output "db_connection_secret_id" {
  value       = aws_secretsmanager_secret.db_connection.id
  description = "ID of the RDS connection string secret"
}
