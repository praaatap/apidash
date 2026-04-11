import 'package:apidash_shared_storage/apidash_shared_storage.dart';

import 'base_command.dart';

/// Command to initialize an API Dash HIS workspace
class InitCommand extends BaseCommand {
  @override
  String get name => 'init';

  @override
  String get description => 'Create API Dash HIS workspace';

  InitCommand() {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Workspace path (absolute path required)',
    );
  }

  @override
  Future<void> execute() async {
    final results = argResults;
    if (results == null) {
      log.err('Unable to read parsed arguments.');
      return;
    }

    final workspacePath = (results['path'] as String?)?.trim();
    if (workspacePath == null || workspacePath.isEmpty) {
      log.err('Missing path. Usage: apidash init --path=<path>');
      return;
    }

    try {
      final storage = StorageService();
      final expandedPath = expandPath(workspacePath);
      await storage.initialize(workspacePath: expandedPath);
      await storage.saveEnvironment('global', {});

      final workspaceUri = generateApidashUri(expandedPath);
      await writeGlobalWorkspaceConfig(workspaceUri);
      await writeLocalWorkspaceConfig(expandedPath);

      await storage.close();

      log.success('Workspace created at $expandedPath');
      log.info(
        'Run this in your shell to set workspace path: '
        'export APIDASH_WORKSPACE_PATH="$expandedPath"',
      );
    } catch (e) {
      log.err('Failed to create workspace: $e');
    }
  }
}
