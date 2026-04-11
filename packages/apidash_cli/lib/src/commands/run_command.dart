import 'base_command.dart';

/// Command to run a collection, folder, or request
class RunCommand extends BaseCommand {
  RunCommand() {
    argParser
      ..addOption('collection', abbr: 'c', help: 'Collection ID to execute')
      ..addOption('folder', abbr: 'f', help: 'Folder ID to execute')
      ..addOption('request', abbr: 'r', help: 'Request ID to execute')
      ..addOption('env', abbr: 'e', help: 'Environment to use')
      ..addOption(
        'format',
        defaultsTo: 'table',
        allowed: ['table', 'json'],
        help: 'Output format',
      );
  }

  @override
  String get name => 'run';

  @override
  String get description => 'Execute a collection, folder, or request';

  @override
  Future<void> execute() async {
    log.info('Run command not fully implemented yet.');
  }
}
