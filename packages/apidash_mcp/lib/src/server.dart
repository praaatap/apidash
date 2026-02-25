import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:better_networking/better_networking.dart';

/// API Dash MCP Server
///
/// Exposes API Dash's core HTTP capabilities via the
/// Model Context Protocol (MCP), allowing AI agents to
/// send requests, inspect responses, and generate cURL commands.
class ApiDashMcpServer extends MCPServer with ToolsSupport {
  ApiDashMcpServer()
      : super(
          implementation: ServerImplementation(
            name: 'apidash-mcp',
            version: '0.0.1',
          ),
        );

  @override
  void initialize() {
    registerTool(sendRequestTool);
    registerTool(inspectResponseTool);
    registerTool(generateCurlTool);
  }

  // ---------------------------------------------------------------------------
  // Tool: send_request
  // ---------------------------------------------------------------------------
  Tool get sendRequestTool => Tool(
        name: 'send_request',
        description:
            'Send an HTTP request using API Dash and return the response. '
            'Supports GET, POST, PUT, PATCH, DELETE, and HEAD methods.',
        inputSchema: ObjectSchema(
          properties: {
            'url': Schema.string(description: 'Target URL (required)'),
            'method': Schema.string(
              description:
                  'HTTP method – GET, POST, PUT, PATCH, DELETE, HEAD. Default: GET',
            ),
            'headers': Schema.string(
              description:
                  'Request headers as a JSON object string, e.g. {"Authorization":"Bearer token"}',
            ),
            'body': Schema.string(
              description: 'Request body string (for POST/PUT/PATCH)',
            ),
          },
          required: ['url'],
        ),
      );

  Future<CallToolResult> handleSendRequest(
      Map<String, Object?> arguments) async {
    final url = arguments['url'] as String;
    final method = _parseMethod(arguments['method'] as String? ?? 'GET');
    final headers = _parseHeaders(arguments['headers'] as String?);
    final body = arguments['body'] as String?;

    final requestModel = HttpRequestModel(
      url: url,
      method: method,
      headers: headers,
      body: body,
    );

    try {
      final (response, duration, error) = await sendHttpRequest(
        'mcp-${DateTime.now().millisecondsSinceEpoch}',
        APIType.rest,
        requestModel,
      );

      if (error != null) {
        return CallToolResult(
          content: [TextContent(text: 'Error: $error')],
          isError: true,
        );
      }

      final result = {
        'status_code': response?.statusCode,
        'headers': response?.headers,
        'body': response?.body,
        'elapsed_ms': duration?.inMilliseconds,
      };

      return CallToolResult(
        content: [TextContent(text: jsonEncode(result))],
      );
    } catch (e) {
      return CallToolResult(
        content: [TextContent(text: 'Error: $e')],
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Tool: inspect_response
  // ---------------------------------------------------------------------------
  Tool get inspectResponseTool => Tool(
        name: 'inspect_response',
        description:
            'Send an HTTP request and deeply inspect the response. '
            'Returns status, content type, size, headers, and a body preview.',
        inputSchema: ObjectSchema(
          properties: {
            'url': Schema.string(description: 'Target URL (required)'),
            'method': Schema.string(
              description: 'HTTP method. Default: GET',
            ),
            'headers': Schema.string(
              description: 'Request headers as a JSON object string',
            ),
            'body': Schema.string(
              description: 'Request body string',
            ),
          },
          required: ['url'],
        ),
      );

  Future<CallToolResult> handleInspectResponse(
      Map<String, Object?> arguments) async {
    final url = arguments['url'] as String;
    final method = _parseMethod(arguments['method'] as String? ?? 'GET');
    final headers = _parseHeaders(arguments['headers'] as String?);
    final body = arguments['body'] as String?;

    final requestModel = HttpRequestModel(
      url: url,
      method: method,
      headers: headers,
      body: body,
    );

    try {
      final (response, duration, error) = await sendHttpRequest(
        'mcp-inspect-${DateTime.now().millisecondsSinceEpoch}',
        APIType.rest,
        requestModel,
      );

      if (error != null) {
        return CallToolResult(
          content: [TextContent(text: 'Error: $error')],
          isError: true,
        );
      }

      final responseBody = response?.body ?? '';
      final bodyPreview = responseBody.length > 500
          ? '${responseBody.substring(0, 500)}...'
          : responseBody;

      final result = {
        'status_code': response?.statusCode,
        'content_type': response?.headers['content-type'],
        'response_size_bytes': responseBody.length,
        'elapsed_ms': duration?.inMilliseconds,
        'headers': response?.headers,
        'body_preview': bodyPreview,
      };

      return CallToolResult(
        content: [TextContent(text: jsonEncode(result))],
      );
    } catch (e) {
      return CallToolResult(
        content: [TextContent(text: 'Error: $e')],
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Tool: generate_curl
  // ---------------------------------------------------------------------------
  Tool get generateCurlTool => Tool(
        name: 'generate_curl',
        description:
            'Generate a cURL command for the given HTTP request parameters.',
        inputSchema: ObjectSchema(
          properties: {
            'url': Schema.string(description: 'Target URL (required)'),
            'method': Schema.string(
              description: 'HTTP method. Default: GET',
            ),
            'headers': Schema.string(
              description: 'Request headers as a JSON object string',
            ),
            'body': Schema.string(
              description: 'Request body string',
            ),
          },
          required: ['url'],
        ),
      );

  Future<CallToolResult> handleGenerateCurl(
      Map<String, Object?> arguments) async {
    final url = arguments['url'] as String;
    final method = (arguments['method'] as String? ?? 'GET').toUpperCase();
    final headersStr = arguments['headers'] as String?;
    final body = arguments['body'] as String?;

    final buffer = StringBuffer();
    buffer.write("curl -X $method '$url'");

    if (headersStr != null && headersStr.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(headersStr);
        for (final entry in parsed.entries) {
          buffer.write(" -H '${entry.key}: ${entry.value}'");
        }
      } catch (_) {
        // If headers can't be parsed, skip them
      }
    }

    if (body != null && body.isNotEmpty) {
      final escapedBody = body.replaceAll("'", "'\\''");
      buffer.write(" -d '$escapedBody'");
    }

    return CallToolResult(
      content: [TextContent(text: buffer.toString())],
    );
  }

  // ---------------------------------------------------------------------------
  // Tool dispatch
  // ---------------------------------------------------------------------------
  @override
  Future<CallToolResult> callTool(CallToolRequest request) async {
    switch (request.params.name) {
      case 'send_request':
        return handleSendRequest(request.params.arguments ?? {});
      case 'inspect_response':
        return handleInspectResponse(request.params.arguments ?? {});
      case 'generate_curl':
        return handleGenerateCurl(request.params.arguments ?? {});
      default:
        return CallToolResult(
          content: [TextContent(text: 'Unknown tool: ${request.params.name}')],
          isError: true,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  HTTPVerb _parseMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HTTPVerb.get;
      case 'POST':
        return HTTPVerb.post;
      case 'PUT':
        return HTTPVerb.put;
      case 'PATCH':
        return HTTPVerb.patch;
      case 'DELETE':
        return HTTPVerb.delete;
      case 'HEAD':
        return HTTPVerb.head;
      case 'OPTIONS':
        return HTTPVerb.options;
      default:
        return HTTPVerb.get;
    }
  }

  List<NameValueModel>? _parseHeaders(String? headersJson) {
    if (headersJson == null || headersJson.isEmpty) return null;
    try {
      final Map<String, dynamic> parsed = jsonDecode(headersJson);
      return parsed.entries
          .map((e) => NameValueModel(name: e.key, value: e.value.toString()))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
