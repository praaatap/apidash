import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:better_networking/better_networking.dart';
import 'base_command.dart';

/// Command to execute an HTTP request from the terminal
class ExecCommand extends BaseCommand {
  ExecCommand() {
    argParser
      ..addOption('method', abbr: 'm', defaultsTo: 'GET', help: 'HTTP method')
      ..addOption('url', abbr: 'u', help: 'Request URL')
      ..addFlag('save', defaultsTo: false, help: 'Save request to workspace')
      ..addOption(
        'collection',
        defaultsTo: 'default',
        help: 'Collection ID to save request',
      )
      ..addOption('request-id', help: 'Custom request ID')
      ..addOption('name', help: 'Request name')
      ..addOption(
        'env',
        abbr: 'e',
        help: 'Environment name for variable substitution',
      );
  }

  @override
  String get name => 'exec';

  @override
  String get description => 'Execute an HTTP request from terminal';

  @override
  Future<void> execute() async {
    final results = argResults;
    if (results == null) {
      log.err('Unable to read parsed arguments.');
      return;
    }

    final methodRaw = ((results['method'] as String?) ?? 'GET').trim();
    final urlFromOption = (results['url'] as String?)?.trim();
    final urlFromRest = results.rest.isNotEmpty ? results.rest.first : null;
    final url = urlFromOption ?? urlFromRest;
    final save = (results['save'] as bool?) ?? false;
    final collectionId = (results['collection'] as String?) ?? 'default';
    final envName = (results['env'] as String?)?.trim();
    final requestId =
        (results['request-id'] as String?)?.trim().isNotEmpty == true
        ? (results['request-id'] as String).trim()
        : 'req_${DateTime.now().millisecondsSinceEpoch}';

    if (url == null || url.isEmpty) {
      log.err('Missing url. Usage: apidash exec --url=<url> [--method=GET]');
      return;
    }

    HTTPVerb method;
    try {
      method = HTTPVerb.values.byName(methodRaw.toLowerCase());
    } catch (_) {
      log.err('Unsupported method: $methodRaw');
      log.info(
        'Supported methods: ${HTTPVerb.values.map((m) => m.name.toUpperCase()).join(', ')}',
      );
      return;
    }

    final request = HttpRequestModel(method: method, url: url);

    // Apply environment if specified and save last CLI request for replay
    var finalRequest = request;
    final storage = StorageService();
    try {
      final workspacePath = await resolveWorkspacePath(null);
      if (workspacePath != null) {
        await storage.initialize(workspacePath: workspacePath);

        if (envName != null && envName.isNotEmpty) {
          final env = await storage.getEnvironment(envName);
          finalRequest = storage.applyEnvironment(request, env);
        }

        // Save the request for `apidash replay` command
        await storage.saveLastCliRequest(finalRequest);
      }
    } catch (e) {
      log.warn('Storage or Environment error: $e');
    }

    final (response, duration, error) = await sendHttpRequest(
      requestId,
      APIType.rest,
      finalRequest,
    );

    if (error != null || response == null) {
      log.err(error ?? 'Request failed');
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

    if (save) {
      try {
        final storage = StorageService();
        final workspacePath = await resolveWorkspacePath(null);
        if (workspacePath == null) {
          log.warn(
            'APIDASH_WORKSPACE_PATH is not set. Skipping --save. '
            'Run "apidash init --path=<path>" first.',
          );
          return;
        }
        await storage.initialize(workspacePath: workspacePath);

        await storage.saveRequest(
          collectionId,
          request,
          requestId: requestId,
          requestName: (results['name'] as String?) ?? '$methodRaw $url',
        );

        await storage.close();
        log.success('Saved request as $requestId in collection $collectionId');
      } catch (e) {
        log.err('Failed to save request: $e');
      }
    }
  }
}
