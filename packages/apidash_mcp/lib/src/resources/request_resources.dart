import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:mcp_server/mcp_server.dart';

/// URI patterns for resource routing
final RegExp _requestUriPattern = RegExp(r'^apidash://requests/([^/]+)/([^/]+)$');
final RegExp _environmentUriPattern = RegExp(r'^apidash://environments/([^/]+)$');
final RegExp _collectionIndexUriPattern = RegExp(r'^apidash://collections/([^/]+)/index$');
const String _workspaceConfigUri = 'apidash://workspace/config';

/// Parses a request URI and extracts collection and request IDs
Match? parseRequestUri(String uri) => _requestUriPattern.firstMatch(uri);

/// Parses an environment URI and extracts environment name
Match? parseEnvironmentUri(String uri) => _environmentUriPattern.firstMatch(uri);

/// Parses a collection index URI and extracts collection ID
Match? parseCollectionIndexUri(String uri) => _collectionIndexUriPattern.firstMatch(uri);

/// Gets a request resource as JSON
Future<Map<String, dynamic>> getRequestResource(
  StorageService storage,
  String collectionId,
  String requestId,
) async {
  final request = await storage.getRequest(requestId);
  if (request == null) {
    throw Exception('Request "$requestId" not found in collection "$collectionId"');
  }

  return {
    'id': requestId,
    'collectionId': collectionId,
    'method': request.method.name.toUpperCase(),
    'url': request.url,
    'headers': (request.headers ?? []).map((h) => {'name': h.name, 'value': h.value}).toList(),
    'params': (request.params ?? []).map((p) => {'name': p.name, 'value': p.value}).toList(),
    if (request.body != null) 'body': request.body,
    if (request.authModel != null) 'auth': request.authModel!.toJson(),
  };
}

/// Gets an environment resource as JSON
Future<Map<String, dynamic>> getEnvironmentResource(
  StorageService storage,
  String environmentName,
) async {
  final variables = await storage.getEnvironment(environmentName);
  final envs = await storage.listEnvironments();
  
  if (!envs.contains(environmentName)) {
    throw Exception('Environment "$environmentName" not found');
  }

  return {
    'name': environmentName,
    'variableCount': variables.length,
    'variables': variables.entries.map((e) => {'key': e.key, 'value': e.value}).toList(),
  };
}

/// Gets workspace configuration resource
Future<Map<String, dynamic>> getWorkspaceConfigResource(StorageService storage) async {
  final activeEnv = await storage.getSetting<String>('activeEnvironment', defaultValue: 'global');
  
  return {
    'activeEnvironment': activeEnv,
    'isReadOnly': storage.isReadOnly,
    'supportedSchemes': ['http', 'https'],
    'redactedHeaders': ['authorization', 'x-api-key', 'cookie', 'set-cookie'],
    'version': '0.0.1-dev',
  };
}

/// Gets a collection index resource (flat metadata list)
Future<List<Map<String, dynamic>>> getCollectionIndexResource(
  StorageService storage,
  String collectionId,
) async {
  final requests = await storage.getCollection(collectionId);
  return requests.map((r) => {
    'id': r['id'],
    'name': r['name'],
    'method': r['method'],
    'url': r['url'],
  }).toList();
}

/// Registers all MCP resources with the server
/// 
/// Due to mcp_server v1.0.3 API limitations with resource templates,
/// resources are exposed via a dedicated `get_resource` tool that follows
/// the exact same URI patterns and returns MCP-compliant resource responses.
/// This is a standard MCP workaround pattern.
void registerResources(
  Server server, {
  required StorageService storage,
}) {
  // Resource gateway tool - provides full resource access via MCP tool interface
  server.addTool(
    name: 'get_resource',
    description: 'Read workspace data via URI-based resource access (apidash://requests/..., apidash://environments/..., apidash://collections/.../index, apidash://workspace/config)',
    inputSchema: {
      'type': 'object',
      'properties': {
        'uri': {
          'type': 'string',
          'description': 'Resource URI (e.g., apidash://requests/default/req_123, apidash://environments/production, apidash://workspace/config)',
        },
      },
      'required': ['uri'],
    },
    handler: (arguments) async {
      try {
        final uri = arguments['uri'] as String;
        dynamic content;

        // Route to appropriate resource handler
        final requestMatch = parseRequestUri(uri);
        if (requestMatch != null) {
          final collectionId = requestMatch.group(1)!;
          final requestId = requestMatch.group(2)!;
          content = await getRequestResource(storage, collectionId, requestId);
        } else if (parseEnvironmentUri(uri) != null) {
          final envName = parseEnvironmentUri(uri)!.group(1)!;
          content = await getEnvironmentResource(storage, envName);
        } else if (parseCollectionIndexUri(uri) != null) {
          final collectionId = parseCollectionIndexUri(uri)!.group(1)!;
          content = await getCollectionIndexResource(storage, collectionId);
        } else if (uri == _workspaceConfigUri) {
          content = await getWorkspaceConfigResource(storage);
        } else {
          return CallToolResult(
            content: [TextContent(text: jsonEncode({'error': 'Unknown resource URI: $uri'}))],
            isError: true,
          );
        }

        return CallToolResult(
          content: [
            TextContent(
              text: jsonEncode({
                'uri': uri,
                'mimeType': 'application/json',
                'data': content,
              }),
            ),
          ],
        );
      } catch (e) {
        return CallToolResult(
          content: [TextContent(text: jsonEncode({'error': e.toString()}))],
          isError: true,
        );
      }
    },
  );

  // List available resources tool
  server.addTool(
    name: 'list_resources',
    description: 'List all available MCP resources and their URI patterns',
    inputSchema: {
      'type': 'object',
      'properties': {},
    },
    handler: (arguments) async {
      final collections = await storage.listCollections();
      final environments = await storage.listEnvironments();

      final resources = [
        {
          'uri': 'apidash://workspace/config',
          'name': 'Workspace Config',
          'description': 'Global workspace settings and configuration',
          'mimeType': 'application/json',
        },
        for (final env in environments)
          {
            'uri': 'apidash://environments/$env',
            'name': 'Environment: $env',
            'description': 'Environment variables for API request substitution',
            'mimeType': 'application/json',
          },
        for (final collection in collections)
          {
            'uri': 'apidash://collections/$collection/index',
            'name': 'Collection Index: $collection',
            'description': 'Flat list of request metadata in collection',
            'mimeType': 'application/json',
          },
        {
          'uri': 'apidash://requests/{collection_id}/{request_id}',
          'name': 'Request Detail',
          'description': 'Full request configuration (use list_requests to find IDs)',
          'mimeType': 'application/json',
          'pattern': true,
        },
      ];

      return CallToolResult(
        content: [TextContent(text: jsonEncode({'resources': resources, 'count': resources.length}))],
      );
    },
  );
}
