import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:apidash_mcp/apidash_mcp.dart';

/// Entry point for the API Dash MCP Server.
///
/// Starts the server using stdio transport, which is the standard
/// transport mechanism for local MCP servers.
void main() async {
  final server = ApiDashMcpServer();

  // Use stdio transport for communication with MCP clients
  server.connect(StdioTransport());

  // Log to stderr so it doesn't interfere with MCP protocol on stdout
  stderr.writeln('API Dash MCP Server started (stdio transport)');
  stderr.writeln(
      'Tools available: send_request, inspect_response, generate_curl');
}
