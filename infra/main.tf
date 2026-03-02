resource "aws_s3_bucket" "resume_bucket" {
    bucket = "cloud-resume-challenge-heesooh-tf"

    force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "resume_bucket_public_access_block" {
    bucket = aws_s3_bucket.resume_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_object" "resume_objects" {
    bucket = aws_s3_bucket.resume_bucket.id

    for_each = toset(var.resume_files_to_upload)
    key      = each.value
    source   = "../frontend/${each.value}"
}
