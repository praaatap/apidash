import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:better_networking/better_networking.dart';
import 'base_command.dart';

/// Command to replay the last executed CLI HTTP request
class ReplayCommand extends BaseCommand {
  ReplayCommand() {
    argParser.addOption(
      'env',
      abbr: 'e',
      help: 'Environment name for variable substitution',
    );
  }

  @override
  String get name => 'replay';

  @override
  String get description =>
      'Replay the last executed HTTP request from the terminal';

  @override
  Future<void> execute() async {
    final results = argResults;
    if (results == null) {
      log.err('Unable to read parsed arguments.');
      return;
    }

    final envName = (results['env'] as String?)?.trim();

    try {
      final storage = StorageService();
      final workspacePath = await resolveWorkspacePath(null);

      if (workspacePath == null) {
        log.err(
          'No workspace found. Configure APIDASH_WORKSPACE_PATH environment variable.',
        );
        return;
      }

      await storage.initialize(workspacePath: workspacePath);

      final lastRequest = await storage.getLastCliRequest();
      if (lastRequest == null) {
        log.err('No previous CLI request found to replay.');
        await storage.close();
        return;
      }

      log.info(
        'Replaying Request: ${lastRequest.method.name.toUpperCase()} ${lastRequest.url}',
      );

      var finalRequest = lastRequest;
      if (envName != null && envName.isNotEmpty) {
        try {
          final env = await storage.getEnvironment(envName);
          finalRequest = storage.applyEnvironment(lastRequest, env);
        } catch (e) {
          log.warn('Failed to apply environment "$envName": $e');
        }
      }

      // We need a dummy requestId for sendHttpRequest logging, we can just use a timestamp.
      final replayRequestId =
          'req_replay_${DateTime.now().millisecondsSinceEpoch}';

      final (response, duration, error) = await sendHttpRequest(
        replayRequestId,
        APIType.rest,
        finalRequest,
      );

      if (error != null || response == null) {
        log.err(error ?? 'Request failed');
        await storage.close();
        return;
      }

      final httpResponseModel = HttpResponseModel().fromResponse(
        response: response,
        time: duration,
      );

      final output = Map<String, dynamic>.from(httpResponseModel.toJson())
        ..remove('bodyBytes');

      const encoder = JsonEncoder.withIndent('  ');
      log.write(encoder.convert(output));

      await storage.close();
    } catch (e) {
      log.err('Failed to replay request: $e');
    }
  }
}
