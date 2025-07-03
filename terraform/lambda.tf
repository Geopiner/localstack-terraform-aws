# Configure the AWS provider to connect Terraform to LocalStack services
provider "aws" {
  access_key                  = "test"      # Dummy access key for LocalStack
  secret_key                  = "test"      # Dummy secret key for LocalStack
  region                      = "us-east-1" # AWS region, arbitrary here for LocalStack
  skip_credentials_validation = true        # Skip credential validation for local dev
  skip_metadata_api_check     = true        # Skip EC2 metadata API check (LocalStack doesn't have it)

  # Override service endpoints to point to LocalStack's URLs
  endpoints {
    lambda     = "http://localhost:4566" # LocalStack Lambda endpoint
    iam        = "http://localhost:4566" # LocalStack IAM endpoint
    dynamodb   = "http://localhost:4566" # LocalStack DynamoDB endpoint
    apigateway = "http://localhost:4566" # LocalStack API Gateway endpoint
  }
}

# Define the Lambda function resource
resource "aws_lambda_function" "lambda_function" {
  function_name    = "app-function"                                  # Lambda function's name
  filename         = "../lambda/lambda_function_payload.zip"                   # Path to zipped Lambda code package
  handler          = "index.handler"                                 # Entry point: index.js file's exported handler function
  runtime          = "nodejs18.x"                                    # Lambda runtime environment (Node.js 18.x)
  role             = aws_iam_role.lambda_exec.arn                    # IAM Role ARN that Lambda assumes for permissions
  source_code_hash = filebase64sha256("../lambda/lambda_function_payload.zip") # Base64 hash to detect code changes & trigger redeploy
  timeout          = 10                                              # Timeout in seconds for Lambda execution
  
  environment {                                                      # Environment variables passed into the Lambda function
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.my_table.name              # Name of DynamoDB table injected as an environment variable
    }
  }
}

# Create IAM Role that Lambda assumes when it runs
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"              # Name of the IAM role

  # Trust policy allowing Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"               # IAM policy version
    Statement = [{
      Action = "sts:AssumeRole"          # Action allowing role assumption
      Effect = "Allow"                   # Effect: allow the action
      Principal = {
        Service = "lambda.amazonaws.com" # Principal: Lambda service
      }
    }]
  })
}
