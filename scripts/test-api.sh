#!/bin/bash

set -e  # Exit immediately if any command fails

# Move into the folder where your Terraform configs live (adjust if needed)
cd "$(dirname "$0")/../terraform"

echo "Starting Terraform apply to spin up API..."
terraform apply -auto-approve

# Grab API Gateway ID output from Terraform
API_ID=$(terraform output -raw api_gateway_id)

# Add domain to /etc/hosts if missing, so your system can resolve the LocalStack API URL
HOST_ENTRY="127.0.0.1 ${API_ID}.execute-api.localhost.localstack.cloud"
if ! grep -q "${API_ID}.execute-api.localhost.localstack.cloud" /etc/hosts; then
  echo "Adding API Gateway hostname to /etc/hosts..."
  echo "$HOST_ENTRY" | sudo tee -a /etc/hosts > /dev/null
else
  echo "API Gateway hostname already in /etc/hosts."
fi

echo "Waiting 5 seconds for LocalStack API Gateway to stabilize..."
sleep 5

# Get the base invoke URL from Terraform output (includes stage)
BASE_URL=$(terraform output -raw api_gateway_invoke_url)

# Remove trailing slash if exists (to avoid double slash in curl URLs)
BASE_URL="${BASE_URL%/}"

echo "Testing /debug endpoint (should return 200)..."
curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/debug" | grep -q "^200$" && echo "PASS: /debug endpoint" || (echo "FAIL: /debug endpoint"; exit 1)

USER_ID="testuser123"
USER_NAME="George"

echo "Creating user with POST..."
curl -s -X POST "${BASE_URL}/user" -H "Content-Type: application/json" -d "{\"id\":\"${USER_ID}\",\"name\":\"${USER_NAME}\"}" | grep -q "${USER_ID}" && echo "PASS: POST user" || (echo "FAIL: POST user"; exit 1)

echo "Retrieving user with GET..."
curl -s "${BASE_URL}/user/${USER_ID}" | grep -q "${USER_NAME}" && echo "PASS: GET user" || (echo "FAIL: GET user"; exit 1)

echo "Deleting user with DELETE..."
curl -s -X DELETE "${BASE_URL}/user/${USER_ID}" | grep -q "deleted" && echo "PASS: DELETE user" || (echo "FAIL: DELETE user"; exit 1)

echo "Checking user no longer exists with GET (expect 404)..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/user/${USER_ID}")
if [[ "$HTTP_STATUS" == "404" ]]; then
  echo "PASS: GET after DELETE returns 404"
else
  echo "FAIL: GET after DELETE returned $HTTP_STATUS"
  exit 1
fi

echo "All tests passed!"

# echo "Tearing down infrastructure..."
# terraform destroy -auto-approve

echo "Done."