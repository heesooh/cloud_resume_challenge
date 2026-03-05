# ==================== DynamoDB ====================
# Create DynamoDB Table
resource "aws_dynamodb_table" "visitor_count_table" {
    name = "${local.name_prefix}-visitor-count"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "id"
    
    attribute {
        name = "id"
        type = "S"
    }
}
