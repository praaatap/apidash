import 'dart:convert';
import 'dart:io';

import 'package:better_networking/better_networking.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;

import '../constants.dart';
import '../utils/path_utils.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  bool _isInitialized = false;
  bool _isReadOnly = false;

  bool get isReadOnly => _isReadOnly;

  Future<void> saveLastCliRequest(HttpRequestModel request) async {
    await setSetting<String>('last_cli_request', jsonEncode(request.toJson()));
  }

  Future<HttpRequestModel?> getLastCliRequest() async {
    final raw = await getSetting<String>('last_cli_request');
    if (raw == null) return null;
    try {
      return HttpRequestModel.fromJson(
        Map<String, Object?>.from(jsonDecode(raw)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize({String? workspacePath}) async {
    if (_isInitialized) return;

    final defaultPath = getDefaultWorkspacePath() ?? '';
    final resolved = expandPath(workspacePath ?? defaultPath);
    await Directory(resolved).create(recursive: true);

    Hive.init(resolved);

    try {
      await Hive.openBox(kDataBox);
      await Hive.openBox(kEnvironmentBox);
      await Hive.openBox(kSettingsBox);
    } catch (e) {
      if (e is HiveError ||
          e is PathAccessException ||
          e is FileSystemException) {
        _isReadOnly = true;
        final tmpDir = Directory(path.join(resolved, '.tmp_readonly'));
        if (tmpDir.existsSync()) {
          try {
            tmpDir.deleteSync(recursive: true);
          } catch (_) {}
        }
        tmpDir.createSync(recursive: true);

        final sourceDir = Directory(resolved);
        for (final entity in sourceDir.listSync()) {
          if (entity is File && entity.path.endsWith('.hive')) {
            try {
              entity.copySync(
                path.join(tmpDir.path, path.basename(entity.path)),
              );
            } catch (_) {}
          }
        }

        Hive.init(tmpDir.path);
        await Hive.openBox(kDataBox);
        await Hive.openBox(kEnvironmentBox);
        await Hive.openBox(kSettingsBox);
      } else {
        rethrow;
      }
    }

    _isInitialized = true;
  }

  Future<List<String>> listCollections() async {
    _checkInitialized();
    final all = await _loadAllRequests();
    final set = <String>{};
    for (final r in all) {
      set.add((r['collectionId'] as String?) ?? 'default');
    }
    return set.isEmpty ? <String>['default'] : set.toList();
  }

  Future<List<Map<String, Object?>>> getCollection(String collectionId) async {
    _checkInitialized();
    final all = await _loadAllRequests();
    final filtered = all
        .where(
          (r) => ((r['collectionId'] as String?) ?? 'default') == collectionId,
        )
        .toList();
    return filtered.map(_uiRequestToCliItem).toList();
  }

  /// Get a single request's HttpRequestModel by its UUID.
  Future<HttpRequestModel?> getRequest(String requestId) async {
    _checkInitialized();
    final box = Hive.box(kDataBox);
    final raw = box.get(requestId);
    if (raw is! Map) return null;

    final uiReq = Map<String, Object?>.from(raw);
    final reqDataRaw = uiReq['httpRequestModel'];
    if (reqDataRaw is! Map) return null;

    try {
      return HttpRequestModel.fromJson(Map<String, Object?>.from(reqDataRaw));
    } catch (_) {
      return null;
    }
  }

  /// Get a single request's formatted item by its UUID.
  Future<Map<String, Object?>?> getRequestItem(String requestId) async {
    _checkInitialized();
    final box = Hive.box(kDataBox);
    final raw = box.get(requestId);
    if (raw is! Map) return null;

    return _uiRequestToCliItem(Map<String, Object?>.from(raw));
  }

  Future<void> saveRequest(
    String collectionId,
    HttpRequestModel request, {
    String? requestId,
    String? requestName,
  }) async {
    _checkInitialized();
    _checkReadOnly();
    final box = Hive.box(kDataBox);
    var ids = _stringList(box.get(kKeyDataBoxIds));

    final id = requestId ?? 'req_${DateTime.now().millisecondsSinceEpoch}';
    final uiMap = <String, Object?>{
      'id': id,
      'apiType': 'rest',
      'name':
          requestName ?? '${request.method.abbr.toUpperCase()} ${request.url}',
      'description': '',
      'httpRequestModel': request.toJson(),
      'responseStatus': null,
      'message': null,
      'httpResponseModel': null,
      'preRequestScript': null,
      'postRequestScript': null,
      'aiRequestModel': null,
      'collectionId': collectionId,
    };

    await box.put(id, uiMap);
    if (!ids.contains(id)) {
      ids = [...ids, id];
      await box.put(kKeyDataBoxIds, ids);
    }
  }

  Future<void> deleteRequest(String collectionId, String requestId) async {
    _checkInitialized();
    _checkReadOnly();
    final box = Hive.box(kDataBox);
    final raw = box.get(requestId);
    if (raw is! Map) return;

    final mapped = Map<String, Object?>.from(raw);
    final reqCollection = (mapped['collectionId'] as String?) ?? 'default';
    if (reqCollection != collectionId) return;

    await box.delete(requestId);
    var ids = _stringList(box.get(kKeyDataBoxIds));
    ids = ids.where((e) => e != requestId).toList();
    await box.put(kKeyDataBoxIds, ids);
  }

  Future<List<String>> listEnvironments() async {
    _checkInitialized();
    final box = Hive.box(kEnvironmentBox);
    final ids = _stringList(box.get(kKeyEnvironmentBoxIds));
    return ids;
  }

  Future<Map<String, String>> getEnvironment(String name) async {
    _checkInitialized();
    final box = Hive.box(kEnvironmentBox);
    final raw = box.get(name);
    if (raw is! Map) return {};

    final model = Map<String, Object?>.from(raw);
    final values = model['values'];
    if (values is! List) return {};

    final out = <String, String>{};
    for (final v in values) {
      if (v is Map) {
        final row = Map<String, Object?>.from(v);
        final enabled = row['enabled'] as bool? ?? true;
        if (!enabled) continue;
        final key = row['key'] as String?;
        final value = row['value'] as String?;
        if (key != null && value != null) {
          out[key] = value;
        }
      }
    }
    return out;
  }

  Future<void> saveEnvironment(
    String name,
    Map<String, String> variables,
  ) async {
    _checkInitialized();
    _checkReadOnly();
    final box = Hive.box(kEnvironmentBox);

    final values = variables.entries
        .map(
          (e) => <String, Object?>{
            'key': e.key,
            'value': e.value,
            'type': 'variable',
            'enabled': true,
          },
        )
        .toList();

    await box.put(name, <String, Object?>{
      'id': name,
      'name': name == 'global' ? 'Global' : name,
      'values': values,
    });

    var ids = _stringList(box.get(kKeyEnvironmentBoxIds));
    if (!ids.contains(name)) {
      ids = [...ids, name];
      await box.put(kKeyEnvironmentBoxIds, ids);
    }
  }

  Future<void> deleteEnvironment(String name) async {
    _checkInitialized();
    _checkReadOnly();
    if (name == 'global') {
      throw Exception('Cannot delete global environment');
    }

    final box = Hive.box(kEnvironmentBox);
    await box.delete(name);
    var ids = _stringList(box.get(kKeyEnvironmentBoxIds));
    ids = ids.where((e) => e != name).toList();
    await box.put(kKeyEnvironmentBoxIds, ids);
  }

  Future<void> setEnvironmentVariable(
    String envName,
    String key,
    String value,
  ) async {
    _checkInitialized();
    final env = await getEnvironment(envName);
    env[key] = value;
    await saveEnvironment(envName, env);
  }

  Future<void> removeEnvironmentVariable(String envName, String key) async {
    _checkInitialized();
    final env = await getEnvironment(envName);
    env.remove(key);
    await saveEnvironment(envName, env);
  }

  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    _checkInitialized();
    final box = Hive.box(kSettingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> setSetting<T>(String key, T value) async {
    _checkInitialized();
    _checkReadOnly();
    final box = Hive.box(kSettingsBox);
    await box.put(key, value);
  }

  String resolveVariables(String input, Map<String, String> env) {
    var result = input;
    for (final entry in env.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  HttpRequestModel applyEnvironment(
    HttpRequestModel model,
    Map<String, String> env,
  ) {
    return model.copyWith(
      url: resolveVariables(model.url, env),
      headers: model.headers
          ?.map(
            (h) => h.copyWith(
              name: resolveVariables(h.name, env),
              value: resolveVariables(h.value, env),
            ),
          )
          .toList(),
      params: model.params
          ?.map(
            (p) => p.copyWith(
              name: resolveVariables(p.name, env),
              value: resolveVariables(p.value, env),
            ),
          )
          .toList(),
      body: model.body != null ? resolveVariables(model.body!, env) : null,
    );
  }

  Future<void> close() async {
    if (!_isInitialized) return;
    await Hive.close();
    _isInitialized = false;
  }

  Future<List<Map<String, Object?>>> _loadAllRequests() async {
    final box = Hive.box(kDataBox);
    final ids = _stringList(box.get(kKeyDataBoxIds));
    final out = <Map<String, Object?>>[];

    for (final id in ids) {
      final raw = box.get(id);
      if (raw is Map) {
        out.add(Map<String, Object?>.from(raw));
      }
    }
    return out;
  }

  Map<String, Object?> _uiRequestToCliItem(Map<String, Object?> uiReq) {
    final id = uiReq['id'] as String? ?? '';
    final name = uiReq['name'] as String? ?? '';
    final reqDataRaw = uiReq['httpRequestModel'];

    Map<String, Object?> reqData = const {};
    if (reqDataRaw is Map) {
      reqData = Map<String, Object?>.from(reqDataRaw);
    }

    String method = 'GET';
    String url = '';
    try {
      final model = HttpRequestModel.fromJson(reqData);
      method = model.method.abbr;
      url = model.url;
    } catch (_) {}

    return <String, Object?>{
      'id': id,
      'name': name,
      'method': method,
      'url': url,
      'data': reqData,
      'collectionId': (uiReq['collectionId'] as String?) ?? 'default',
    };
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception(
        'StorageService not initialized. Call initialize() first.',
      );
    }
  }

  void _checkReadOnly() {
    if (_isReadOnly) {
      throw Exception(
        'APIDash GUI is currently open. The CLI/MCP server is running in Read-Only mode. Please close the GUI to modify data.',
      );
    }
  }
}
