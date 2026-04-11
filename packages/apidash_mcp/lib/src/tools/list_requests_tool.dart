import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:better_networking/better_networking.dart';
import 'package:mcp_server/mcp_server.dart';

/// Request summary with basic information
class RequestSummary {
  const RequestSummary({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
  });

  final String id;
  final String name;
  final String method;
  final String url;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'method': method,
        'url': url,
      };
}

/// Lists all requests in a collection
Future<List<RequestSummary>> listRequestsFromCollection(
  StorageService storage,
  String collectionId,
) async {
  try {
    final requests = await storage.getCollection(collectionId);
    final output = <RequestSummary>[];

    for (final request in requests) {
      final httpRequestModel = HttpRequestModel.fromJson(
        Map<String, Object?>.from(request['data'] as Map),
      );

      output.add(RequestSummary(
        id: request['id'] as String,
        name: request['name'] as String? ??
            '${httpRequestModel.method.name.toUpperCase()} ${httpRequestModel.url}',
        method: httpRequestModel.method.name.toUpperCase(),
        url: httpRequestModel.url,
      ));
    }

    return output;
  } catch (e) {
    rethrow;
  }
}

/// Registers the list_requests tool
void registerListRequestsTool(
  Server server, {
  required StorageService storage,
}) {
  server.addTool(
    name: 'list_requests',
    description: 'List all requests in a specific collection',
    inputSchema: {
      'type': 'object',
      'properties': {
        'collection_id': {
          'type': 'string',
          'description': 'The collection ID to list requests from',
        },
      },
      'required': ['collection_id'],
    },
    handler: (arguments) async {
      try {
        final collectionId = arguments['collection_id'] as String;
        final requests = await listRequestsFromCollection(storage, collectionId);
        final payload = requests.map((r) => r.toJson()).toList();
        return CallToolResult(
          content: [
            TextContent(text: jsonEncode(payload)),
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
