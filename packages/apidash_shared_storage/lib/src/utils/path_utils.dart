import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../constants.dart';

/// Expands tilde (~) in paths to the user's home directory.
String expandPath(String path) {
  if (path.startsWith('~')) {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      return path.replaceFirst('~', home);
    }
  }
  return path;
}

/// Gets the typical location for the API Dash global config file.
String? getGlobalConfigPath() {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) return null;
  return p.join(home, '.apidash', kApiDashConfigFileName);
}

/// Gets the default workspace path in the user's home directory.
String? getDefaultWorkspacePath() {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) return null;
  return p.join(home, kApiDashDefaultWorkspaceDirName);
}

/// Generates an apidash:// URI for a workspace path.
String generateApidashUri(String workspacePath) {
  return '$kApiDashUriScheme$workspacePath';
}

/// Resolves an apidash:// URI back into a local filesystem path.
String? resolveApidashUri(String uri) {
  if (!uri.startsWith(kApiDashUriScheme)) return null;
  final pathBase = uri.substring(kApiDashUriScheme.length);
  return expandPath(pathBase);
}

/// Writes the global workspace configuration file.
Future<void> writeGlobalWorkspaceConfig(String workspacePath) async {
  final configPath = getGlobalConfigPath();
  if (configPath == null) return;
  final file = File(configPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode({'path': workspacePath}));
}

/// Writes a local marker file for a workspace.
Future<void> writeLocalWorkspaceConfig(String workspacePath) async {
  final file = File(p.join(workspacePath, '.apidash_env'));
  await file.writeAsString(jsonEncode({'workspace': true}));
}

/// Resolves the intended workspace path from passed arguments, environment, or global config.
Future<String?> resolveWorkspacePath([String? passedPath]) async {
  if (passedPath != null && passedPath.isNotEmpty) {
    if (passedPath.startsWith(kApiDashUriScheme)) {
      return resolveApidashUri(passedPath);
    } else {
      return expandPath(passedPath);
    }
  }

  // Fallback 1: Environment Variable
  final envPath = Platform.environment[kApiDashWorkspaceEnvVar];
  if (envPath != null && envPath.isNotEmpty) {
    return expandPath(envPath);
  }

  // Fallback 2: Global Config File
  final configPath = getGlobalConfigPath();
  if (configPath != null && await File(configPath).exists()) {
    try {
      final content = await File(configPath).readAsString();
      if (content.isNotEmpty) {
        final config = jsonDecode(content) as Map<String, dynamic>;
        final pathVal = config['path'] as String?;
        if (pathVal != null) {
          if (pathVal.startsWith(kApiDashUriScheme)) {
            return resolveApidashUri(pathVal);
          }
          return expandPath(pathVal);
        }
      }
    } catch (_) {}
  }

  // Final Fallback: Default Directory
  return getDefaultWorkspacePath();
}

/// Alias for backward compatibility with older CLI calls
Future<String?> resolveWorkspaceUri(String? passedUri) =>
    resolveWorkspacePath(passedUri);
