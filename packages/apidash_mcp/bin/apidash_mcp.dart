import 'dart:io';

import 'package:dart_mcp/stdio.dart';
import 'package:apidash_mcp/apidash_mcp.dart';

void main() {
  final channel = stdioChannel(input: stdin, output: stdout);
  ApiDashMcpServer(channel);

  stderr.writeln('API Dash MCP Server started (stdio)');
}
