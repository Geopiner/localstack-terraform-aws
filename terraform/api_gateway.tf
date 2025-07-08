# Create the main REST API in API Gateway — your API’s “website name”
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = var.api_gateway_name  # Friendly name for the API (e.g., "my-api")
}

# Create the "/user" resource under the root (like a folder named "user")
resource "aws_api_gateway_resource" "user" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "user"
}

# Create the dynamic "/user/{id}" resource for user-specific paths
resource "aws_api_gateway_resource" "user_id" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.user.id
  path_part   = "{id}"
}

# Create the "/debug" resource under the root
resource "aws_api_gateway_resource" "debug" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "debug"
}

# Define POST method on "/user" (for creating users)
resource "aws_api_gateway_method" "create_user" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user.id
  http_method   = "POST"
  authorization = "NONE"  # No auth for now
}

# Define GET method on "/user/{id}" (for fetching user info)
resource "aws_api_gateway_method" "get_user" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_id.id
  http_method   = "GET"
  authorization = "NONE"
}

# Define DELETE method on "/user/{id}" (for deleting user)
resource "aws_api_gateway_method" "delete_user" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# Define GET method on "/debug"
resource "aws_api_gateway_method" "debug_get" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.debug.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integrate POST /user with user Lambda function (AWS_PROXY for Lambda Proxy integration)
resource "aws_api_gateway_integration" "create_user" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user.id
  http_method             = aws_api_gateway_method.create_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.user.invoke_arn
}

# Integrate GET /user/{id} with user Lambda
resource "aws_api_gateway_integration" "get_user" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_id.id
  http_method             = aws_api_gateway_method.get_user.http_method
  integration_http_method = "POST"  # Lambda is invoked with POST internally
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.user.invoke_arn
}

# Integrate DELETE /user/{id} with user Lambda
resource "aws_api_gateway_integration" "delete_user" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_id.id
  http_method             = aws_api_gateway_method.delete_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.user.invoke_arn
}

# Integrate GET /debug with debug Lambda
resource "aws_api_gateway_integration" "debug_get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.debug.id
  http_method             = aws_api_gateway_method.debug_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.debug.invoke_arn
}

# Allow API Gateway to invoke user Lambda
resource "aws_lambda_permission" "api_gateway_permission_user" {
  statement_id  = "AllowAPIGatewayInvokeUser"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

# Allow API Gateway to invoke debug Lambda
resource "aws_lambda_permission" "api_gateway_permission_debug" {
  statement_id  = "AllowAPIGatewayInvokeDebug"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.debug.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

# Create a single deployment including all integrations and methods (user + debug)
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.create_user,
    aws_api_gateway_integration.get_user,
    aws_api_gateway_integration.delete_user,
    aws_api_gateway_integration.debug_get_lambda,
    aws_api_gateway_method.debug_get,
  ]

  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "prod"

  depends_on = [
    aws_api_gateway_deployment.deployment
  ]
}