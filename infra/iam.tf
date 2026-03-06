# ==================== DynamoDB + Lambda ====================
# Lambda Trust Policy Document
data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create Lambda Execution Role - Attach Trust Policy
resource "aws_iam_role" "lambda_role" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
}

# Attach Lambda Managed Policy
resource "aws_iam_role_policy_attachment" "lambda_basic_role_attachment" {
  role       = aws_iam_role.lambda_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB Read/Write Access Policy Document
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

# Create Lambda Role Inline Policy to Access DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb_inline_policy" {
  name = "DynamoDBReadWriteAccess"
  role = aws_iam_role.lambda_role.id

  policy = data.aws_iam_policy_document.dynamodb_read_write_policy.json
}

# ==================== S3 + CloudFront ====================
# Resume Bucket Policy to Only Grant CloudFront Distribution Access
data "aws_iam_policy_document" "cloudfront_explicit_allow_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.resume_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        "${aws_cloudfront_distribution.resume_distribution.arn}"
      ]
    }
  }
}
