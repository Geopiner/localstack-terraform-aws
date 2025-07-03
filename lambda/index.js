const AWS = require('aws-sdk');                               // Import AWS SDK for JavaScript
const dynamodb = new AWS.DynamoDB.DocumentClient({            // Create DynamoDB DocumentClient instance
    endpoint: 'http://host.docker.internal:4566',                        // LocalStack DynamoDB endpoint URL
    region: 'us-east-1',                                      // AWS region (arbitrary for LocalStack)
    accessKeyId: 'test',                                      // Dummy access key for LocalStack
    secretAccessKey: 'test',                                  // Dummy secret key for LocalStack
})

const TABLE_NAME = process.env.DYNAMODB_TABLE;                // DynamoDB table name from Lambda environment variables

exports.handler = async (event) => {                          // Lambda function handler, receives event object
    console.log("DYNAMODB_TABLE env var:", process.env.DYNAMODB_TABLE);    // Log the full incoming event for debugging

    // Extract 'id' from path parameters; with API Gateway proxy integration 'proxy' holds the path
    const id = event.pathParameters ? event.pathParameters.proxy : 'default-id';

    // Extract 'name' from query string parameters, default to 'Anonymous' if missing
    const name = event.queryStringParameters ? event.queryStringParameters.name : 'Anonymous';

    // Prepare DynamoDB put item parameters
    const params = {
        TableName: TABLE_NAME,                                // Target DynamoDB table
        Item: {                                               // Item object to insert
            id: id,                                           // Primary key id
            name: name,                                       // Name attribute from query string
            createdAt: new Date().toISOString(),              // Timestamp for item creation
        }, 
    }; 
    
    console.log("Preparing to write to DynamoDB with params:", JSON.stringify(params));

    try { 
        await dynamodb.put(params).promise();                 // Execute DynamoDB put operation asynchronously
        console.log("Write complete, returning response");
        
        // On success, return 200 with confirmation and inserted item
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Item saved.',
                item: params.Item,
            }),
        };
    } catch (error) {
      console.error("Error writing to DynamoDB:", error);     // Log error details to CloudWatch / logs
      return {
        statusCode: 500,                                      // Return 500 Internal Server Error on failure
        body: JSON.stringify({ error: 'Could not save item.' }),
      };
    }
};