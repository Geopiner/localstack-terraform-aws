provider "aws" {
  # Which AWS region you want to use — LocalStack ignores this but Terraform needs it anyway
  region = var.aws_region

  # These are dummy keys because LocalStack doesn't require real AWS credentials
  access_key = "test"
  secret_key = "test"

  # Skip checks that would normally verify your credentials are real — not needed for LocalStack
  skip_credentials_validation = true

  # Skip EC2 metadata service checks because LocalStack doesn't simulate EC2 instances
  skip_metadata_api_check = true

  # Override the default AWS service URLs to point to LocalStack running on your machine
  endpoints {
    lambda     = "http://localhost:4566"  # Local Lambda service endpoint
    iam        = "http://localhost:4566"  # Local IAM service endpoint
    dynamodb   = "http://localhost:4566"  # Local DynamoDB service endpoint
    apigateway = "http://localhost:4566"  # Local API Gateway service endpoint
  }
}