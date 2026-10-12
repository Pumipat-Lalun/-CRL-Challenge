variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_alb_cidrs" {
  type = list(string)
}

variable "enable_https" {
  type = bool
}

variable "metabase_port" {
  type = number
}

variable "postgres_port" {
  type = number
}
