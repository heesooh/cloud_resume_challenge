# TODO: Refactor
# Address .ico and script.js issue on browser
# Add route53
# Update readme.md 

# DynamoDB Table
resource "aws_dynamodb_table" "visitor_count_table" {
    name = "${local.name_prefix}-visitor-count"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "id"
    
    attribute {
        name = "id"
        type = "S"
    }
}

# Lambda Trust Policy
data "aws_iam_policy_document" "lambda_trust_policy" {
    statement {
        effect = "Allow"

        principals {
          type = "Service"
          identifiers = ["lambda.amazonaws.com"]
        }

        actions = ["sts:AssumeRole"]
    }
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_role" {
    name = "${local.name_prefix}-lambda-role"
    assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
}

# Attach Lambda Role Policies
resource "aws_iam_role_policy_attachment" "lambda_basic_role_attachment" {
    role = aws_iam_role.lambda_role.id
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB Read/Write Policy
data "aws_iam_policy_document" "dynamodb_read_write_policy" {
    statement {
        effect = "Allow"

        actions = [
            "dynamodb:UpdateItem",
            "dynamodb:GetItem",
            "dynamodb:PutItem"
        ]

        resources = [aws_dynamodb_table.visitor_count_table.arn]
    }
}

# Create DynamoDB Inline Policy
resource "aws_iam_role_policy" "lambda_dynamodb_inline_policy" {
    name   = "DynamoDBReadWriteAccess"
    role   = aws_iam_role.lambda_role.id

    policy = data.aws_iam_policy_document.dynamodb_read_write_policy.json
}

# Lambda Zip
data "archive_file" "lambda_zip" {
    type = "zip"
    source_file = "../backend/lambda.py"
    output_path = "${path.module}/lambda.zip"
}

# Lambda Function
resource "aws_lambda_function" "visitor_count_lambda" {
    function_name = "${local.name_prefix}-lambda-function"
    role     = aws_iam_role.lambda_role.arn
    filename = data.archive_file.lambda_zip.output_path
    handler  = "lambda.lambda_handler"
    runtime  = var.python_runtime

    environment {
        variables = {
            DYNAMODB_TABLE_NAME = aws_dynamodb_table.visitor_count_table.name
        }
    }
}

# API Gateway
resource "aws_apigatewayv2_api" "visitor_count_api" {
    name          = "${local.name_prefix}-api-gateway"
    protocol_type = "HTTP"
}

# API Gateway - Integration with Lambda
resource "aws_apigatewayv2_integration" "visitor_count_api_lambda" {
    api_id = aws_apigatewayv2_api.visitor_count_api.id
    integration_type = "AWS_PROXY"
    integration_uri = aws_lambda_function.visitor_count_lambda.invoke_arn
    payload_format_version  = "2.0"
}

# API Gateway - Route
resource "aws_apigatewayv2_route" "visitor_count_api_route" {
    api_id    = aws_apigatewayv2_api.visitor_count_api.id
    route_key = "GET /count"
    target    = "integrations/${aws_apigatewayv2_integration.visitor_count_api_lambda.id}"
}

# API Gateway - Stage
resource "aws_apigatewayv2_stage" "visitor_count_api_stage" {
    api_id = aws_apigatewayv2_api.visitor_count_api.id
    name   = "$default"
    auto_deploy = true 
}

# Allow API Gateway to Invoke Lambda Function
resource "aws_lambda_permission" "lambda_allow_api_gateway" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.visitor_count_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.visitor_count_api.execution_arn}/$default/GET/count"
}

resource "random_string" "suffix" {
    length  = 8
    special = false
    upper   = false
}

# S3 Bucket
resource "aws_s3_bucket" "resume_bucket" {
    bucket = "${local.name_prefix}-bucket-${random_string.suffix.result}"

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

    for_each     = toset(var.resume_files_to_upload)
    key          = each.value
    source       = "../frontend/${each.value}"
    content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), "text/plain")
}

# Upload Updated FrontEnd Script to S3 Bucket
resource "aws_s3_object" "resume_object_script" {
    bucket = aws_s3_bucket.resume_bucket.id

    key     = "script.js"
    content = local.counter_script
    content_type = "application/javascript"
}

# CloudFront Distribution
resource "aws_cloudfront_origin_access_control" "resume_bucket_oac" {
    name = "${local.name_prefix}-cloudfront-oac"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}

data "aws_cloudfront_cache_policy" "optimized" {
    name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "resume_distribution" {
    enabled = true
    default_root_object = "index.html"

    origin {
        domain_name = aws_s3_bucket.resume_bucket.bucket_regional_domain_name
        origin_id   = "cloud-resume-origin"
        origin_access_control_id = aws_cloudfront_origin_access_control.resume_bucket_oac.id
    }

    default_cache_behavior {
      target_origin_id = "cloud-resume-origin"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods = ["GET", "HEAD"]
      cached_methods = ["GET", "HEAD"]

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
}

# Resume Bucket Policy to Only Grant CloudFront Access
data "aws_iam_policy_document" "resume_bucket_policy" {
    statement {
        effect = "Allow"

        principals {
            type        = "Service"
            identifiers = ["cloudfront.amazonaws.com"]
        }

        actions   = ["s3:GetObject"]
        resources = [
            "${aws_s3_bucket.resume_bucket.arn}/*"
        ]
        
        condition {
          test     = "StringEquals"
          variable = "AWS:SourceArn" 
          values   = [
            "${aws_cloudfront_distribution.resume_distribution.arn}"
          ]
        }
    }
}

resource "aws_s3_bucket_policy" "resume_bucket_policy_attachment" {
    bucket = aws_s3_bucket.resume_bucket.id
    policy = data.aws_iam_policy_document.resume_bucket_policy.json
}
