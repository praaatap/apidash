import 'package:args/command_runner.dart';
import 'commands/exec_command.dart';
import 'commands/init_command.dart';
import 'commands/run_command.dart';
import 'commands/list_command.dart';
import 'commands/env_command.dart';
import 'commands/mcp_command.dart';
import 'commands/open_command.dart';
import 'commands/replay_command.dart';

const String kCliVersion = '0.0.1-dev';

/// CliRunner wires commands and global flags.
class CliRunner extends CommandRunner<void> {
  CliRunner()
    : super(
        'apidash',
        'API Dash CLI - run and inspect HTTP requests from your terminal.',
        usageLineLength: 80,
      ) {
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current CLI version.',
      )
      ..addFlag(
        'verbose',
        negatable: false,
        help: 'Print detailed output including request/response headers.',
      )
      ..addFlag('quiet', negatable: false, help: 'Suppress non-error output.')
      ..addOption(
        'workspace',
        abbr: 'w',
        help: 'Workspace path (overrides config and APIDASH_WORKSPACE_PATH)',
      );

    addCommand(InitCommand());
    addCommand(ExecCommand());
    addCommand(RunCommand());
    addCommand(ListCommand());
    addCommand(EnvCommand());
    addCommand(McpCommand());
    addCommand(OpenCommand());
    addCommand(ReplayCommand());
  }

  @override
  Future<void> run(Iterable<String> args) async {
    final argResults = parse(args);

    if (argResults['version'] == true) {
      print('apidash_cli v$kCliVersion');
      return;
    }

    if (argResults['verbose'] == true && argResults['quiet'] == true) {
      throw UsageException('Cannot use --verbose and --quiet together.', usage);
    }

    await super.run(args);
  }
}
