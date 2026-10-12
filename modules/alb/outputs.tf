output "target_group_arn" {
  value = aws_lb_target_group.metabase.arn
}

output "dns_name" {
  value = aws_lb.this.dns_name
}

output "url" {
  value = "${local.enable_https ? "https" : "http"}://${aws_lb.this.dns_name}"
}
