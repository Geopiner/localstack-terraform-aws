// ─────────────────────────────────────────────────────────────────────────────
// API Gateway ID Output
//
// Exposes the unique identifier of the API Gateway created by Terraform.
// Useful for referencing the API in other resources or scripts.
// ─────────────────────────────────────────────────────────────────────────────
output "api_gateway_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}

// ─────────────────────────────────────────────────────────────────────────────
// API Gateway Invoke URL Output
//
// Constructs the full base URL to invoke the deployed API Gateway.
// Combines the API ID with the LocalStack hostname, port, and deployment stage.
// This URL is used in local testing and scripts to call your API endpoints.
// ─────────────────────────────────────────────────────────────────────────────
output "api_gateway_invoke_url" {
  value = "http://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.localhost.localstack.cloud:4566/prod/"
}