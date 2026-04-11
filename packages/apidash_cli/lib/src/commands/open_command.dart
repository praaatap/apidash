import 'dart:io';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'base_command.dart';

/// Command to open the API Dash Desktop application
class OpenCommand extends BaseCommand {
  OpenCommand() {
    argParser.addOption(
      'workspace',
      abbr: 'w',
      help: 'Workspace path to open in the app',
    );
  }

  @override
  String get name => 'open';

  @override
  List<String> get aliases => ['start', 'gui'];

  @override
  String get description => 'Open the API Dash Desktop application';

  @override
  Future<void> execute() async {
    final results = argResults;
    if (results == null) {
      log.err('Unable to read parsed arguments.');
      return;
    }

    final workspacePath = (results['workspace'] as String?)?.trim();

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

      log.info('Opening API Dash Desktop...');
      if (finalWorkspacePath != null) {
        log.info('Target Workspace: $finalWorkspacePath');
      }

      // Prepare command for different platforms
      Map<String, String> environment = {};

      if (finalWorkspacePath != null) {
        environment['APIDASH_WORKSPACE_PATH'] = finalWorkspacePath;
      }

      bool success = false;

      if (Platform.isWindows) {
        // Try to start the executable if it's in the PATH
        try {
          await Process.start(
            'cmd',
            ['/c', 'start', 'apidash'],
            environment: environment,
            runInShell: true,
          );
          success = true;
        } catch (_) {
          // Fallback to local development run if in repo
          try {
            log.info('Desktop app not found in PATH. Trying flutter run...');
            await Process.start(
              'flutter',
              ['run', '-d', 'windows'],
              environment: environment,
              mode: ProcessStartMode.detached,
            );
            success = true;
          } catch (e) {
            log.err('Failed to launch API Dash: $e');
          }
        }
      } else if (Platform.isMacOS) {
        try {
          await Process.start(
            'open',
            ['-a', 'apidash'],
            environment: environment,
          );
          success = true;
        } catch (e) {
          log.err('Failed to launch API Dash: $e');
        }
      } else if (Platform.isLinux) {
        try {
          await Process.start(
            'apidash',
            [],
            environment: environment,
            mode: ProcessStartMode.detached,
          );
          success = true;
        } catch (e) {
          log.err('Failed to launch API Dash: $e');
        }
      } else {
        log.err('Unsupported platform for open command.');
      }

      if (success) {
        log.success('API Dash launch signal sent successfully.');
      }
    } catch (e) {
      log.err('Error during open command: $e');
    }
  }
}
