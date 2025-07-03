resource "aws_dynamodb_table" "my_table" {
  name           = "my-table"                    # Name of the DynamoDB table
  billing_mode   = "PAY_PER_REQUEST"             # Use on-demand capacity mode (no need to specify read/write units)
  hash_key       = "id"                          # Partition key attribute name (primary key)

  attribute {
    name = "id"                                  # Attribute name for the partition key
    type = "S"                                   # Attribute type "S" means String
  }
}
