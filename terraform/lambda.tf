// ─────────────────────────────────────────────────────────────────────────────
// IAM Role for Lambda Execution
//
// Creates an IAM role that AWS Lambda functions will assume when running.
// This role grants permission for Lambda to execute and interact with other AWS services.
// The assume_role_policy restricts this role to be assumed only by Lambda service.
// Tags are added for organization and cost tracking.
// ─────────────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.common_tags
}

// ─────────────────────────────────────────────────────────────────────────────
// User Lambda Function
//
// Defines the main Lambda function handling user-related API requests.
// It runs Node.js code packaged in a zip file.
// The function assumes the IAM role defined above to gain necessary permissions.
// Environment variables provide dynamic configuration like DynamoDB table name.
// The source_code_hash ensures Terraform detects code changes and redeploys.
// ─────────────────────────────────────────────────────────────────────────────
resource "aws_lambda_function" "user" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  filename         = "../lambda/lambda_function_payload.zip"
  source_code_hash = filebase64sha256("../lambda/lambda_function_payload.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = var.common_tags
}

// ─────────────────────────────────────────────────────────────────────────────
// Debug Lambda Function
//
// A separate Lambda function dedicated to the /debug API endpoint.
// It provides a simple health check or test response to verify deployment and API Gateway integration.
// Uses the same IAM role and environment configuration for consistency.
// ─────────────────────────────────────────────────────────────────────────────
resource "aws_lambda_function" "debug" {
  function_name    = "debug_lambda"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "debug.handler"
  runtime          = "nodejs18.x"
  filename         = "../lambda/lambda_debug_payload.zip"
  source_code_hash = filebase64sha256("../lambda/lambda_debug_payload.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = var.common_tags
}