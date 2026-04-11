import 'dart:io';

void main() async {
  final content = await File('d:/apidash/packages/apidash_shared_storage/lib/apidash_shared_storage.dart').readAsString();
  final srcDir = Directory('d:/apidash/packages/apidash_shared_storage/lib/src');
  await srcDir.create(recursive: true);
  await Directory('${srcDir.path}/models').create(recursive: true);
  await Directory('${srcDir.path}/utils').create(recursive: true);
  await Directory('${srcDir.path}/parsers').create(recursive: true);
  await Directory('${srcDir.path}/services').create(recursive: true);

  // 1. Path utils
  final pathStart = content.indexOf('String expandPath(');
  final pathEnd = content.indexOf('/// Converts an imported collection');
  final pathCode = "import 'dart:io';\nimport 'package:path/path.dart' as p;\nimport '../constants.dart';\n\n" + content.substring(pathStart, pathEnd);
  await File('${srcDir.path}/utils/path_utils.dart').writeAsString(pathCode);

  // 2. Parser
  final parserStart = content.indexOf('/// Converts an imported collection');
  final parserEnd = content.indexOf('class StorageService {');
  final parserCode = "import 'dart:convert';\nimport 'package:better_networking/better_networking.dart';\nimport 'package:har_parser/har_parser.dart';\nimport 'package:insomnia_parser/insomnia_parser.dart';\nimport 'package:postman_parser/postman_parser.dart';\nimport 'package:curl_parser/curl_parser.dart';\nimport '../models/imported_request.dart';\nimport 'dart:math';\n\n" + content.substring(parserStart, parserEnd);
  await File('${srcDir.path}/parsers/import_parser.dart').writeAsString(parserCode);

  // 3. StorageService
  final storageStart = content.indexOf('class StorageService {');
  final storageCode = "import 'package:hive/hive.dart';\nimport 'package:better_networking/better_networking.dart';\nimport '../constants.dart';\nimport '../utils/path_utils.dart';\nimport '../models/imported_request.dart';\nimport '../parsers/import_parser.dart';\n\n" + content.substring(storageStart);
  await File('${srcDir.path}/services/storage_service.dart').writeAsString(storageCode);

  // 4. Barrel file
  final barrelCode = "export 'src/constants.dart';\nexport 'src/models/imported_request.dart';\nexport 'src/utils/path_utils.dart';\nexport 'src/parsers/import_parser.dart';\nexport 'src/services/storage_service.dart';\n";
  await File('d:/apidash/packages/apidash_shared_storage/lib/apidash_shared_storage.dart').writeAsString(barrelCode);

  print('Done splitting!');
}
