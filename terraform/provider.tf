// ─────────────────────────────────────────────────────────────────────────────
// AWS Provider Configuration for Terraform using LocalStack
//
// This block configures the AWS provider plugin for Terraform, targeting LocalStack
// running locally instead of real AWS. It sets dummy credentials and disables checks
// irrelevant for LocalStack to avoid errors during apply.
//
// The 'endpoints' override redirects AWS service calls to LocalStack’s local URLs,
// enabling offline and cost-free development.
// ─────────────────────────────────────────────────────────────────────────────

provider "aws" {
  # AWS region (required by Terraform but ignored by LocalStack)
  region = var.aws_region

  # Dummy AWS credentials since LocalStack doesn't require real keys
  access_key = "test"
  secret_key = "test"

  # Disable validation that real AWS credentials exist (LocalStack exception)
  skip_credentials_validation = true

  # Disable metadata API check because LocalStack doesn't emulate EC2 metadata service
  skip_metadata_api_check = true

  # Redirect AWS service endpoints to LocalStack local endpoints
  endpoints {
    lambda     = "http://localhost:4566"
    iam        = "http://localhost:4566"
    dynamodb   = "http://localhost:4566"
    apigateway = "http://localhost:4566"
  }
}