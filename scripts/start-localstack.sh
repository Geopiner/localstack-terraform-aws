#!/bin/bash
set -e

echo "Starting LocalStack Docker container..."
docker run --rm -d --name localstack_main -p 4566:4566 -p 4571:4571 -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack

echo "Waiting for LocalStack to be ready..."
until curl -s http://localhost:4566/_localstack/health | grep '"services":' > /dev/null; do
  echo -n "."
  sleep 2
done
echo "LocalStack is up."

# Move up one folder from scripts, then into terraform
cd ..
cd terraform

echo "Initializing Terraform..."
terraform init

echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo "Waiting 5 seconds for resources to stabilize..."
sleep 5

# Try to get API ID from Terraform output
if API_ID=$(terraform output -raw api_gateway_id 2>/dev/null); then
  echo "Got API Gateway ID from Terraform output: $API_ID"
else
  echo "Terraform output 'api_gateway_id' not found, trying AWS CLI..."
  API_ID=$(aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis --query "items[0].id" --output text)
  echo "Got API Gateway ID from AWS CLI: $API_ID"
fi

# Get the invoke URL from terraform output
INVOKE_URL=$(terraform output -raw api_gateway_invoke_url)

# Extract hostname only (strip protocol, port, and path)
API_HOST=$(echo "$INVOKE_URL" | sed -E 's#http://([^/:]+)(:[0-9]+)?/.*#\1#')

echo "API Gateway hostname: $API_HOST"

# Check if hostname is in /etc/hosts, add if missing
if ! grep -q "$API_HOST" /etc/hosts; then
  echo "Adding $API_HOST to /etc/hosts..."
  echo "127.0.0.1 $API_HOST" | sudo tee -a /etc/hosts > /dev/null
else
  echo "$API_HOST already exists in /etc/hosts"
fi

echo "Running test curl request..."
curl "${INVOKE_URL}test-id?name=George"

echo "Done."