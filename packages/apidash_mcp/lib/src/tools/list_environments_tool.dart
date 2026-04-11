// ignore_for_file: unused_import
import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:better_networking/better_networking.dart';
import 'package:mcp_server/mcp_server.dart';

/// Lists all available environments in the workspace
Future<List<String>> listEnvironments(StorageService storage) async {
  try {
    final environmentIds = await storage.listEnvironments();
    return environmentIds;
  } catch (e) {
    rethrow;
  }
}

/// Gets the variables in a specific environment
Future<Map<String, String>> getEnvironmentVariables(
  StorageService storage,
  String environmentName,
) async {
  try {
    final variables = await storage.getEnvironment(environmentName);
    return variables;
  } catch (e) {
    rethrow;
  }
}

/// Registers the list_environments tool
void registerListEnvironmentsTool(
  Server server, {
  required StorageService storage,
}) {
  server.addTool(
    name: 'list_environments',
    description: 'List all available environments in the workspace',
    inputSchema: {'type': 'object', 'properties': {}},
    handler: (arguments) async {
      try {
        final environments = await listEnvironments(storage);
        return CallToolResult(
          content: [
            TextContent(text: jsonEncode(environments)),
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

/// Registers the get_environment_variables tool
void registerGetEnvironmentVariablesTool(
  Server server, {
  required StorageService storage,
}) {
  server.addTool(
    name: 'get_environment_variables',
    description: 'Get all variables in a specific environment',
    inputSchema: {
      'type': 'object',
      'properties': {
        'environment_name': {
          'type': 'string',
          'description': 'The name of the environment to get variables from',
        },
      },
      'required': ['environment_name'],
    },
    handler: (arguments) async {
      try {
        final envName = arguments['environment_name'] as String;
        final variables = await getEnvironmentVariables(storage, envName);
        return CallToolResult(
          content: [
            TextContent(text: jsonEncode(variables)),
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
