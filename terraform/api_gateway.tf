// ─────────────────────────────────────────────────────────────────────────────
// API Gateway REST API Setup
// This block creates the main REST API which serves as the root container
// for all your API resources and routes. It's like the "website" for your API.
// ─────────────────────────────────────────────────────────────────────────────
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = var.api_gateway_name  // Friendly name, e.g. "my-api"
}

// ─────────────────────────────────────────────────────────────────────────────
// API Gateway Resources Setup
// These resources define the API paths/endpoints your API will expose:
// - "/user" for general user operations
// - "/user/{id}" for operations on a specific user by ID
// - "/debug" for a simple debug/test endpoint
// ─────────────────────────────────────────────────────────────────────────────
resource "aws_api_gateway_resource" "user" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "user"
}

resource "aws_api_gateway_resource" "user_id" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.user.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "debug" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "debug"
}

// ─────────────────────────────────────────────────────────────────────────────
// API Gateway Methods
// These define the HTTP verbs allowed on each resource, such as POST, GET, DELETE.
// Authorization is set to NONE here, meaning no authentication is required.
// ─────────────────────────────────────────────────────────────────────────────
resource "aws_api_gateway_method" "create_user" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_user" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "delete_user" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "debug_get" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.debug.id
  http_method   = "GET"
  authorization = "NONE"
}

// ─────────────────────────────────────────────────────────────────────────────
// API Gateway Integrations with Lambda
// These link each API method to the appropriate Lambda function using AWS_PROXY
// integration type, allowing Lambda to handle the entire request/response.
// Note: Lambda is invoked internally using HTTP POST regardless of method.
// ─────────────────────────────────────────────────────────────────────────────
resource "aws_api_gateway_integration" "create_user" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user.id
  http_method             = aws_api_gateway_method.create_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.user.invoke_arn
}

resource "aws_api_gateway_integration" "get_user" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_id.id
  http_method             = aws_api_gateway_method.get_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.user.invoke_arn
}

resource "aws_api_gateway_integration" "delete_user" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_id.id
  http_method             = aws_api_gateway_method.delete_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.user.invoke_arn
}

resource "aws_api_gateway_integration" "debug_get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.debug.id
  http_method             = aws_api_gateway_method.debug_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.debug.invoke_arn
}

// ─────────────────────────────────────────────────────────────────────────────
// Lambda Permissions for API Gateway
// These permissions allow API Gateway service to invoke the specified Lambda
// functions. Without these, the integration would fail due to access denied.
// ─────────────────────────────────────────────────────────────────────────────
resource "aws_lambda_permission" "api_gateway_permission_user" {
  statement_id  = "AllowAPIGatewayInvokeUser"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_debug" {
  statement_id  = "AllowAPIGatewayInvokeDebug"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.debug.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

// ─────────────────────────────────────────────────────────────────────────────
// API Gateway Deployment and Stage
// Deployment bundles all your API methods and integrations into a deployable unit.
// The stage (here "prod") is the environment alias through which you access the API.
// create_before_destroy ensures safe updates by creating new deployment before deleting old.
// ─────────────────────────────────────────────────────────────────────────────
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