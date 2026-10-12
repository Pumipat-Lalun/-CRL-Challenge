variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "target_port" {
  type = number
}

variable "certificate_arn" {
  type     = string
  default  = null
  nullable = true
}

variable "idle_timeout" {
  type = number
}
