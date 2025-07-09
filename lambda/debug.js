// ─────────────────────────────────────────────────────────────────────────────
// 🐞 Lambda Debug Handler
//
// This is a simple AWS Lambda function used purely as a debugging endpoint.
// When hit via API Gateway, it returns a 200 status code with a basic JSON
// message. It confirms that:
//   - Lambda is deployed and reachable
//   - API Gateway integration is working
//   - No IAM or execution role issues are present
//
// Use this as a baseline test to verify infrastructure is functional before
// testing more complex logic.
// ─────────────────────────────────────────────────────────────────────────────

exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message: "Debug endpoint OK" }),
  };
};