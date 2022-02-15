output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "arn" {
  value = "${aws_vpc.main.arn}"
}

output "vpc_cidr_block" {
  value = "${aws_vpc.main.cidr_block}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public.*.id}"
}

output "private_subnet_id" {
  value = "${aws_subnet.main.*.id}"
}

output "owner_id" {
  value = "${aws_vpc.main.owner_id}"
}

output "internal-sg" {
  value = "${aws_security_group.allow-internal.id}"
}
