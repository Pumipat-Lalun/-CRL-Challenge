output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].id]
}

output "private_app_subnet_ids" {
  value = [for key in sort(keys(aws_subnet.private_app)) : aws_subnet.private_app[key].id]
}

output "private_db_subnet_ids" {
  value = [for key in sort(keys(aws_subnet.private_db)) : aws_subnet.private_db[key].id]
}
