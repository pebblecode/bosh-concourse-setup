resource "aws_iam_role_policy" "director" {
  name = "director"
  role = "${aws_iam_role.director.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": [
      "ec2:AssociateAddress",
      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteVolume",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:RegisterImage",
      "ec2:DeregisterImage"
    ],
    "Effect": "Allow",
    "Resource": "*"
  },{
    "Effect": "Allow",
    "Action": "elasticloadbalancing:*",
    "Resource": "*"
  },{
    "Effect": "Allow",
    "Action": "iam:PassRole",
    "Resource": "${aws_iam_role.director.arn}"
  }]
}EOF
}

resource "aws_iam_role" "director" {
  name = "director"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": { 
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "director" {
  name  = "director"
  roles = ["${aws_iam_role.director.name}"]
}
