import 'dart:io';
import 'package:args/args.dart';
import 'package:mcp_server/mcp_server.dart';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'tools/list_collections_tool.dart';
import 'tools/list_requests_tool.dart';
import 'tools/get_request_detail_tool.dart';
import 'tools/exec_request_tool.dart';
import 'tools/exec_collection_tool.dart';
import 'tools/exec_folder_tool.dart';
import 'tools/list_environments_tool.dart';
import 'resources/request_resources.dart';
import 'prompts/api_prompts.dart';

const String kMcpServerVersion = '0.0.1-dev';

/// Starts the MCP server over stdio.
///
/// The server reads the workspace path from command line arguments,
/// APIDASH_WORKSPACE_PATH environment variable, or resolves it automatically.
Future<void> runServer(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('workspace', abbr: 'w', help: 'Path to the API Dash workspace');

  final results = parser.parse(arguments);
  String? workspacePath = results['workspace'] as String?;

  if (workspacePath == null || workspacePath.trim().isEmpty) {
    workspacePath = await resolveWorkspacePath();
  }

  if (workspacePath == null || workspacePath.trim().isEmpty) {
    stderr.writeln(
      'Error: No API Dash workspace found.\n'
      'Please specify one using --workspace <path> or set the APIDASH_WORKSPACE_PATH environment variable.',
    );
    exitCode = 64;
    return;
  }

  // Ensure workspace exists
  final workspaceDir = Directory(workspacePath);
  if (!workspaceDir.existsSync()) {
    stderr.writeln('Error: Workspace directory does not exist: $workspacePath');
    exitCode = 64;
    return;
  }

  // Initialize Storage Service
  final storage = StorageService();
  await storage.initialize(workspacePath: workspacePath);

  final config = McpServerConfig(
    name: 'apidash_mcp',
    version: kMcpServerVersion,
    capabilities: ServerCapabilities.simple(
      tools: true,
      resources: true,
      prompts: true,
    ),
  );

  final serverResult = await McpServer.createAndStart(
    config: config,
    transportConfig: TransportConfig.stdio(),
  );

  serverResult.fold(
    (server) {
      // Register Tools
      registerListCollectionsTool(server, storage: storage);
      registerListRequestsTool(server, storage: storage);
      registerGetRequestDetailTool(server, storage: storage);
      registerExecRequestTool(server, storage: storage);
      registerExecCollectionTool(server, storage: storage);
      registerExecFolderTool(server, storage: storage);
      registerListEnvironmentsTool(server, storage: storage);
      registerGetEnvironmentVariablesTool(server, storage: storage);

      // Register Resources
      registerResources(server, storage: storage);

      // Register Prompts
      registerPrompts(server);

      stderr.writeln(
        'APIDash MCP server v$kMcpServerVersion started successfully',
      );
      stderr.writeln(
        'Workspace: $workspacePath',
      );
    },
    (error) {
      stderr.writeln('Failed to start MCP server: $error');
      exitCode = 1;
    },
  );
}
