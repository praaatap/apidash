import 'package:mcp_server/mcp_server.dart';

/// Prompt for running a collection with optional environment
class RunCollectionPrompt {
  static const String name = 'run-collection';
  static const String description = 'Run an API collection and report results';

  static Map<String, dynamic> getArgumentsSchema() {
    return {
      'type': 'object',
      'properties': {
        'collection_id': {
          'type': 'string',
          'description': 'The collection ID to run',
        },
        'environment': {
          'type': 'string',
          'description': 'Environment to use (optional)',
        },
      },
      'required': ['collection_id'],
    };
  }

  static Future<GetPromptResult> handler(Map<String, dynamic> arguments) async {
    final collectionId = arguments['collection_id'] as String;
    final environment = arguments['environment'] as String?;

    return GetPromptResult(
      description: 'Run collection $collectionId',
      messages: [
        Message(
          role: 'user',
          content: TextContent(
            text: '''Please run the API collection with ID "$collectionId"${environment != null ? ' using the "$environment" environment' : ''}.

For each request in the collection, I need you to:
1. Execute the request
2. Report the status code and response time
3. Highlight any failures or errors
4. Provide a summary of the results

Start by listing all requests in the collection, then execute them one by one.''',
          ),
        ),
      ],
    );
  }
}

/// Prompt for debugging a failed request
class DebugRequestPrompt {
  static const String name = 'debug-request';
  static const String description = 'Debug a failed API request';

  static Map<String, dynamic> getArgumentsSchema() {
    return {
      'type': 'object',
      'properties': {
        'request_id': {
          'type': 'string',
          'description': 'The request ID to debug',
        },
        'collection_id': {
          'type': 'string',
          'description': 'The collection ID containing the request',
        },
        'error': {
          'type': 'string',
          'description': 'The error message or unexpected response',
        },
      },
      'required': ['request_id', 'collection_id'],
    };
  }

  static Future<GetPromptResult> handler(Map<String, dynamic> arguments) async {
    final requestId = arguments['request_id'] as String;
    final collectionId = arguments['collection_id'] as String;
    final error = arguments['error'] as String?;

    return GetPromptResult(
      description: 'Debug request $requestId',
      messages: [
        Message(
          role: 'user',
          content: TextContent(
            text: '''I need help debugging a failed API request.

Request ID: $requestId
Collection ID: $collectionId
${error != null ? 'Error/Issue: $error' : ''}

Please help me:
1. Get the full details of this request (URL, headers, body, auth)
2. Check if environment variables are properly configured
3. Identify potential issues with the request configuration
4. Suggest fixes for the problem
5. Test the corrected request

Start by retrieving the request details.''',
          ),
        ),
      ],
    );
  }
}

/// Prompt for comparing environments
class CompareEnvironmentsPrompt {
  static const String name = 'compare-environments';
  static const String description = 'Compare two environments';

  static Map<String, dynamic> getArgumentsSchema() {
    return {
      'type': 'object',
      'properties': {
        'environment_1': {
          'type': 'string',
          'description': 'First environment to compare',
        },
        'environment_2': {
          'type': 'string',
          'description': 'Second environment to compare',
        },
      },
      'required': ['environment_1', 'environment_2'],
    };
  }

  static Future<GetPromptResult> handler(Map<String, dynamic> arguments) async {
    final env1 = arguments['environment_1'] as String;
    final env2 = arguments['environment_2'] as String;

    return GetPromptResult(
      description: 'Compare environments $env1 and $env2',
      messages: [
        Message(
          role: 'user',
          content: TextContent(
            text: '''Compare these two API environments:

Environment 1: $env1
Environment 2: $env2

Please:
1. List all variables in both environments
2. Identify variables that exist in one but not the other
3. Highlight variables with different values
4. Show variables that are identical

Present the comparison in a clear table format.''',
          ),
        ),
      ],
    );
  }
}

/// Prompt for creating a new request
class CreateRequestPrompt {
  static const String name = 'create-request';
  static const String description = 'Create a new API request';

  static Map<String, dynamic> getArgumentsSchema() {
    return {
      'type': 'object',
      'properties': {
        'method': {
          'type': 'string',
          'description': 'HTTP method (GET, POST, PUT, DELETE, etc.)',
        },
        'url': {
          'type': 'string',
          'description': 'Request URL',
        },
        'description': {
          'type': 'string',
          'description': 'Description of what this request does',
        },
      },
      'required': ['method', 'url'],
    };
  }

  static Future<GetPromptResult> handler(Map<String, dynamic> arguments) async {
    final method = arguments['method'] as String;
    final url = arguments['url'] as String;
    final description = arguments['description'] as String?;

    return GetPromptResult(
      description: 'Create new $method request to $url',
      messages: [
        Message(
          role: 'user',
          content: TextContent(
            text: '''Help me create a new API request:

Method: $method
URL: $url
${description != null ? 'Description: $description' : ''}

Please help me:
1. Set up appropriate headers for this type of request
2. Configure authentication if needed
3. Set up the request body (for POST/PUT/PATCH)
4. Add any necessary query parameters
5. Save this request to a collection

What additional configuration does this request need?''',
          ),
        ),
      ],
    );
  }
}

/// Prompt for generating a test plan for an API
class GenerateTestPlanPrompt {
  static const String name = 'generate-test-plan';
  static const String description = 'Design a comprehensive test plan for an API or collection';

  static Future<GetPromptResult> handler(Map<String, dynamic> arguments) async {
    final collectionId = arguments['collection_id'] as String?;

    return GetPromptResult(
      description: 'Generate test plan${collectionId != null ? ' for collection $collectionId' : ''}',
      messages: [
        Message(
          role: 'user',
          content: TextContent(
            text: '''Please help me design a comprehensive test plan for ${collectionId != null ? 'the API collection with ID "$collectionId"' : 'my API'}.

Your plan should include:
1. Functional tests (Happy path, edge cases, error conditions)
2. Performance expectations (Response time, throughput)
3. Security verification (Auth, headers, data validation)
4. Data integrity checks (Payload structure, schema validation)

${collectionId != null ? 'Start by listing the requests in the collection to understand the scope.' : 'Ask me for the API endpoints you should analyze.'}''',
          ),
        ),
      ],
    );
  }
}

/// Prompt for performing a security audit on a request
class SecurityAuditPrompt {
  static const String name = 'security-audit';
  static const String description = 'Perform a security audit on an API request';

  static Future<GetPromptResult> handler(Map<String, dynamic> arguments) async {
    final requestId = arguments['request_id'] as String;
    final collectionId = arguments['collection_id'] as String;

    return GetPromptResult(
      description: 'Security audit for request $requestId',
      messages: [
        Message(
          role: 'user',
          content: TextContent(
            text: '''Please perform a security audit on the API request "$requestId" in collection "$collectionId".

Review the following:
1. Authentication mechanism (Is it robust? Is it using HTTPS?)
2. Sensitive headers (Are any credentials being leaked in plaintext?)
3. Data exposure (Is the request sending more data than necessary?)
4. Potential vulnerabilities (Injection, broken access control, etc.)

Start by getting the full details of the request.''',
          ),
        ),
      ],
    );
  }
}

/// Prompt for optimizing a request payload
class OptimizePayloadPrompt {
  static const String name = 'optimize-payload';
  static const String description = 'Optimize the payload and headers of an API request';

  static Future<GetPromptResult> handler(Map<String, dynamic> arguments) async {
    final requestId = arguments['request_id'] as String;
    final collectionId = arguments['collection_id'] as String;

    return GetPromptResult(
      description: 'Optimize payload for request $requestId',
      messages: [
        Message(
          role: 'user',
          content: TextContent(
            text: '''Please help me optimize the payload and configuration for API request "$requestId" in collection "$collectionId".

Suggestions should cover:
1. Minimizing payload size
2. Using more efficient headers (e.g., Cache-Control, Accept-Encoding)
3. Cleaning up redundant fields in the request body
4. Improving documentation and naming

Start by retrieving the request details.''',
          ),
        ),
      ],
    );
  }
}

/// Prompt for explaining a collection
class ExplainCollectionPrompt {
  static const String name = 'explain-collection';
  static const String description = 'Explain the purpose and flow of an API collection';

  static Future<GetPromptResult> handler(Map<String, dynamic> arguments) async {
    final collectionId = arguments['collection_id'] as String;

    return GetPromptResult(
      description: 'Explain collection $collectionId',
      messages: [
        Message(
          role: 'user',
          content: TextContent(
            text: '''Please explain the purpose and high-level workflow of the API collection "$collectionId".

Analyze:
1. What business problem this collection solves
2. The logical sequence of requests (the "flow")
3. Key data dependencies between requests
4. Major components and subsystems involved

Start by listing all requests in the collection.''',
          ),
        ),
      ],
    );
  }
}

/// Registers all prompts with the MCP server
void registerPrompts(Server server) {
  server.addPrompt(
    name: RunCollectionPrompt.name,
    description: RunCollectionPrompt.description,
    arguments: [
      PromptArgument(
        name: 'collection_id',
        description: 'The collection ID to run',
        required: true,
      ),
      PromptArgument(
        name: 'environment',
        description: 'Environment to use (optional)',
        required: false,
      ),
    ],
    handler: RunCollectionPrompt.handler,
  );

  server.addPrompt(
    name: DebugRequestPrompt.name,
    description: DebugRequestPrompt.description,
    arguments: [
      PromptArgument(
        name: 'request_id',
        description: 'The request ID to debug',
        required: true,
      ),
      PromptArgument(
        name: 'collection_id',
        description: 'The collection ID containing the request',
        required: true,
      ),
      PromptArgument(
        name: 'error',
        description: 'The error message or unexpected response',
        required: false,
      ),
    ],
    handler: DebugRequestPrompt.handler,
  );

  server.addPrompt(
    name: CompareEnvironmentsPrompt.name,
    description: CompareEnvironmentsPrompt.description,
    arguments: [
      PromptArgument(
        name: 'environment_1',
        description: 'First environment to compare',
        required: true,
      ),
      PromptArgument(
        name: 'environment_2',
        description: 'Second environment to compare',
        required: true,
      ),
    ],
    handler: CompareEnvironmentsPrompt.handler,
  );

  server.addPrompt(
    name: CreateRequestPrompt.name,
    description: CreateRequestPrompt.description,
    arguments: [
      PromptArgument(
        name: 'method',
        description: 'HTTP method (GET, POST, PUT, DELETE, etc.)',
        required: true,
      ),
      PromptArgument(
        name: 'url',
        description: 'Request URL',
        required: true,
      ),
      PromptArgument(
        name: 'description',
        description: 'Description of what this request does',
        required: false,
      ),
    ],
    handler: CreateRequestPrompt.handler,
  );

  server.addPrompt(
    name: GenerateTestPlanPrompt.name,
    description: GenerateTestPlanPrompt.description,
    arguments: [
      PromptArgument(
        name: 'collection_id',
        description: 'Optional collection ID to generate plan for',
        required: false,
      ),
    ],
    handler: GenerateTestPlanPrompt.handler,
  );

  server.addPrompt(
    name: SecurityAuditPrompt.name,
    description: SecurityAuditPrompt.description,
    arguments: [
      PromptArgument(
        name: 'request_id',
        description: 'The request ID to audit',
        required: true,
      ),
      PromptArgument(
        name: 'collection_id',
        description: 'The collection ID containing the request',
        required: true,
      ),
    ],
    handler: SecurityAuditPrompt.handler,
  );

  server.addPrompt(
    name: OptimizePayloadPrompt.name,
    description: OptimizePayloadPrompt.description,
    arguments: [
      PromptArgument(
        name: 'request_id',
        description: 'The request ID to optimize',
        required: true,
      ),
      PromptArgument(
        name: 'collection_id',
        description: 'The collection ID containing the request',
        required: true,
      ),
    ],
    handler: OptimizePayloadPrompt.handler,
  );

  server.addPrompt(
    name: ExplainCollectionPrompt.name,
    description: ExplainCollectionPrompt.description,
    arguments: [
      PromptArgument(
        name: 'collection_id',
        description: 'The collection ID to explain',
        required: true,
      ),
    ],
    handler: ExplainCollectionPrompt.handler,
  );
}
