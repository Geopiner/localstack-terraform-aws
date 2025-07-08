# This creates a DynamoDB table in AWS (or LocalStack in our case)
resource "aws_dynamodb_table" "my_table" {
  name         = var.dynamodb_table_name  # The table’s name, set from the variable above
  billing_mode = "PAY_PER_REQUEST"        # You pay only for what you use, no capacity setup needed
  hash_key     = "id"                      # The primary key for the table — this must be unique for each item

  attribute {
    name = "id"                           # Define the "id" attribute as the key
    type = "S"                           # "S" means string type (like text)
  }
}