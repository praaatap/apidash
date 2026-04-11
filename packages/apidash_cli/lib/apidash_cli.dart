/// API Dash CLI - Command-line interface for API Dash
///
/// This library provides a command-line interface for executing and managing
/// HTTP requests from your terminal.
///
/// Available commands:
/// - `init` - Initialize a new API Dash workspace
/// - `exec` - Execute an ad-hoc HTTP request
/// - `run` - Execute a collection, folder, or request
/// - `list` - List collections, requests, or request details
/// - `env` - Manage environment variables
/// - `mcp` - Run the MCP server for AI agent integration
/// - `open` - Open the API Dash Desktop application
library;

export 'src/cli_runner.dart' show CliRunner;
export 'src/commands/base_command.dart' show BaseCommand;
export 'src/commands/exec_command.dart' show ExecCommand;
export 'src/commands/init_command.dart' show InitCommand;
export 'src/commands/run_command.dart' show RunCommand;
export 'src/commands/list_command.dart' show ListCommand;
export 'src/commands/env_command.dart' show EnvCommand;
export 'src/commands/mcp_command.dart' show McpCommand;
export 'src/commands/open_command.dart' show OpenCommand;
export 'src/runner.dart' show runCli;
