resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.name_prefix}-state-bucket-heesooh"

  force_destroy = true
}
