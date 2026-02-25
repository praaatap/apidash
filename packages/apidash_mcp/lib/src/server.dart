import 'dart:convert';
import 'dart:async';

import 'package:dart_mcp/server.dart';
import 'package:better_networking/better_networking.dart';

/// MCP server that exposes API Dash HTTP capabilities as tools.
///
/// Uses [ToolsSupport] to register three tools:
/// - `send_request`: Send an HTTP request and return the response.
/// - `inspect_response`: Inspect the response details.
/// - `generate_curl`: Generate a cURL command from+96
///  request params.
final class ApiDashMcpServer extends MCPServer with ToolsSupport {
  ApiDashMcpServer(
    super.channel, {
    super.protocolLogSink,
  }) : super.fromStreamChannel(
          implementation: Implementation(
            name: 'apidash-mcp',
            version: '0.0.1',
          ),
          instructions:
              'API Dash MCP Server exposes HTTP request capabilities. '
              'Use the available tools to send requests, inspect responses, '
              'and generate cURL commands.',
        );

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) async {
    registerTool(_sendRequestTool, _handleSendRequest);
    registerTool(_inspectResponseTool, _handleInspectResponse);
    registerTool(_generateCurlTool, _handleGenerateCurl);

    return super.initialize(request);
  }

  // -- send_request ----------------------------------------------------------

  static final _sendRequestTool = Tool(
    name: 'send_request',
    description: 'Send an HTTP request using API Dash and return the response.',
    inputSchema: ObjectSchema(
      properties: {
        'url': Schema.string(description: 'Target URL'),
        'method': Schema.string(
          description: 'HTTP method (GET, POST, PUT, PATCH, DELETE, HEAD). '
              'Defaults to GET.',
        ),
        'headers': Schema.string(
          description: 'Request headers as a JSON object string.',
        ),
        'body': Schema.string(description: 'Request body string.'),
      },
      required: ['url'],
    ),
  );

  Future<CallToolResult> _handleSendRequest(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final url = args['url'] as String;
    final method = _parseMethod(args['method'] as String?);
    final headers = _parseHeaders(args['headers'] as String?);
    final body = args['body'] as String?;

    final requestModel = HttpRequestModel(
      url: url,
      method: method,
      headers: headers,
      body: body,
    );

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
  }

  // -- inspect_response ------------------------------------------------------

  static final _inspectResponseTool = Tool(
    name: 'inspect_response',
    description: 'Send a request and inspect the response details including '
        'content type, size, headers, and body preview.',
    inputSchema: ObjectSchema(
      properties: {
        'url': Schema.string(description: 'Target URL'),
        'method': Schema.string(description: 'HTTP method. Defaults to GET.'),
        'headers': Schema.string(
          description: 'Request headers as a JSON object string.',
        ),
        'body': Schema.string(description: 'Request body string.'),
      },
      required: ['url'],
    ),
  );

  Future<CallToolResult> _handleInspectResponse(
    CallToolRequest request,
  ) async {
    final args = request.arguments ?? {};
    final url = args['url'] as String;
    final method = _parseMethod(args['method'] as String?);
    final headers = _parseHeaders(args['headers'] as String?);
    final body = args['body'] as String?;

    final requestModel = HttpRequestModel(
      url: url,
      method: method,
      headers: headers,
      body: body,
    );

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
  }

  // -- generate_curl ---------------------------------------------------------

  static final _generateCurlTool = Tool(
    name: 'generate_curl',
    description: 'Generate a cURL command for the given request parameters.',
    inputSchema: ObjectSchema(
      properties: {
        'url': Schema.string(description: 'Target URL'),
        'method': Schema.string(description: 'HTTP method. Defaults to GET.'),
        'headers': Schema.string(
          description: 'Request headers as a JSON object string.',
        ),
        'body': Schema.string(description: 'Request body string.'),
      },
      required: ['url'],
    ),
  );

  Future<CallToolResult> _handleGenerateCurl(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final url = args['url'] as String;
    final method = (args['method'] as String? ?? 'GET').toUpperCase();
    final headersStr = args['headers'] as String?;
    final body = args['body'] as String?;

    final buffer = StringBuffer("curl -X $method '$url'");

    if (headersStr != null && headersStr.isNotEmpty) {
      try {
        final parsed = jsonDecode(headersStr) as Map<String, dynamic>;
        for (final entry in parsed.entries) {
          buffer.write(" -H '${entry.key}: ${entry.value}'");
        }
      } catch (_) {
        // Skip malformed headers
      }
    }

    if (body != null && body.isNotEmpty) {
      final escaped = body.replaceAll("'", "'\\''");
      buffer.write(" -d '$escaped'");
    }

    return CallToolResult(
      content: [TextContent(text: buffer.toString())],
    );
  }

  // -- Helpers ---------------------------------------------------------------

  static HTTPVerb _parseMethod(String? method) {
    switch (method?.toUpperCase()) {
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

  static List<NameValueModel>? _parseHeaders(String? headersJson) {
    if (headersJson == null || headersJson.isEmpty) return null;
    try {
      final parsed = jsonDecode(headersJson) as Map<String, dynamic>;
      return parsed.entries
          .map((e) => NameValueModel(name: e.key, value: e.value.toString()))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
