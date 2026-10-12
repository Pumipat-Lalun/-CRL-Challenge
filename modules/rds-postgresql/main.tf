resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-subnets"
  }
}

resource "aws_db_instance" "this" {
  identifier = substr("${var.name_prefix}-postgres", 0, 63)

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username
  port     = 5432

  manage_master_user_password = true

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = "18:00-19:00"
  maintenance_window      = "Sun:19:00-Sun:20:00"

  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately
  copy_tags_to_snapshot      = true

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier

  lifecycle {
    precondition {
      condition     = var.skip_final_snapshot || (var.final_snapshot_identifier != null && var.final_snapshot_identifier != "")
      error_message = "final_snapshot_identifier must be set when skip_final_snapshot is false."
    }
  }

  tags = {
    Name = "${var.name_prefix}-postgres"
  }
}
