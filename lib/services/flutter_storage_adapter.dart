import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:apidash_shared_storage/apidash_shared_storage.dart' as shared;

/// Flutter-specific wrapper around apidash_shared_storage
/// 
/// This adapter allows the main Flutter app to use the shared storage layer
/// while maintaining compatibility with Flutter-specific features like
/// history tracking and DashBot that aren't shared with CLI/MCP.
class FlutterStorageAdapter {
  // Singleton pattern
  static final FlutterStorageAdapter _instance = FlutterStorageAdapter._internal();
  factory FlutterStorageAdapter() => _instance;
  FlutterStorageAdapter._internal();

  // Shared storage service (for data, environments, settings)
  final shared.StorageService _sharedStorage = shared.StorageService();
  
  // Flutter-specific boxes (not shared with CLI/MCP)
  late LazyBox _historyLazyBox;
  late LazyBox _dashBotBox;
  late Box _historyMetaBox;
  
  // State
  bool _isInitialized = false;
  bool _isReadOnly = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isReadOnly => _isReadOnly;
  Box get dataBox => Hive.box(shared.kDataBox);
  Box get environmentBox => Hive.box(shared.kEnvironmentBox);

  /// Initialize storage for Flutter app
  /// 
  /// This bridges the Flutter app to use apidash_shared_storage
  /// for core data while maintaining Flutter-specific boxes.
  Future<bool> initialize({
    bool initializeUsingPath = false,
    String? workspaceFolderPath,
  }) async {
    if (_isInitialized) return true;

    try {
      // 1. Initialize Hive (Flutter or path-based)
      if (initializeUsingPath && workspaceFolderPath != null) {
        Hive.init(workspaceFolderPath);
      } else {
        await Hive.initFlutter();
      }

      // 2. Open shared boxes via StorageService
      await _sharedStorage.initialize(workspacePath: workspaceFolderPath);
      
      // Check if we're in read-only mode
      _isReadOnly = _sharedStorage.isReadOnly;

      // 3. Open Flutter-specific boxes (not shared with CLI/MCP)
      _historyMetaBox = await Hive.openBox('apidash-history-meta');
      _historyLazyBox = await Hive.openLazyBox('apidash-history-lazy');
      _dashBotBox = await Hive.openLazyBox('apidash-dashbot-data');

      // 4. Initialize shared storage boxes
      // These are opened by _sharedStorage.initialize()
      // We just verify they're open
      if (!Hive.isBoxOpen(shared.kDataBox)) {
        await Hive.openBox(shared.kDataBox);
      }
      if (!Hive.isBoxOpen(shared.kEnvironmentBox)) {
        await Hive.openBox(shared.kEnvironmentBox);
      }

      _isInitialized = true;
      
      if (_isReadOnly) {
        debugPrint('⚠️  Running in read-only mode (CLI/MCP has workspace open)');
      }
      
      debugPrint('✅ Storage initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing storage: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Shared Collections API (via apidash_shared_storage)
  // ─────────────────────────────────────────────

  Future<List<String>> listCollections() async {
    _checkInitialized();
    return _sharedStorage.listCollections();
  }

  Future<List<Map<String, dynamic>>> getCollection(String collectionId) async {
    _checkInitialized();
    return _sharedStorage.getCollection(collectionId);
  }

  Future<dynamic> getRequest(String requestId) async {
    _checkInitialized();
    // Use shared storage for consistency
    return _sharedStorage.getRequest(requestId);
  }

  Future<void> saveRequest(
    String collectionId,
    Map<String, dynamic> requestModelJson, {
    String? requestId,
    String? requestName,
  }) async {
    _checkInitialized();
    _checkReadOnly();
    
    // Convert JSON map to HttpRequestModel for shared storage
    // For backward compatibility, we store the JSON directly in Hive
    // and also sync to shared storage
    await dataBox.put(requestId ?? DateTime.now().millisecondsSinceEpoch.toString(), requestModelJson);
    
    // Sync to shared storage (optional, for CLI/MCP access)
    // This ensures CLI/MCP can see requests created in GUI
    try {
      // Note: This would require converting JSON to HttpRequestModel
      // For now, we rely on Hive box being shared
    } catch (e) {
      debugPrint('Warning: Could not sync to shared storage: $e');
    }
  }

  Future<void> deleteRequest(String requestId) async {
    _checkInitialized();
    _checkReadOnly();
    
    await dataBox.delete(requestId);
    
    // Also delete from shared storage
    try {
      await _sharedStorage.deleteRequest('default', requestId);
    } catch (e) {
      debugPrint('Warning: Could not delete from shared storage: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Shared Environments API (via apidash_shared_storage)
  // ─────────────────────────────────────────────

  Future<List<String>> listEnvironments() async {
    _checkInitialized();
    return _sharedStorage.listEnvironments();
  }

  Future<Map<String, String>> getEnvironment(String name) async {
    _checkInitialized();
    return _sharedStorage.getEnvironment(name);
  }

  Future<void> saveEnvironment(String name, Map<String, String> variables) async {
    _checkInitialized();
    _checkReadOnly();
    await _sharedStorage.saveEnvironment(name, variables);
  }

  Future<void> setEnvironmentVariable(String envName, String key, String value) async {
    _checkInitialized();
    _checkReadOnly();
    await _sharedStorage.setEnvironmentVariable(envName, key, value);
  }

  Future<void> removeEnvironmentVariable(String envName, String key) async {
    _checkInitialized();
    _checkReadOnly();
    await _sharedStorage.removeEnvironmentVariable(envName, key);
  }

  Future<void> deleteEnvironment(String name) async {
    _checkInitialized();
    _checkReadOnly();
    await _sharedStorage.deleteEnvironment(name);
  }

  // ─────────────────────────────────────────────
  // Shared Settings API (via apidash_shared_storage)
  // ─────────────────────────────────────────────

  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    _checkInitialized();
    return _sharedStorage.getSetting<T>(key, defaultValue: defaultValue);
  }

  Future<void> setSetting<T>(String key, T value) async {
    _checkInitialized();
    _checkReadOnly();
    await _sharedStorage.setSetting<T>(key, value);
  }

  // ─────────────────────────────────────────────
  // Flutter-Specific Features (History, DashBot)
  // ─────────────────────────────────────────────

  // History Management (Flutter-only)
  Future<List<String>> getHistoryIds() async {
    _checkInitialized();
    return List<String>.from(_historyMetaBox.get('historyIds') ?? []);
  }

  Future<void> setHistoryIds(List<String> ids) async {
    _checkInitialized();
    await _historyMetaBox.put('historyIds', ids);
  }

  Future<dynamic> getHistoryRequest(String id) async {
    _checkInitialized();
    return await _historyLazyBox.get(id);
  }

  Future<void> setHistoryRequest(String id, Map<String, dynamic> requestJson) async {
    _checkInitialized();
    await _historyLazyBox.put(id, requestJson);
  }

  Future<void> deleteHistoryRequest(String id) async {
    _checkInitialized();
    await _historyLazyBox.delete(id);
  }

  Future<void> clearAllHistory() async {
    _checkInitialized();
    await _historyMetaBox.clear();
    await _historyLazyBox.clear();
  }

  // DashBot Management (Flutter-only)
  Future<dynamic> getDashbotMessages() async {
    _checkInitialized();
    return await _dashBotBox.get('messages');
  }

  Future<void> saveDashbotMessages(String messages) async {
    _checkInitialized();
    await _dashBotBox.put('messages', messages);
  }

  // ─────────────────────────────────────────────
  // Environment Variable Substitution (Shared)
  // ─────────────────────────────────────────────

  String resolveVariables(String input, Map<String, String> env) {
    return _sharedStorage.resolveVariables(input, env);
  }

  // ─────────────────────────────────────────────
  // Utility Methods
  // ─────────────────────────────────────────────

  Future<void> clearAllData() async {
    _checkInitialized();
    _checkReadOnly();
    
    await dataBox.clear();
    await environmentBox.clear();
    await _historyMetaBox.clear();
    await _historyLazyBox.clear();
    await _dashBotBox.clear();
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _sharedStorage.close();
      _isInitialized = false;
    }
  }

  // ─────────────────────────────────────────────
  // Internal Helpers
  // ─────────────────────────────────────────────

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('Storage not initialized. Call initialize() first.');
    }
  }

  void _checkReadOnly() {
    if (_isReadOnly) {
      throw StateError(
        'Storage is in read-only mode. Close CLI/MCP to make changes.',
      );
    }
  }
}

// Global instance for backward compatibility
final flutterStorage = FlutterStorageAdapter();
