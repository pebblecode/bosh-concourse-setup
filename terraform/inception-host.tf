resource "aws_security_group" "inception_host" {
  name        = "inceptionhost"
  description = "Bosh Director Access"
  vpc_id      = "${aws_vpc.default.id}"

  tags = {
    Name      = "inception-host"
    component = "bosh-director"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The bosh inception host

resource "template_file" "inception_init" {
  template = "${file("${path.module}/inception-host.tpl")}"
}

resource "template_file" "bosh_init" {
  template = "${file("${path.module}/bosh_init.sh")}"
}

resource "template_file" "director" {
  template = "${file("${path.module}/director.yaml.tpl")}"

  vars {
    availability_zone                  = "${aws_subnet.default.availability_zone}"
    subnet_cidr                        = "${aws_subnet.default.cidr_block}"
    subnet_id                          = "${aws_subnet.default.id}"
    director_iam_instance_profile_name = "director"
    bosh_password                      = "${var.bosh_password}"
    aws_region                         = "${var.aws_region}"
    provisioned_private_key_path       = "./bosh.pem"
    security_group                     = "${aws_security_group.boshdefault.id}"
    key_name                           = "${aws_key_pair.admin.key_name}"
  }
}

resource "template_cloudinit_config" "inception_host" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${template_file.inception_init.rendered}"
  }

  part {
    content_type = "text/cloud-config"
    content      = "${template_file.director.rendered}"
  }

  part {
    filename     = "02bosh_init.sh"
    content_type = "text/x-shellscript"
    content      = "${template_file.bosh_init.rendered}"
  }

  part {
    filename     = "03bosh_cli_init.sh"
    content_type = "text/x-shellscript"
    content      = "#!/bin/bash\ngem install bosh_cli --no-rdoc --no-ri"
  }
}

resource "aws_instance" "inception" {
  ami                         = "ami-4070e433"                              # 14.04 LTS eu-west
  instance_type               = "t2.medium"
  key_name                    = "${aws_key_pair.admin.key_name}"
  monitoring                  = "false"
  vpc_security_group_ids      = ["${aws_security_group.inception_host.id}"]
  subnet_id                   = "${aws_subnet.default.id}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.director.name}"
  private_ip = "10.0.0.5"

  tags {
    Name = "Inception Host"
  }

  user_data = "${template_cloudinit_config.inception_host.rendered}"
}

resource "aws_key_pair" "admin" {
  key_name   = "build_ec2_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDI+XnMeiV5P3JLOgfpk9656mHrnLHMjFH5ShBxDRL+6wnc9uiDtXay7j1k0lhpdqQ50DyT2HmrfBpXq2l8AnzGFqjPvddZfekh4a2JbNWU1IYdfz8KmebSn5e6oKEmsDn0arZJFCW6VZWE+YSiIzRFJwzJz/TVL+7K2kpNKc2cl6EXCxaAgAbQD4ulcAd5ZBSTKrzLesRHJCSlSjGHU8f3Lck4slAmiX6JbQI7J4Qq+OoOnyw1EWCowItkkEj3JTpV66WqZaKb//PyGxElfTcv3yQ4PfoN61VYqZ9+S6B/Jq62EdZcpaTKgeZ06MdtPE5/XLjPC9UPdFCEJQu5Ak9Mf6EMJn90WEDl0P5EViHwTUzxanHN3+O8nuvR0QBfl0j/xBG57/+jmWM/qOiZVXDzjUmFdqGDMiheYE5O09tvU0Vi11weL5SQ1ZBI9+OGev5TYoypdb3qg7VWUiQrtyjSAlTv7Q8A2lixBfnWMCFNrb6lJ6Ktd8cZVs0WNhJOVztWeP8lHQpef4HggmxDz/mbGRwH9vorQ30kYh58x+kpylaP0o84cjuwD9SvbPTaBJcvtnqZ9vCBJTDmPFr5/+4XLbKvXB2SVpDtqB8HLXRY/5X40s2KgAmPRfdVO/Q0144i4yIrfqp0TSw3Aj1Wx9nSj2lDmHe43TzE+Gkh5SmLow== cirrusadmin@pebblecode.com"
}
