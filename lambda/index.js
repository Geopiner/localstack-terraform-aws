// ─────────────────────────────────────────────────────────────────────────────
// 👤 Lambda Handler for User CRUD (Create, Read, Delete)
//
// This AWS Lambda function is responsible for handling user-related operations
// through API Gateway. It talks to a DynamoDB table (emulated via LocalStack)
// and supports three HTTP methods:
//
//   - POST /user         → Creates a new user from request body
//   - GET /user/{id}     → Retrieves a user by their ID
//   - DELETE /user/{id}  → Deletes a user by their ID
//
// ⚙️ DynamoDB table name is passed as an environment variable: `DYNAMODB_TABLE`
// 📦 Local AWS SDK client is configured to use the LocalStack endpoint
//
// ✅ Features:
//   - Input validation with informative error messages
//   - Standardized HTTP response codes
//   - Clear error handling and logging
// ─────────────────────────────────────────────────────────────────────────────

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient({
  endpoint: 'http://host.docker.internal:4566',
  region: 'us-east-1',
  accessKeyId: 'test',
  secretAccessKey: 'test',
});

const TABLE_NAME = process.env.DYNAMODB_TABLE;

exports.handler = async (event) => {
  console.log("Received event:", JSON.stringify(event));

  const method = event.httpMethod;
  const id = event.pathParameters ? event.pathParameters.id : null;

  try {
    if (method === 'POST') {
      // ─────────────────────────────────────────────────────────────
      // 📝 Create a new user based on JSON body
      // Requires `id` and `name` fields
      // ─────────────────────────────────────────────────────────────
      const body = JSON.parse(event.body || '{}');
      if (!body.id || !body.name) {
        return {
          statusCode: 400,
          body: JSON.stringify({ error: "Missing 'id' or 'name' in request body" }),
        };
      }

      const params = {
        TableName: TABLE_NAME,
        Item: {
          id: body.id,
          name: body.name,
          createdAt: new Date().toISOString(),
        },
      };

      await dynamodb.put(params).promise();
      return {
        statusCode: 201,
        body: JSON.stringify({ message: "User created", user: params.Item }),
      };

    } else if (method === 'GET') {
      // ─────────────────────────────────────────────────────────────
      // 🔍 Get a user by ID from the path
      // ─────────────────────────────────────────────────────────────
      if (!id) {
        return {
          statusCode: 400,
          body: JSON.stringify({ error: "Missing user 'id' in path" }),
        };
      }

      const params = {
        TableName: TABLE_NAME,
        Key: { id },
      };

      const result = await dynamodb.get(params).promise();
      if (!result.Item) {
        return {
          statusCode: 404,
          body: JSON.stringify({ error: "User not found" }),
        };
      }

      return {
        statusCode: 200,
        body: JSON.stringify(result.Item),
      };

    } else if (method === 'DELETE') {
      // ─────────────────────────────────────────────────────────────
      // 🗑️ Delete a user by ID from the path
      // ─────────────────────────────────────────────────────────────
      if (!id) {
        return {
          statusCode: 400,
          body: JSON.stringify({ error: "Missing user 'id' in path" }),
        };
      }

      const params = {
        TableName: TABLE_NAME,
        Key: { id },
      };

      await dynamodb.delete(params).promise();

      return {
        statusCode: 200,
        body: JSON.stringify({ message: `User ${id} deleted` }),
      };

    } else {
      // ─────────────────────────────────────────────────────────────
      // ❌ Method not supported
      // ─────────────────────────────────────────────────────────────
      return {
        statusCode: 405,
        body: JSON.stringify({ error: `Method ${method} not allowed` }),
      };
    }
  } catch (error) {
    // ─────────────────────────────────────────────────────────────
    // 💥 Handle any internal server errors
    // ─────────────────────────────────────────────────────────────
    console.error("Error handling request:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};