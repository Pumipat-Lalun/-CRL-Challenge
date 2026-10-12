variable "aws_region" {
  description = "AWS Region in which the stack is deployed."
  type        = string
}

variable "project_name" {
  description = "Short project identifier used in resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.project_name))
    error_message = "project_name must be 2-16 lowercase alphanumeric or hyphen characters and start with a letter."
  }
}

variable "environment" {
  description = "Deployment environment name, for example dev, uat, or prod."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,7}$", var.environment))
    error_message = "environment must be 2-8 lowercase alphanumeric or hyphen characters and start with a letter."
  }
}

variable "tags" {
  description = "Additional tags applied to all supported AWS resources."
  type        = map(string)
  default     = {}
}

variable "network" {
  description = "VPC, Availability Zone, subnet, and NAT configuration."
  type = object({
    vpc_cidr                 = string
    availability_zones       = list(string)
    public_subnet_cidrs      = list(string)
    private_app_subnet_cidrs = list(string)
    private_db_subnet_cidrs  = list(string)
    single_nat_gateway       = bool
  })

  validation {
    condition = (
      length(var.network.availability_zones) >= 2 &&
      length(var.network.public_subnet_cidrs) == length(var.network.availability_zones) &&
      length(var.network.private_app_subnet_cidrs) == length(var.network.availability_zones) &&
      length(var.network.private_db_subnet_cidrs) == length(var.network.availability_zones)
    )
    error_message = "Use at least two Availability Zones and provide one public, private app, and private DB subnet CIDR per Availability Zone."
  }
}

variable "alb" {
  description = "Application Load Balancer configuration."
  type = object({
    allowed_cidr_blocks = list(string)
    certificate_arn     = optional(string)
    idle_timeout        = number
  })

  validation {
    condition     = length(var.alb.allowed_cidr_blocks) > 0
    error_message = "alb.allowed_cidr_blocks must contain at least one IPv4 CIDR."
  }
}

variable "metabase" {
  description = "Metabase ECS Fargate configuration."
  type = object({
    image                             = string
    cpu                               = number
    memory                            = number
    desired_count                     = number
    log_retention_days                = number
    health_check_grace_period_seconds = number
  })

  validation {
    condition     = var.metabase.desired_count >= 1
    error_message = "metabase.desired_count must be at least 1."
  }
}

variable "postgres" {
  description = "RDS for PostgreSQL application database configuration."
  type = object({
    engine_version               = string
    instance_class               = string
    allocated_storage            = number
    max_allocated_storage        = number
    multi_az                     = bool
    backup_retention_period      = number
    apply_immediately            = bool
    deletion_protection          = bool
    skip_final_snapshot          = bool
    final_snapshot_identifier    = optional(string)
    performance_insights_enabled = bool
  })

  validation {
    condition = (
      var.postgres.allocated_storage >= 20 &&
      (
        var.postgres.max_allocated_storage == 0 ||
        var.postgres.max_allocated_storage >= var.postgres.allocated_storage
      )
    )
    error_message = "postgres.allocated_storage must be at least 20 GiB; max_allocated_storage must be 0 or greater than or equal to allocated_storage."
  }

  validation {
    condition     = var.postgres.skip_final_snapshot || try(length(var.postgres.final_snapshot_identifier) > 0, false)
    error_message = "postgres.final_snapshot_identifier is required when skip_final_snapshot is false."
  }
}
