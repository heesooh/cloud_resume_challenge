# Output CloudFront Endpoint to Verify
output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.resume_distribution.domain_name
}
