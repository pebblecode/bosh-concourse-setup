resource "aws_s3_bucket" "supplier_frontend_version" {
  bucket = "inoket-supplier-frontend-artifacts"
  acl = "private"
}
