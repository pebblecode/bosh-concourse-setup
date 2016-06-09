resource "aws_iam_role_policy" "s3_pipeline_artifacts" {
  name = "s3_pipeline_artifacts"
  role = "${aws_iam_role.concourse-worker.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:ListBuckets"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.build_artifacts.arn}"
    }
  ]
}
EOF
}
resource "aws_iam_role" "concourse-worker" {
  name = "concourse-worker"
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

resource "aws_iam_instance_profile" "concourse-worker" {
  name = "concourse-worker"
  roles = ["${aws_iam_role.concourse-worker.name}"]
}

