# Create an ELB security group
resource "aws_security_group" "elbgroup" {
  name        = "elbgroup"
  description = "ELB security group"
  vpc_id      = "${aws_vpc.default.id}"
  tags {
  Name = "elbgroup"
  component = "concourse"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound https
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound https
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create a new load balancer
resource "aws_elb" "concourse" {
  name = "concourse-elb"
  subnets = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elbgroup.id}"]

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  /*listener {*/
    /*instance_port = 8080*/
    /*instance_protocol = "http"*/
    /*lb_port = 443*/
    /*lb_protocol = "https"*/
    /*ssl_certificate_id = "${var.ssl_cert_arn}"*/
/*}*/

  listener {
    instance_port = 2222
    instance_protocol = "tcp"
    lb_port = 2222
    lb_protocol = "tcp"
  }

  tags {
  component = "concourse"
  }
}

# Create a CNAME record
resource "aws_route53_record" "concourse" {
   zone_id = "${var.ci_dns_zone_id}"
   name = "${var.ci_hostname}"
   type = "CNAME"
   ttl = "300"
   records = ["${aws_elb.concourse.dns_name}"]
}
