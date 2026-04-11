import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:better_networking/better_networking.dart';
import 'package:mcp_server/mcp_server.dart';

/// Result of executing a single request
class RequestExecutionResult {
  const RequestExecutionResult({
    required this.requestId,
    required this.requestName,
    required this.success,
    this.statusCode,
    this.time,
    this.error,
  });

  final String requestId;
  final String requestName;
  final bool success;
  final int? statusCode;
  final int? time;
  final String? error;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'requestName': requestName,
        'success': success,
        if (statusCode != null) 'statusCode': statusCode,
        if (time != null) 'time': time,
        if (error != null) 'error': error,
      };
}

/// Executes all requests in a collection
Future<List<RequestExecutionResult>> executeCollection(
  StorageService storage,
  String collectionId, {
  String? environment,
}) async {
  try {
    final requests = await storage.getCollection(collectionId);

    if (requests.isEmpty) {
      throw Exception('Collection "$collectionId" not found or is empty');
    }

    // Get environment
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

    final results = <RequestExecutionResult>[];

    for (final request in requests) {
      final reqData = request['data'] as Map<String, dynamic>;
      final httpRequestModel = HttpRequestModel.fromJson(reqData);

      var requestModel = httpRequestModel;

      // Apply environment
      if (envVars.isNotEmpty) {
        requestModel = storage.applyEnvironment(requestModel, envVars);
      }

      // Execute the request
      final execId = request['id'] as String;
      final (response, duration, error) = await sendHttpRequest(
        execId,
        APIType.rest,
        requestModel,
      );

      final requestName = request['name'] as String? ??
          '${requestModel.method.name.toUpperCase()} ${requestModel.url}';

      if (error != null) {
        results.add(RequestExecutionResult(
          requestId: execId,
          requestName: requestName,
          success: false,
          error: error,
        ));
      } else if (response != null) {
        final httpResponseModel = HttpResponseModel().fromResponse(
          response: response,
          time: duration,
        );

        results.add(RequestExecutionResult(
          requestId: execId,
          requestName: requestName,
          success: true,
          statusCode: httpResponseModel.statusCode,
          time: duration?.inMilliseconds,
        ));
      }
    }

    return results;
  } catch (e) {
    rethrow;
  }
}

/// Registers the exec_collection tool
void registerExecCollectionTool(
  Server server, {
  required StorageService storage,
}) {
  server.addTool(
    name: 'exec_collection',
    description: 'Execute all requests in a collection sequentially',
    inputSchema: {
      'type': 'object',
      'properties': {
        'collection_id': {
          'type': 'string',
          'description': 'The collection ID to execute',
        },
        'environment': {
          'type': 'string',
          'description': 'Environment name to use for variable resolution',
        },
      },
      'required': ['collection_id'],
    },
    handler: (arguments) async {
      try {
        final collectionId = arguments['collection_id'] as String;
        final environment = arguments['environment'] as String?;

        final results = await executeCollection(
          storage,
          collectionId,
          environment: environment,
        );

        final summary = {
          'collectionId': collectionId,
          'total': results.length,
          'success': results.where((r) => r.success).length,
          'failed': results.where((r) => !r.success).length,
          'results': results.map((r) => r.toJson()).toList(),
        };

        return CallToolResult(
          content: [
            TextContent(text: jsonEncode(summary)),
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
