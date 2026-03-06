# ==================== S3 ====================
# Generate Random Suffix for Unique S3 Bucket Name
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create Resume Bucket - Allow Object Deletion Upon Bucket Delete
resource "aws_s3_bucket" "resume_bucket" {
  bucket = "${local.name_prefix}-bucket-${random_string.suffix.result}"

  force_destroy = true
}

# Block Public Access to Resume Bucket
resource "aws_s3_bucket_public_access_block" "resume_bucket_public_access_block" {
  bucket = aws_s3_bucket.resume_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload Static Portfolio Site in "../frontend/out/*" 
resource "aws_s3_object" "resume_objects" {
  for_each = fileset("${path.module}/../frontend/out", "**")

  bucket = aws_s3_bucket.resume_bucket.id
  key    = each.value
  source = "${path.module}/../frontend/out/${each.value}"
  content_type = lookup(
  local.content_types, element(split(".", each.value), length(split(".", each.value)) - 1), "text/plain")

  etag = filemd5("${path.module}/../frontend/out/${each.value}")
}

# Upload Visitor Count Script to Resume Bucket
resource "aws_s3_object" "resume_object_script" {
  bucket = aws_s3_bucket.resume_bucket.id

  key          = "resume/script.js"
  content      = local.counter_script
  content_type = "application/javascript"
}

# Attach S3 Bucket Policy that Only Allow CloudFront Distriibution Access
resource "aws_s3_bucket_policy" "resume_bucket_policy_attachment" {
  bucket = aws_s3_bucket.resume_bucket.id
  policy = data.aws_iam_policy_document.cloudfront_explicit_allow_policy.json
}



# ==================== CloudFront ====================
# Create CloudFront Distribution Origin Access Control
resource "aws_cloudfront_origin_access_control" "resume_bucket_oac" {
  name                              = "${local.name_prefix}-cloudfront-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create AWS Managed Cache Policy Object
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

# Create CloudFront Distribution with OAC & Cache Policy Defined Above
resource "aws_cloudfront_distribution" "resume_distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.resume_bucket.bucket_regional_domain_name
    origin_id                = "cloud-resume-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.resume_bucket_oac.id
  }

  default_cache_behavior {
    target_origin_id       = "cloud-resume-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.optimized.id
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
}
