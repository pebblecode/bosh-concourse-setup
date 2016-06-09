resource "aws_iam_group" "deployers" {
  name = "ReleaseCandidateDeployers"
}

resource "aws_iam_policy" "release_bucket_access" {
  name = "ReleaseBucketAccess"
  description = "Access to releases in S3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.build_artifacts.arn}",
        "${aws_s3_bucket.build_artifacts.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "deployers_release_bucket" {
  name = "attach_release_bucket_access"
  groups = ["${aws_iam_group.deployers.name}"]
  policy_arn = "${aws_iam_policy.release_bucket_access.arn}"
}

resource "aws_iam_user" "concourse_worker" {
  name = "ConcourseWorker"
}

resource "aws_iam_group_membership" "concourse_worker_deployers" {
  name = "ConcourseWorkerDeploys"
  users = ["${aws_iam_user.concourse_worker.name}"]
  group = "${aws_iam_group.deployers.name}"
}

resource "aws_iam_access_key" "concourse_worker" {
  user = "${aws_iam_user.concourse_worker.name}"
}

resource "aws_s3_bucket" "build_artifacts" {
  bucket = "inoket-build-artifacts"
  acl = "private"
}

output "deployer_key_id" {
  value = "${aws_iam_access_key.concourse_worker.id}"
}

output "deployer_key_secret" {
  value = "${aws_iam_access_key.concourse_worker.secret}"
}

