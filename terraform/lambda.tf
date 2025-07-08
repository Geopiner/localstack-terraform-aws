# Create an IAM role that Lambda functions will assume during execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"  # Role name visible in AWS console (LocalStack here)

  # Policy document allowing Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"         # Permission to assume this role
      Effect = "Allow"                  # Grant permission
      Principal = {
        Service = "lambda.amazonaws.com"  # Only Lambda service can assume
      }
    }]
  })

  tags = var.common_tags
}

# Main Lambda function definition (your user API handler)
resource "aws_lambda_function" "user" {
  function_name = var.lambda_function_name       # Lambda function name
  role          = aws_iam_role.lambda_exec.arn   # IAM role ARN to execute with
  handler       = var.lambda_handler             # Entry point in your Node.js code (index.handler)
  runtime       = var.lambda_runtime             # Node.js runtime version
  filename      = "../lambda/lambda_function_payload.zip"  # Path to zipped Lambda code
  source_code_hash = filebase64sha256("../lambda/lambda_function_payload.zip")  # Detect changes in code

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name   # Name of DynamoDB table passed into Lambda
    }
  }

  tags = var.common_tags
}

# Second Lambda function used for /debug endpoint — separate logic or simple response
resource "aws_lambda_function" "debug" {
  function_name = "debug_lambda"  # fixed name, or use your var
  role          = aws_iam_role.lambda_exec.arn
  handler       = "debug.handler"          # file name . exported function
  runtime       = "nodejs18.x"
  filename      = "../lambda/lambda_debug_payload.zip"
  source_code_hash = filebase64sha256("../lambda/lambda_debug_payload.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = var.common_tags
}