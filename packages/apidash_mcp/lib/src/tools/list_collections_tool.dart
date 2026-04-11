import 'dart:convert';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:mcp_server/mcp_server.dart';

/// Summary of a collection with its ID, name, and request count
class CollectionSummary {
  const CollectionSummary({
    required this.id,
    required this.name,
    this.requestCount = 0,
  });

  final String id;
  final String name;
  final int requestCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'requestCount': requestCount,
      };
}

/// Lists all collections from the API Dash workspace
Future<List<CollectionSummary>> listCollectionsFromWorkspace(
  StorageService storage,
) async {
  try {
    final collectionIds = await storage.listCollections();
    final output = <CollectionSummary>[];

    for (final collectionId in collectionIds) {
      String name = collectionId;
      int requestCount = 0;

      try {
        final requests = await storage.getCollection(collectionId);
        requestCount = requests.length;
        name = collectionId == 'default' ? 'Default Collection' : collectionId;
      } catch (_) {
        // Ignore errors when getting collection details
      }

      output.add(CollectionSummary(
        id: collectionId,
        name: name,
        requestCount: requestCount,
      ));
    }

    return output;
  } catch (e) {
    rethrow;
  }
}

/// Registers the list_collections tool
void registerListCollectionsTool(
  Server server, {
  required StorageService storage,
}) {
  server.addTool(
    name: 'list_collections',
    description: 'List all collections available in the API Dash workspace with request counts',
    inputSchema: {'type': 'object', 'properties': {}},
    handler: (arguments) async {
      try {
        final collections = await listCollectionsFromWorkspace(storage);
        final payload = collections.map((c) => c.toJson()).toList();
        return CallToolResult(
          content: [
            TextContent(text: jsonEncode(payload)),
          ],
        );
      } catch (e) {
        return CallToolResult(
          content: [
            TextContent(text: jsonEncode({'error': e.toString()})),
          ],
          isError: true,
        );
      }
    },
  );
}
