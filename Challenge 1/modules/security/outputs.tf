output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "metabase_security_group_id" {
  value = aws_security_group.metabase.id
}

output "postgres_security_group_id" {
  value = aws_security_group.postgres.id
}
