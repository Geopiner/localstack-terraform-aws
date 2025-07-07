# Create the API Gateway REST API
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "my-api" # Name of the API Gateway instance
}

# Define a catch-all proxy resource for any URL path
#resource "aws_api_gateway_resource" "proxy" {
#  rest_api_id = aws_api_gateway_rest_api.api_gateway.id               # Link to the API Gateway created above
#  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id # Attach under root path "/"
#  path_part   = "{proxy+}"                                            # Catch-all wildcard path
#}

resource "aws_api_gateway_resource" "user" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "user"
}

resource "aws_api_gateway_method" "create_user" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_user" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user.id
  http_method             = aws_api_gateway_method.create_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_api_gateway_resource" "user_id" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.user.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "get_user" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_user" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_id.id
  http_method             = aws_api_gateway_method.get_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_api_gateway_method" "delete_user" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_user" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_id.id
  http_method             = aws_api_gateway_method.delete_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

# Allow ANY HTTP method (GET, POST, PUT, DELETE, etc.) on the proxy resource
#resource "aws_api_gateway_method" "proxy_method" {
#  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id # Link to the API
#  resource_id   = aws_api_gateway_resource.proxy.id       # Link to the catch-all resource
#  http_method   = "ANY"                                   # Accept any HTTP method
#  authorization = "NONE"                                  # No authentication required
#}

# Connect the proxy resource to the Lambda function using AWS_PROXY integration
#resource "aws_api_gateway_integration" "lambda_integration" {
#  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id         # Link to the API
#  resource_id             = aws_api_gateway_resource.proxy.id               # Link to the resource
#  http_method             = aws_api_gateway_method.proxy_method.http_method # Must match the method above
#  integration_http_method = "POST"                                          # Method used by API Gateway to invoke Lambda
#  type                    = "AWS_PROXY"                                     # Enable Lambda Proxy integration (raw request/response passthrough)
#  uri                     = aws_lambda_function.lambda_function.invoke_arn  # Lambda function's invoke ARN
#}

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"                                     # Unique statement ID
  action        = "lambda:InvokeFunction"                                     # Action to allow
  function_name = aws_lambda_function.lambda_function.function_name           # Target Lambda function
  principal     = "apigateway.amazonaws.com"                                  # Service that’s allowed to invoke Lambda
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*" # Limit permission to this specific API Gateway
}

# Deploy the API Gateway configuration
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.create_user,
    aws_api_gateway_integration.get_user,
    aws_api_gateway_integration.delete_user
  ]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id          # Reference the REST API to deploy
}

# Define the stage where the API is accessible (prod/dev/etc.)
resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id  # Reference the REST API
  deployment_id = aws_api_gateway_deployment.deployment.id # Link to the deployment to be used in this stage
  stage_name    = "prod"                                   # Stage name (used in URL path)
}

# Output the invoke URL for easy access after apply
output "api_gateway_invoke_url" {
  value = "http://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.localhost.localstack.cloud:4566/prod/" # Base URL for API invocation
}

output "api_gateway_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}
