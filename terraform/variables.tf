# AWS region used by Terraform (LocalStack ignores this but Terraform needs it syntactically)
variable "aws_region" {
  description = "AWS region used by Terraform. Required even for LocalStack."
  type        = string
  default     = "us-east-1"
}

# The name of the main DynamoDB table used by Lambda
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for storing user data"
  type        = string
  default     = "my-table"
}

# The name for your API Gateway instance — like naming your API project
variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "my-api"
}

# The function name of the main user-handling Lambda function
variable "lambda_function_name" {
  description = "Main Lambda function name (used for create/get/delete user)"
  type        = string
  default     = "user-lambda"
}

# The function name of the second/debug Lambda function
variable "second_lambda_function_name" {
  description = "Second Lambda function name (used for /debug endpoint)"
  type        = string
  default     = "debug-lambda"
}

# Handler definition in your Lambda — file name and exported function
variable "lambda_handler" {
  description = "Lambda handler function (e.g., 'index.handler')"
  type        = string
  default     = "index.handler"
}

# The runtime used for Lambda (Node.js version)
variable "lambda_runtime" {
  description = "Lambda runtime environment"
  type        = string
  default     = "nodejs18.x"
}

# Common tags applied to all resources — useful for grouping and billing
variable "common_tags" {
  description = "Tags applied to all AWS resources"
  type        = map(string)
  default     = {
    Project = "localstack-demo"
    Owner   = "George"
  }
}