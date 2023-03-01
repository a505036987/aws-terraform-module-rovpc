output "vpc_id" {
  value = aws_vpc.wssdev-vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.publicsub.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.privatesub.*.id
}

output "public_route_table_id" {
  value = aws_route_table.rt_public.id
}

output "private_route_table_ids" {
  value = aws_route_table.rt_private.*.id
}
