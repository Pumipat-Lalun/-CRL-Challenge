variable "name_prefix" {
  type = string
}

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "database_name" {
  type = string
}

variable "master_username" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "max_allocated_storage" {
  type = number
}

variable "multi_az" {
  type = bool
}

variable "backup_retention_period" {
  type = number
}

variable "apply_immediately" {
  type = bool
}

variable "deletion_protection" {
  type = bool
}

variable "skip_final_snapshot" {
  type = bool
}

variable "final_snapshot_identifier" {
  type     = string
  default  = null
  nullable = true
}

variable "performance_insights_enabled" {
  type = bool
}
