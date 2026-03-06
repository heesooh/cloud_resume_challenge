# ==================== Lambda ====================
# Zip Lambda Funciton
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../backend/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

# Create Lambda Function
resource "aws_lambda_function" "visitor_count_lambda" {
  function_name = "${local.name_prefix}-lambda-function"
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.lambda_zip.output_path
  handler       = "lambda.lambda_handler"
  runtime       = var.python_runtime

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.visitor_count_table.name
    }
  }
}

# Allow API Gateway to Invoke Lambda Function
resource "aws_lambda_permission" "lambda_allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_count_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_count_api.execution_arn}/$default/GET/count"
}

# Reduce CloudWatch Log Rentiontion Period to Reduce Storage Cost
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.visitor_count_lambda.function_name}"
  retention_in_days = 7
}



# ==================== API Gateway ====================
# Create API Gateway
resource "aws_apigatewayv2_api" "visitor_count_api" {
  name          = "${local.name_prefix}-api-gateway"
  protocol_type = "HTTP"
}

# Integrate API Gateway with Lambda
resource "aws_apigatewayv2_integration" "visitor_count_api_lambda" {
  api_id                 = aws_apigatewayv2_api.visitor_count_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_count_lambda.invoke_arn
  payload_format_version = "2.0"
}

# Create API Route on API Gateway
resource "aws_apigatewayv2_route" "visitor_count_api_route" {
  api_id    = aws_apigatewayv2_api.visitor_count_api.id
  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.visitor_count_api_lambda.id}"
}

# Create API Stage on API Gateway
resource "aws_apigatewayv2_stage" "visitor_count_api_stage" {
  api_id      = aws_apigatewayv2_api.visitor_count_api.id
  name        = "$default"
  auto_deploy = true
}