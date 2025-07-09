#!/bin/bash
set -e

################################################################################
# 🧰 start.sh – Bootstraps the LocalStack development environment
#
# This script:
#   1. Starts the LocalStack Docker container.
#   2. Waits for LocalStack to be fully operational.
#   3. Navigates to the Terraform directory.
#   4. Runs `terraform init` and `terraform apply` to deploy the stack.
#   5. Extracts the API Gateway invoke URL.
#   6. Adds the hostname to `/etc/hosts` (for local DNS resolution).
#   7. Sends a test POST request to the local API to confirm it's working.
#
# Meant to be run from the /scripts directory.
################################################################################

# 🐳 Start LocalStack Docker container with correct ports and Docker socket
echo "Starting LocalStack Docker container..."
docker run --rm -d --name localstack_main -p 4566:4566 -p 4571:4571 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  localstack/localstack

# ⏳ Wait until LocalStack reports it's fully healthy
echo "Waiting for LocalStack to be ready..."
until curl -s http://localhost:4566/_localstack/health | grep '"services":' > /dev/null; do
  echo -n "."
  sleep 2
done
echo "LocalStack is up."

# 📁 Move into the Terraform directory (assumes we're in /scripts)
cd ..
cd terraform

# 🧱 Initialize Terraform (downloads required providers/modules)
echo "Initializing Terraform..."
terraform init

# 🚀 Deploy the Terraform infrastructure to LocalStack
echo "Applying Terraform configuration..."
terraform apply -auto-approve

# ⏳ Short wait to allow LocalStack services to stabilize
echo "Waiting 5 seconds for resources to stabilize..."
sleep 5

# 🔍 Try to get the API Gateway ID from Terraform output; fallback to AWS CLI if missing
if API_ID=$(terraform output -raw api_gateway_id 2>/dev/null); then
  echo "Got API Gateway ID from Terraform output: $API_ID"
else
  echo "Terraform output 'api_gateway_id' not found, trying AWS CLI..."
  API_ID=$(aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis \
    --query "items[0].id" --output text)
  echo "Got API Gateway ID from AWS CLI: $API_ID"
fi

# 🌐 Get the full API invoke URL from Terraform outputs
INVOKE_URL=$(terraform output -raw api_gateway_invoke_url)

# 🧠 Extract just the hostname (no port or protocol) from the URL
API_HOST=$(echo "$INVOKE_URL" | sed -E 's#http://([^/:]+)(:[0-9]+)?/.*#\1#')
echo "API Gateway hostname: $API_HOST"

# 🧹 Add hostname to /etc/hosts if it's not already there (for DNS resolution)
if ! grep -q "$API_HOST" /etc/hosts; then
  echo "Adding $API_HOST to /etc/hosts..."
  echo "127.0.0.1 $API_HOST" | sudo tee -a /etc/hosts > /dev/null
else
  echo "$API_HOST already exists in /etc/hosts"
fi

# 🧪 Test the deployed API by sending a sample POST request to the /user endpoint
echo "Running test curl request..."
curl -s -X POST "${INVOKE_URL}user" \
  -H "Content-Type: application/json" \
  -d '{"id": "test-id", "name": "George"}' | jq

echo -e "\nTest user created. LocalStack is ready."