# This output shows the unique ID of your API Gateway instance after Terraform finishes.
output "api_gateway_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}

# This output builds the full URL you use to call your deployed API.
# It uses the API ID plus the fixed LocalStack domain and port, then adds the stage 'prod'.
output "api_gateway_invoke_url" {
  value = "http://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.localhost.localstack.cloud:4566/prod/"
}