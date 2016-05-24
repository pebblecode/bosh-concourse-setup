output "security_group_id" {
    value = "${aws_security_group.boshdefault.id}"
}

output "subnet_id" {
    value = "${aws_subnet.default.id}"
}

output "inception_host_ip" {
  value = "${aws_instance.inception.public_ip}"
}
