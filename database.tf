# KMS Key for RDS Encryption
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${var.organization_name}-rds-key"
  }
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/${var.organization_name}-rds"
  target_key_id = aws_kms_key.rds_key.key_id
}

# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.organization_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private-a3.id, aws_subnet.private-b3.id]

  tags = {
    Name = "${var.organization_name}-db-subnet-group"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql_db" {
  identifier        = "${var.organization_name}-mysql-db"
  engine            = "mysql"
  engine_version    = "8.0.35"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_key.arn

  db_name  = "myappdb"
  username = "admin"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Backup and Maintenance
  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  copy_tags_to_snapshot   = true

  # High Availability
  multi_az = true

  # Performance and Monitoring
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  enabled_cloudwatch_logs_exports       = ["error", "general", "slowquery"]

  # Delete Protection
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.organization_name}-mysql-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name = "${var.organization_name}-mysql-db"
  }

  depends_on = [
    aws_db_subnet_group.db_subnet_group,
    aws_security_group.rds_sg
  ]
}

# RDS Read Replica
resource "aws_db_instance" "mysql_read_replica" {
  identifier          = "${var.organization_name}-mysql-read-replica"
  replicate_source_db = aws_db_instance.mysql_db.identifier
  instance_class      = "db.t3.micro"
  storage_encrypted   = true
  kms_key_id          = aws_kms_key.rds_key.arn

  # Place read replica in different AZ
  availability_zone = "${var.region}b"

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.organization_name}-mysql-replica-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name = "${var.organization_name}-mysql-read-replica"
  }

  depends_on = [
    aws_db_instance.mysql_db
  ]
}

# Outputs
output "db_endpoint" {
  value       = aws_db_instance.mysql_db.endpoint
  description = "The connection endpoint for the database"
}

output "db_name" {
  value       = aws_db_instance.mysql_db.db_name
  description = "The name of the database"
}

output "db_username" {
  value       = aws_db_instance.mysql_db.username
  description = "The database admin username"
  sensitive   = true
}

output "read_replica_endpoint" {
  value       = aws_db_instance.mysql_read_replica.endpoint
  description = "The connection endpoint for the read replica"
}
