resource "aws_s3_bucket" "artifacts" {
  bucket = var.prefix
  tags = var.default_tags
}
