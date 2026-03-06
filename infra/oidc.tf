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

data "aws_iam_policy_document" "github_permissions_policy" {
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
      "${aws_s3_bucket.resume_bucket.arn}",
      "${aws_s3_bucket.resume_bucket.arn}/*",
      "${aws_cloudfront_distribution.resume_distribution.arn}",
      "${aws_lambda_function.visitor_count_lambda.arn}",
      "${aws_dynamodb_table.visitor_count_table.arn}",
      "${aws_apigatewayv2_api.visitor_count_api.arn}/*",
      "arn:aws:iam::*:role/${local.name_prefix}-*",
      "arn:aws:logs:*:*:log-group:/aws/lambda/${local.name_prefix}-*",
    ]
  }

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
