import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:better_networking/better_networking.dart';
import 'base_command.dart';

/// Command to list collections, requests, or request details
class ListCommand extends BaseCommand {
  ListCommand() {
    argParser
      ..addOption(
        'collection',
        abbr: 'c',
        help: 'Collection ID to list requests from',
      )
      ..addOption('folder', abbr: 'f', help: 'Folder ID to list requests from')
      ..addOption('request', abbr: 'r', help: 'Request ID to show details')
      ..addOption(
        'format',
        defaultsTo: 'table',
        allowed: ['table', 'json'],
        help: 'Output format',
      );
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List collections, requests, or request details';

  @override
  Future<void> execute() async {
    final results = argResults;
    if (results == null) {
      log.err('Unable to read parsed arguments.');
      return;
    }

    final collectionId = (results['collection'] as String?)?.trim();
    final folderId = (results['folder'] as String?)?.trim();
    final requestId = (results['request'] as String?)?.trim();
    final format = results['format'] as String;

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

      if (requestId != null) {
        // Show request details
        await _showRequestDetails(storage, requestId, format);
      } else if (collectionId != null) {
        // List requests in collection
        await _listCollectionRequests(storage, collectionId, folderId, format);
      } else {
        // List all collections
        await _listCollections(storage, format);
      }

      await storage.close();
    } catch (e) {
      log.err('Failed to list: $e');
    }
  }

  Future<void> _listCollections(StorageService storage, String format) async {
    final collectionIds = await storage.listCollections();

    if (format == 'json') {
      const encoder = JsonEncoder.withIndent('  ');
      log.write(encoder.convert(collectionIds));
    } else {
      log.info('');
      log.info('Collections:');
      log.info('─────────────────────────────────────────────────');

      if (collectionIds.isEmpty) {
        log.info('  No collections found');
      } else {
        for (final collectionId in collectionIds) {
          final requests = await storage.getCollection(collectionId);
          log.info('  📁 $collectionId (${requests.length} requests)');
        }
      }
      log.info('─────────────────────────────────────────────────');
    }
  }

  Future<void> _listCollectionRequests(
    StorageService storage,
    String collectionId,
    String? folderId,
    String format,
  ) async {
    final requests = await storage.getCollection(collectionId);

    if (format == 'json') {
      final output = requests
          .map(
            (r) => {
              'id': r['id'],
              'name': r['name'] ?? '${r['method']} ${r['url']}',
              'method': r['method'],
              'url': r['url'],
            },
          )
          .toList();
      const encoder = JsonEncoder.withIndent('  ');
      log.write(encoder.convert(output));
    } else {
      log.info('');
      log.info('Requests in collection: $collectionId');
      log.info('─────────────────────────────────────────────────');

      if (requests.isEmpty) {
        log.info('  No requests found');
      } else {
        for (final request in requests) {
          final method = request['method'] as String;
          final name = request['name'] ?? '$method ${request['url']}';
          log.info('  $method  $name');
        }
      }
      log.info('─────────────────────────────────────────────────');
    }
  }

  Future<void> _showRequestDetails(
    StorageService storage,
    String requestId,
    String format,
  ) async {
    final requestItem = await storage.getRequestItem(requestId);

    if (requestItem == null) {
      log.err('Request "$requestId" not found');
      return;
    }

    final reqData = requestItem['data'] as Map<String, dynamic>;
    final httpRequestModel = HttpRequestModel.fromJson(reqData);

    if (format == 'json') {
      final output = {
        'id': requestItem['id'],
        'name': requestItem['name'],
        'method': requestItem['method'],
        'url': requestItem['url'],
        'headers': httpRequestModel.headers
            ?.map((h) => {'name': h.name, 'value': h.value})
            .toList(),
        'params': httpRequestModel.params
            ?.map((p) => {'name': p.name, 'value': p.value})
            .toList(),
        if (httpRequestModel.body != null) 'body': httpRequestModel.body,
      };
      const encoder = JsonEncoder.withIndent('  ');
      log.write(encoder.convert(output));
    } else {
      log.info('');
      log.info('Request: ${requestItem['name'] ?? requestId}');
      log.info('─────────────────────────────────────────────────');
      log.info('  ID:     ${requestItem['id']}');
      log.info('  Method: ${requestItem['method']}');
      log.info('  URL:    ${requestItem['url']}');

      if (httpRequestModel.headers != null &&
          httpRequestModel.headers!.isNotEmpty) {
        log.info('');
        log.info('  Headers:');
        for (final header in httpRequestModel.headers!) {
          log.info('    ${header.name}: ${header.value}');
        }
      }

      if (httpRequestModel.params != null &&
          httpRequestModel.params!.isNotEmpty) {
        log.info('');
        log.info('  Parameters:');
        for (final param in httpRequestModel.params!) {
          log.info('    ${param.name}: ${param.value}');
        }
      }

      if (httpRequestModel.body != null) {
        log.info('');
        log.info('  Body:');
        log.info('    ${httpRequestModel.body}');
      }

      log.info('─────────────────────────────────────────────────');
    }
  }
}
