module "network" {
  source = "./modules/network"

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.network.vpc_cidr
  availability_zones       = var.network.availability_zones
  public_subnet_cidrs      = var.network.public_subnet_cidrs
  private_app_subnet_cidrs = var.network.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.network.private_db_subnet_cidrs
  single_nat_gateway       = var.network.single_nat_gateway
}

module "security" {
  source = "./modules/security"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  allowed_alb_cidrs = var.alb.allowed_cidr_blocks
  enable_https      = try(var.alb.certificate_arn != null && var.alb.certificate_arn != "", false)
  metabase_port     = 3000
  postgres_port     = 5432
}

module "alb" {
  source = "./modules/alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  target_port       = 3000
  certificate_arn   = try(var.alb.certificate_arn, null)
  idle_timeout      = var.alb.idle_timeout
}

module "postgres" {
  source = "./modules/rds-postgresql"

  name_prefix                  = local.name_prefix
  private_db_subnet_ids        = module.network.private_db_subnet_ids
  security_group_id            = module.security.postgres_security_group_id
  database_name                = "metabase"
  master_username              = "metabase_admin"
  engine_version               = var.postgres.engine_version
  instance_class               = var.postgres.instance_class
  allocated_storage            = var.postgres.allocated_storage
  max_allocated_storage        = var.postgres.max_allocated_storage
  multi_az                     = var.postgres.multi_az
  backup_retention_period      = var.postgres.backup_retention_period
  apply_immediately            = var.postgres.apply_immediately
  deletion_protection          = var.postgres.deletion_protection
  skip_final_snapshot          = var.postgres.skip_final_snapshot
  final_snapshot_identifier    = try(var.postgres.final_snapshot_identifier, null)
  performance_insights_enabled = var.postgres.performance_insights_enabled
}

module "ecs_metabase" {
  source = "./modules/ecs-metabase"

  name_prefix                       = local.name_prefix
  aws_region                        = var.aws_region
  private_app_subnet_ids            = module.network.private_app_subnet_ids
  security_group_id                 = module.security.metabase_security_group_id
  target_group_arn                  = module.alb.target_group_arn
  container_image                   = var.metabase.image
  container_port                    = 3000
  task_cpu                          = var.metabase.cpu
  task_memory                       = var.metabase.memory
  desired_count                     = var.metabase.desired_count
  log_retention_days                = var.metabase.log_retention_days
  health_check_grace_period_seconds = var.metabase.health_check_grace_period_seconds
  db_host                           = module.postgres.address
  db_port                           = module.postgres.port
  db_name                           = module.postgres.database_name
  db_username                       = module.postgres.master_username
  db_secret_arn                     = module.postgres.master_user_secret_arn

  depends_on = [module.alb]
}
