# Setup OIDC Between AWS & Github
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Github Action Policy Document
data "aws_iam_policy_document" "github_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:heesooh/cloud_resume_challenge:*"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

# Create IAM Role GitHub Can Assume
resource "aws_iam_role" "github_actions_role" {
  name               = "${local.name_prefix}-github-role"
  assume_role_policy = data.aws_iam_policy_document.github_trust_policy.json
}

# Get Current AWS Account ID
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_permissions_policy" {
  # Grant Github Role Access to All Resrouces Deployed  
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:*",
      "lambda:*",
      "apigateway:*",
      "cloudfront:*",
      "s3:*",
      "iam:*",
      "logs:*",
    ]
    resources = [
      "arn:aws:s3:::${local.name_prefix}-*",
      "arn:aws:s3:::${local.name_prefix}-*/*",
      "arn:aws:lambda:*:*:function:${local.name_prefix}-*",
      "arn:aws:dynamodb:*:*:table/${local.name_prefix}-*",
      "arn:aws:iam::*:role/${local.name_prefix}-*",
      "arn:aws:logs:*:*:log-group:/aws/lambda/${local.name_prefix}-*",
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
    ]
  }

  # Grant Github Role Additional Access to Find CloudFornt Managed Caching Policy
  statement {
    effect = "Allow"
    actions = [
      "cloudfront:ListCachePolicies",
      "cloudfront:GetCachePolicy",
      "cloudfront:ListDistributions",
      "cloudfront:ListOriginAccessControls",
      "iam:ListPolicies",
      "iam:GetPolicy",
      "iam:GetRole"
    ]
    resources = ["*"]
  }

  # Grant Github Role Access to Terraform State Bucket
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.terraform_state.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.terraform_state.bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy" "github_inline_policy" {
  name   = "GithubCloudResumePermissions"
  role   = aws_iam_role.github_actions_role.id
  policy = data.aws_iam_policy_document.github_permissions_policy.json
}

# Output Github Role ARN
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}
