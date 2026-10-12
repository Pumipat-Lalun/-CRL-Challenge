resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Public access to the Metabase load balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}

resource "aws_security_group" "metabase" {
  name        = "${var.name_prefix}-metabase-sg"
  description = "Traffic between the load balancer and Metabase tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-metabase-sg"
  }
}

resource "aws_security_group" "postgres" {
  name        = "${var.name_prefix}-postgres-sg"
  description = "PostgreSQL access from Metabase tasks only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-postgres-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_alb_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = var.enable_https ? toset(var.allowed_alb_cidrs) : toset([])

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_metabase" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Metabase application traffic"
  referenced_security_group_id = aws_security_group.metabase.id
  from_port                    = var.metabase_port
  to_port                      = var.metabase_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "metabase_from_alb" {
  security_group_id            = aws_security_group.metabase.id
  description                  = "Application traffic from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.metabase_port
  to_port                      = var.metabase_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "metabase_https" {
  security_group_id = aws_security_group.metabase.id
  description       = "HTTPS for image pulls and AWS APIs"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "metabase_dns_udp" {
  security_group_id = aws_security_group.metabase.id
  description       = "DNS over UDP"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "metabase_dns_tcp" {
  security_group_id = aws_security_group.metabase.id
  description       = "DNS over TCP"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "metabase_to_postgres" {
  security_group_id            = aws_security_group.metabase.id
  description                  = "PostgreSQL application database"
  referenced_security_group_id = aws_security_group.postgres.id
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_metabase" {
  security_group_id            = aws_security_group.postgres.id
  description                  = "PostgreSQL from Metabase tasks"
  referenced_security_group_id = aws_security_group.metabase.id
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
}
