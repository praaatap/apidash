import 'dart:io';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'base_command.dart';

/// Command to run the MCP server
class McpCommand extends BaseCommand {
  McpCommand() {
    argParser.addOption(
      'workspace',
      abbr: 'w',
      help: 'Workspace path for the MCP server',
    );
    argParser.addFlag(
      'headless',
      help:
          'Run strictly in headless mode (no informational logs on stdout, stdio piped directly)',
      negatable: false,
    );
  }

  @override
  String get name => 'mcp';

  @override
  String get description => 'Run the MCP server for AI agent integration';

  @override
  Future<void> execute() async {
    final results = argResults;
    if (results == null) {
      log.err('Unable to read parsed arguments.');
      return;
    }

    final workspacePath = (results['workspace'] as String?)?.trim();
    final isHeadless = results['headless'] as bool? ?? false;

    try {
      String? finalWorkspacePath;

      if (workspacePath != null && workspacePath.isNotEmpty) {
        finalWorkspacePath = workspacePath;
      } else {
        // Try to resolve workspace from config or environment
        final resolvedPath = await resolveWorkspacePath(null);
        if (resolvedPath != null) {
          finalWorkspacePath = resolvedPath;
        }
      }

      if (finalWorkspacePath == null) {
        if (!isHeadless) {
          log.err(
            'No workspace specified. Use --workspace <path> or set '
            'APIDASH_WORKSPACE_PATH environment variable.',
          );
        } else {
          stderr.writeln('Error: No workspace specified.');
        }
        return;
      }

      if (!isHeadless) {
        // APIDash Theme Color (Orange/Amber) ANSI escape code
        const String apiDashAnsiBlue = '\x1B[38;5;75m';
        const String reset = '\x1B[0m';

        stderr.writeln(apiDashAnsiBlue);
        stderr.writeln(r'''
    ___    ____  ________  ____   _____ __ __
   /   |  / __ \/  _/ __ \/ __ \ / ___// // /
  / /| | / /_/ // // / / / /_/ / \__ \/ // / 
 / ___ |/ ____// // /_/ / __  / ___/ / __  / 
/_/  |_/_/   /___/_____/_/ /_/ /____/_/ /_/  
''');
        stderr.writeln('${reset}Starting APIDash MCP server...');
        stderr.writeln('Workspace: $finalWorkspacePath\n');
        stderr.writeln('The MCP server is now running on stdio.');
        stderr.writeln(
          'Connect your AI assistant (Claude Desktop, VS Code, Cursor) to interact.\n',
        );
        stderr.writeln('Press Ctrl+C to stop the server.\n');
      }

      // Start the MCP server process with piped io
      final process = await Process.start(
        'dart',
        ['run', 'apidash_mcp'],
        environment: {'APIDASH_WORKSPACE_PATH': finalWorkspacePath},
        workingDirectory: null,
      );

      // Pipe standard streams
      stdin.pipe(process.stdin);
      process.stdout.listen((data) => stdout.add(data));
      process.stderr.listen((data) => stderr.add(data));

      final exitCode = await process.exitCode;

      if (exitCode != 0 && !isHeadless) {
        log.err('MCP server exited with code $exitCode');
      }
      exit(exitCode);
    } catch (e) {
      if (!isHeadless) {
        log.err('Failed to start MCP server: $e');
      } else {
        stderr.writeln('Failed to start MCP server: $e');
      }
      exit(1);
    }
  }
}
