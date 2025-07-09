#!/bin/bash

################################################################################
# ✅ test.sh – End-to-end smoke test for LocalStack-based API
#
# This script does the following:
#   1. Runs `terraform apply` to stand up infrastructure (API Gateway, Lambda, DynamoDB).
#   2. Extracts API Gateway ID and adds its domain to /etc/hosts if missing.
#   3. Waits briefly to ensure API Gateway is responsive.
#   4. Sends test requests to:
#      - `/debug` (basic connectivity check)
#      - `/user` POST (create a user)
#      - `/user/{id}` GET (retrieve user)
#      - `/user/{id}` DELETE (delete user)
#      - `/user/{id}` GET again to confirm deletion (expect 404)
#   5. Confirms all endpoints behave correctly.
#
# Optional: You can uncomment the final `terraform destroy` to clean up resources.
################################################################################

set -e  # Exit immediately if any command fails

# 📁 Move into Terraform configuration directory
cd "$(dirname "$0")/../terraform"

echo "Starting Terraform apply to spin up API..."
terraform apply -auto-approve

# 🔎 Extract API Gateway ID for domain resolution
API_ID=$(terraform output -raw api_gateway_id)

# 🌐 Add domain to /etc/hosts for local resolution of custom API hostname
HOST_ENTRY="127.0.0.1 ${API_ID}.execute-api.localhost.localstack.cloud"
if ! grep -q "${API_ID}.execute-api.localhost.localstack.cloud" /etc/hosts; then
  echo "Adding API Gateway hostname to /etc/hosts..."
  echo "$HOST_ENTRY" | sudo tee -a /etc/hosts > /dev/null
else
  echo "API Gateway hostname already in /etc/hosts."
fi

# ⏳ Allow API Gateway time to initialize
echo "Waiting 5 seconds for LocalStack API Gateway to stabilize..."
sleep 5

# 🌍 Get base URL from Terraform output (includes stage)
BASE_URL=$(terraform output -raw api_gateway_invoke_url)

# 🧹 Remove trailing slash to avoid double slashes in test requests
BASE_URL="${BASE_URL%/}"

# 🔁 Run test suite

# ✅ Test debug endpoint
echo "Testing /debug endpoint (should return 200)..."
curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/debug" | grep -q "^200$" && echo "PASS: /debug endpoint" || (echo "FAIL: /debug endpoint"; exit 1)

# 🧪 Create a test user
USER_ID="testuser123"
USER_NAME="George"

echo "Creating user with POST..."
curl -s -X POST "${BASE_URL}/user" -H "Content-Type: application/json" -d "{\"id\":\"${USER_ID}\",\"name\":\"${USER_NAME}\"}" | grep -q "${USER_ID}" && echo "PASS: POST user" || (echo "FAIL: POST user"; exit 1)

# 🔍 Retrieve user
echo "Retrieving user with GET..."
curl -s "${BASE_URL}/user/${USER_ID}" | grep -q "${USER_NAME}" && echo "PASS: GET user" || (echo "FAIL: GET user"; exit 1)

# 🗑️ Delete user
echo "Deleting user with DELETE..."
curl -s -X DELETE "${BASE_URL}/user/${USER_ID}" | grep -q "deleted" && echo "PASS: DELETE user" || (echo "FAIL: DELETE user"; exit 1)

# 🚫 Confirm user no longer exists
echo "Checking user no longer exists with GET (expect 404)..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/user/${USER_ID}")
if [[ "$HTTP_STATUS" == "404" ]]; then
  echo "PASS: GET after DELETE returns 404"
else
  echo "FAIL: GET after DELETE returned $HTTP_STATUS"
  exit 1
fi

# ✅ All tests completed successfully
echo "All tests passed!"

# 🧨 Optional teardown (commented out by default)
# echo "Tearing down infrastructure..."
# terraform destroy -auto-approve

echo "Done."