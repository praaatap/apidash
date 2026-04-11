import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final root = r'd:\apidash\packages\apidash_shared_storage';
  final libList = File(p.join(root, 'lib', 'apidash_shared_storage.dart'));
  final content = await libList.readAsString();

  final srcDir = Directory(p.join(root, 'lib', 'src'));
  final modelsDir = Directory(p.join(srcDir.path, 'models'));
  final utilsDir = Directory(p.join(srcDir.path, 'utils'));
  final parsersDir = Directory(p.join(srcDir.path, 'parsers'));
  final servicesDir = Directory(p.join(srcDir.path, 'services'));

  await srcDir.create(recursive: true);
  await modelsDir.create(recursive: true);
  await utilsDir.create(recursive: true);
  await parsersDir.create(recursive: true);
  await servicesDir.create(recursive: true);

  // 1. Write constants
  final constantsContent = '''
const String kApiDashWorkspaceEnvVar = 'APIDASH_WORKSPACE_PATH';
const String kApiDashConfigFileName = 'config.json';
const String kApiDashDefaultWorkspaceDirName = '.apidash';
const String kApiDashUriScheme = 'apidash://';

const String kDataBox = 'apidash-data';
const String kEnvironmentBox = 'apidash-environments';
const String kSettingsBox = 'apidash-settings';

const String kKeyDataBoxIds = 'ids';
const String kKeyEnvironmentBoxIds = 'environmentIds';
''';
  await File(p.join(srcDir.path, 'constants.dart')).writeAsString(constantsContent);

  // 2. Write models/imported_request.dart
  final importedRequestContent = '''
import 'package:better_networking/better_networking.dart';

class ImportedRequest {
  const ImportedRequest({required this.request, this.name});

  final HttpRequestModel request;
  final String? name;
}
''';
  await File(p.join(modelsDir.path, 'imported_request.dart')).writeAsString(importedRequestContent);

  // 3. Extract the path utils from content.
  final lines = content.split('\n');
  int? pathStart, pathEnd;
  int? parserStart, parserEnd;
  int? storageStart, storageEnd;

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('String expandPath(String path)')) pathStart = i;
    if (lines[i].contains('Future<String?> resolveWorkspaceUri(')) pathEnd = i + 40; // Approx end
    // find EXACT boundary
  }

  // Instead of fragile substrings, I will just copy the entire file to storage_service.dart and then we can strip out parts.
  // Actually, since this script approach could fail easily if regex doesn't match perfectly, 
  // let's do this directly in dart: 
  print("Refactoring started");
}
