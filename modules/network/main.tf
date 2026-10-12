locals {
  subnets = {
    for index, az in var.availability_zones : tostring(index) => {
      availability_zone = az
      public_cidr       = var.public_subnet_cidrs[index]
      private_app_cidr  = var.private_app_subnet_cidrs[index]
      private_db_cidr   = var.private_db_subnet_cidrs[index]
    }
  }

  nat_gateway_keys = var.single_nat_gateway ? toset(["0"]) : toset(keys(local.subnets))
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.public_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${each.value.availability_zone}"
    Tier = "public"
  }
}

resource "aws_subnet" "private_app" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.private_app_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-app-${each.value.availability_zone}"
    Tier = "private-app"
  }
}

resource "aws_subnet" "private_db" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.private_db_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-db-${each.value.availability_zone}"
    Tier = "isolated-db"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = local.nat_gateway_keys

  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip-${each.key}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_gateway_keys

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.name_prefix}-nat-${each.key}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_app" {
  for_each = local.subnets

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-app-rt-${each.key}"
  }
}

resource "aws_route" "private_app_internet" {
  for_each = local.subnets

  route_table_id         = aws_route_table.private_app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? "0" : each.key].id
}

resource "aws_route_table_association" "private_app" {
  for_each = local.subnets

  subnet_id      = aws_subnet.private_app[each.key].id
  route_table_id = aws_route_table.private_app[each.key].id
}

resource "aws_route_table" "private_db" {
  for_each = local.subnets

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-db-rt-${each.key}"
  }
}

resource "aws_route_table_association" "private_db" {
  for_each = local.subnets

  subnet_id      = aws_subnet.private_db[each.key].id
  route_table_id = aws_route_table.private_db[each.key].id
}
