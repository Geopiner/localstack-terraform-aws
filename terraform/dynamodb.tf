// ─────────────────────────────────────────────────────────────────────────────
// DynamoDB Table Resource
//
// Defines a DynamoDB table to store user data with a simple primary key.
// Uses on-demand billing to avoid capacity management and costs are based on usage.
// The primary key "id" is a string that uniquely identifies each item in the table.
// ─────────────────────────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "my_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}