import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:better_networking/better_networking.dart';
import 'package:mcp_server/mcp_server.dart';

/// Executes an HTTP request (saved or ad-hoc)
Future<Map<String, dynamic>> executeRequest(
  StorageService storage, {
  String? requestId,
  String? collectionId,
  String? url,
  String method = 'GET',
  Map<String, String>? headers,
  Map<String, String>? params,
  String? body,
  String? environment,
}) async {
  try {
    HttpRequestModel requestModel;

    if (requestId != null && collectionId != null) {
      // Execute saved request
      final savedRequest = await storage.getRequest(requestId);
      if (savedRequest == null) {
        throw Exception('Request "$requestId" not found in collection "$collectionId"');
      }
      requestModel = savedRequest;
    } else if (url != null) {
      // Execute ad-hoc request
      HTTPVerb httpMethod;
      try {
        httpMethod = HTTPVerb.values.byName(method.toLowerCase());
      } catch (_) {
        throw Exception('Invalid HTTP method: $method');
      }

      requestModel = HttpRequestModel(
        method: httpMethod,
        url: url,
        headers: headers?.entries.map((e) => NameValueModel(name: e.key, value: e.value)).toList() ?? [],
        params: params?.entries.map((e) => NameValueModel(name: e.key, value: e.value)).toList() ?? [],
        body: body,
      );
    } else {
      throw Exception('Either request_id+collection_id or url must be provided');
    }

    // Apply environment
    final envVars = <String, String>{};
    
    // Always load global variables
    try {
      final globalEnv = await storage.getEnvironment('global');
      envVars.addAll(globalEnv);
    } catch (_) {
      // Ignore if global env doesn't exist
    }

    // Layer specified environment on top
    if (environment != null && environment.isNotEmpty && environment != 'global') {
      final env = await storage.getEnvironment(environment);
      envVars.addAll(env);
    }

    if (envVars.isNotEmpty) {
      requestModel = storage.applyEnvironment(requestModel, envVars);
    }

    // Execute the request
    final execId = 'exec_${DateTime.now().millisecondsSinceEpoch}';
    final (response, duration, error) = await sendHttpRequest(
      execId,
      APIType.rest,
      requestModel,
    );

    if (error != null) {
      return {
        'success': false,
        'error': error,
      };
    }

    if (response == null) {
      return {
        'success': false,
        'error': 'No response received',
      };
    }

    final httpResponseModel = HttpResponseModel().fromResponse(
      response: response,
      time: duration,
    );

    // Redact sensitive headers
    final redactedHeaders = <String, String>{};
    final sensitiveHeaders = ['authorization', 'x-api-key', 'cookie', 'set-cookie'];
    for (final header in (httpResponseModel.headers ?? {}).entries) {
      if (sensitiveHeaders.contains(header.key.toLowerCase())) {
        redactedHeaders[header.key] = '[REDACTED]';
      } else {
        redactedHeaders[header.key] = header.value;
      }
    }

    return {
      'success': true,
      'statusCode': httpResponseModel.statusCode,
      'time': duration?.inMilliseconds,
      'contentType': httpResponseModel.contentType,
      'headers': redactedHeaders,
      'body': httpResponseModel.body,
    };
  } catch (e) {
    rethrow;
  }
}

/// Registers the exec_request tool
void registerExecRequestTool(
  Server server, {
  required StorageService storage,
}) {
  server.addTool(
    name: 'exec_request',
    description: 'Execute a saved HTTP request or send an ad-hoc request',
    inputSchema: {
      'type': 'object',
      'properties': {
        'request_id': {
          'type': 'string',
          'description': 'ID of a saved request (omit for ad-hoc requests)',
        },
        'collection_id': {
          'type': 'string',
          'description': 'Collection ID containing the saved request (required for saved requests)',
        },
        'url': {
          'type': 'string',
          'description': 'Request URL (for ad-hoc requests)',
        },
        'method': {
          'type': 'string',
          'description': 'HTTP method: GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS',
          'default': 'GET',
        },
        'headers': {
          'type': 'object',
          'description': 'Request headers as key-value pairs',
          'additionalProperties': {'type': 'string'},
        },
        'params': {
          'type': 'object',
          'description': 'Query parameters as key-value pairs',
          'additionalProperties': {'type': 'string'},
        },
        'body': {
          'type': 'string',
          'description': 'Request body (for POST, PUT, PATCH)',
        },
        'environment': {
          'type': 'string',
          'description': 'Environment name to use for variable resolution',
        },
      },
    },
    handler: (arguments) async {
      try {
        final result = await executeRequest(
          storage,
          requestId: arguments['request_id'] as String?,
          collectionId: arguments['collection_id'] as String?,
          url: arguments['url'] as String?,
          method: (arguments['method'] as String?) ?? 'GET',
          headers: (arguments['headers'] as Map?)?.cast<String, String>(),
          params: (arguments['params'] as Map?)?.cast<String, String>(),
          body: arguments['body'] as String?,
          environment: arguments['environment'] as String?,
        );

        return CallToolResult(
          content: [
            TextContent(text: jsonEncode(result)),
          ],
        );
      } catch (e) {
        return CallToolResult(
          content: [
            TextContent(text: jsonEncode({'error': e.toString()})),
          ],
          isError: true,
        );
      }
    },
  );
}
