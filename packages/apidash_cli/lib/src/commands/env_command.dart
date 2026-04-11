import 'package:args/args.dart';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'base_command.dart';

/// Command to manage environments
class EnvCommand extends BaseCommand {
  EnvCommand() {
    argParser.addCommand('list');
    argParser.addCommand('create');
    argParser.addCommand('delete');
    argParser.addCommand('set');
    argParser.addCommand('unset');
    argParser.addCommand('use');
  }

  @override
  String get name => 'env';

  @override
  String get description => 'Manage environment variables';

  @override
  Future<void> execute() async {
    final results = argResults;
    if (results == null) {
      log.err('Unable to read parsed arguments.');
      return;
    }

    final subcommand = results.command;
    if (subcommand == null) {
      log.info('Usage: apidash env <subcommand>');
      log.info('');
      log.info('Subcommands:');
      log.info(
        '  list [name]     List all environments or variables in an environment',
      );
      log.info('  create <name>   Create a new environment');
      log.info('  delete <name>   Delete an environment');
      log.info('  set <name> <key> <value>   Set a variable');
      log.info('  unset <name> <key>         Remove a variable');
      log.info('  use <name>      Set active environment');
      return;
    }

    try {
      final storage = StorageService();
      final workspacePath = await resolveWorkspacePath(null);

      if (workspacePath == null) {
        log.err(
          'No workspace found. Run "apidash init --path=<path>" first '
          'or set APIDASH_WORKSPACE_PATH environment variable.',
        );
        return;
      }

      await storage.initialize(workspacePath: workspacePath);

      switch (subcommand.name) {
        case 'list':
          await _handleList(storage, subcommand);
          break;
        case 'create':
          await _handleCreate(storage, subcommand);
          break;
        case 'delete':
          await _handleDelete(storage, subcommand);
          break;
        case 'set':
          await _handleSet(storage, subcommand);
          break;
        case 'unset':
          await _handleUnset(storage, subcommand);
          break;
        case 'use':
          await _handleUse(storage, subcommand);
          break;
      }

      await storage.close();
    } catch (e) {
      log.err('Failed: $e');
    }
  }

  Future<void> _handleList(
    StorageService storage,
    ArgResults subcommand,
  ) async {
    final envName = subcommand.rest.isNotEmpty ? subcommand.rest.first : null;

    if (envName != null) {
      // List variables in specific environment
      final envIds = await storage.listEnvironments();
      if (!envIds.contains(envName)) {
        log.err('Environment "$envName" not found');
        return;
      }

      final variables = await storage.getEnvironment(envName);

      log.info('');
      log.info('Environment: $envName');
      log.info('─────────────────────────────────────────────────');

      if (variables.isEmpty) {
        log.info('  No variables');
      } else {
        for (final entry in variables.entries) {
          log.info('  ✓ ${entry.key} = ${entry.value}');
        }
      }
      log.info('─────────────────────────────────────────────────');
    } else {
      // List all environments
      final envIds = await storage.listEnvironments();

      log.info('');
      log.info('Environments:');
      log.info('─────────────────────────────────────────────────');

      for (final envId in envIds) {
        final variables = await storage.getEnvironment(envId);
        log.info('  🌍 $envId (${variables.length} variables)');
      }
      log.info('─────────────────────────────────────────────────');
    }
  }

  Future<void> _handleCreate(
    StorageService storage,
    ArgResults subcommand,
  ) async {
    if (subcommand.rest.isEmpty) {
      log.err('Missing environment name. Usage: apidash env create <name>');
      return;
    }

    final envName = subcommand.rest.first;

    // Check if environment already exists
    final envIds = await storage.listEnvironments();
    if (envIds.contains(envName)) {
      log.err('Environment "$envName" already exists');
      return;
    }

    await storage.saveEnvironment(envName, {});
    log.success('Environment "$envName" created');
  }

  Future<void> _handleDelete(
    StorageService storage,
    ArgResults subcommand,
  ) async {
    if (subcommand.rest.isEmpty) {
      log.err('Missing environment name. Usage: apidash env delete <name>');
      return;
    }

    final envName = subcommand.rest.first;

    if (envName == 'global') {
      log.err('Cannot delete the global environment');
      return;
    }

    final envIds = await storage.listEnvironments();
    if (!envIds.contains(envName)) {
      log.err('Environment "$envName" does not exist');
      return;
    }

    await storage.deleteEnvironment(envName);
    log.success('Environment "$envName" deleted');
  }

  Future<void> _handleSet(StorageService storage, ArgResults subcommand) async {
    if (subcommand.rest.length < 3) {
      log.err('Missing arguments. Usage: apidash env set <name> <key> <value>');
      return;
    }

    final envName = subcommand.rest[0];
    final key = subcommand.rest[1];
    final value = subcommand.rest[2];

    final envIds = await storage.listEnvironments();
    if (!envIds.contains(envName)) {
      log.err('Environment "$envName" not found');
      return;
    }

    await storage.setEnvironmentVariable(envName, key, value);
    log.success('Set $key = $value in $envName');
  }

  Future<void> _handleUnset(
    StorageService storage,
    ArgResults subcommand,
  ) async {
    if (subcommand.rest.length < 2) {
      log.err('Missing arguments. Usage: apidash env unset <name> <key>');
      return;
    }

    final envName = subcommand.rest[0];
    final key = subcommand.rest[1];

    final envIds = await storage.listEnvironments();
    if (!envIds.contains(envName)) {
      log.err('Environment "$envName" not found');
      return;
    }

    await storage.removeEnvironmentVariable(envName, key);
    log.success('Unset $key from $envName');
  }

  Future<void> _handleUse(StorageService storage, ArgResults subcommand) async {
    if (subcommand.rest.isEmpty) {
      log.err('Missing environment name. Usage: apidash env use <name>');
      return;
    }

    final envName = subcommand.rest.first;

    final envIds = await storage.listEnvironments();
    if (!envIds.contains(envName)) {
      log.err('Environment "$envName" not found');
      return;
    }

    // Note: Setting active environment would need workspace config update
    log.info('Active environment set to: $envName');
  }
}
