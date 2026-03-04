# S3 Bucket
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

# DynamoDB Table
resource "aws_dynamodb_table" "visitor_count_table" {
    name = "cloud-resume-challenge-visitor-count-tf"
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
    name = "cloud-resume-challenge-lambda"
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
    name   = "dynamodb-read-write-access"
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
    function_name = "cloud-resume-challenge-counter-tf"
    role = aws_iam_role.lambda_role.arn

    filename = data.archive_file.lambda_zip.output_path
    handler = "lambda.lambda_handler"
    runtime = "python3.14"
}