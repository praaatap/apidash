import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:mcp_server/mcp_server.dart';

/// Detailed request information
class RequestDetail {
  const RequestDetail({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.headers = const [],
    this.params = const [],
    this.body,
    this.auth,
  });

  final String id;
  final String name;
  final String method;
  final String url;
  final List<Map<String, String>> headers;
  final List<Map<String, String>> params;
  final String? body;
  final Map<String, dynamic>? auth;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'method': method,
        'url': url,
        'headers': headers,
        'params': params,
        if (body != null) 'body': body,
        if (auth != null) 'auth': auth,
      };
}

/// Gets detailed information about a specific request
Future<RequestDetail> getRequestDetail(
  StorageService storage,
  String collectionId,
  String requestId,
) async {
  try {
    final httpRequestModel = await storage.getRequest(requestId);

    if (httpRequestModel == null) {
      throw Exception('Request "$requestId" not found');
    }

    // Build headers list
    final headers = <Map<String, String>>[];
    final modelHeaders = httpRequestModel.headers ?? [];
    final modelHeaderEnabled = httpRequestModel.isHeaderEnabledList ?? [];
    for (var i = 0; i < modelHeaders.length; i++) {
      final header = modelHeaders[i];
      final isEnabled = i < modelHeaderEnabled.length
          ? modelHeaderEnabled[i]
          : true;
      headers.add({
        'name': header.name,
        'value': header.value.toString(),
        'enabled': isEnabled.toString(),
      });
    }

    // Build params list
    final params = <Map<String, String>>[];
    final modelParams = httpRequestModel.params ?? [];
    final modelParamEnabled = httpRequestModel.isParamEnabledList ?? [];
    for (var i = 0; i < modelParams.length; i++) {
      final param = modelParams[i];
      final isEnabled = i < modelParamEnabled.length
          ? modelParamEnabled[i]
          : true;
      params.add({
        'name': param.name,
        'value': param.value.toString(),
        'enabled': isEnabled.toString(),
      });
    }

    // Build auth info
    Map<String, dynamic>? auth;
    if (httpRequestModel.authModel != null) {
      auth = httpRequestModel.authModel!.toJson();
    }

    // Get request metadata from collection
    final requests = await storage.getCollection(collectionId);
    final requestMeta = requests.firstWhere(
      (r) => r['id'] == requestId,
      orElse: () => <String, Object?>{},
    );

    return RequestDetail(
      id: requestId,
      name: requestMeta['name'] as String? ?? requestId,
      method: httpRequestModel.method.name.toUpperCase(),
      url: httpRequestModel.url,
      headers: headers,
      params: params,
      body: httpRequestModel.body,
      auth: auth,
    );
  } catch (e) {
    rethrow;
  }
}

/// Registers the get_request_detail tool
void registerGetRequestDetailTool(
  Server server, {
  required StorageService storage,
}) {
  server.addTool(
    name: 'get_request_detail',
    description: 'Get complete details of a saved request including headers, params, body, and auth',
    inputSchema: {
      'type': 'object',
      'properties': {
        'collection_id': {
          'type': 'string',
          'description': 'The collection ID containing the request',
        },
        'request_id': {
          'type': 'string',
          'description': 'The request ID to get details for',
        },
      },
      'required': ['collection_id', 'request_id'],
    },
    handler: (arguments) async {
      try {
        final collectionId = arguments['collection_id'] as String;
        final requestId = arguments['request_id'] as String;

        final detail = await getRequestDetail(
          storage,
          collectionId,
          requestId,
        );

        return CallToolResult(
          content: [
            TextContent(text: jsonEncode(detail.toJson())),
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
