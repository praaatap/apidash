import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:apidash_shared_storage/apidash_shared_storage.dart' as shared;
import 'flutter_storage_adapter.dart';

// Re-export shared constants for backward compatibility
const String kDataBox = shared.kDataBox;
const String kEnvironmentBox = shared.kEnvironmentBox;
const String kKeyDataBoxIds = shared.kKeyDataBoxIds;
const String kKeyEnvironmentBoxIds = shared.kKeyEnvironmentBoxIds;

// Flutter-specific box names (not shared with CLI/MCP)
const String kHistoryMetaBox = "apidash-history-meta";
const String kHistoryBoxIds = "historyIds";
const String kHistoryLazyBox = "apidash-history-lazy";

const String kDashBotBox = "apidash-dashbot-data";
const String kKeyDashBotBoxIds = 'messages';

Future<bool> initHiveBoxes(
  bool initializeUsingPath,
  String? workspaceFolderPath,
) async {
  try {
    // Use FlutterStorageAdapter which wraps apidash_shared_storage
    final adapter = FlutterStorageAdapter();
    final success = await adapter.initialize(
      initializeUsingPath: initializeUsingPath,
      workspaceFolderPath: workspaceFolderPath,
    );
    
    if (success) {
      debugPrint('✅ Storage initialized using apidash_shared_storage');
    }
    
    return success;
  } catch (e) {
    debugPrint('❌ Error initializing storage: $e');
    return false;
  }
}

Future<bool> openHiveBoxes() async {
  try {
    // Shared boxes are opened by FlutterStorageAdapter.initialize()
    // Just verify they're open
    if (!Hive.isBoxOpen(kDataBox)) {
      await Hive.openBox(kDataBox);
    }
    if (!Hive.isBoxOpen(kEnvironmentBox)) {
      await Hive.openBox(kEnvironmentBox);
    }
    
    // Open Flutter-specific boxes
    if (!Hive.isBoxOpen(kHistoryMetaBox)) {
      await Hive.openBox(kHistoryMetaBox);
    }
    if (!Hive.isBoxOpen(kHistoryLazyBox)) {
      await Hive.openLazyBox(kHistoryLazyBox);
    }
    if (!Hive.isBoxOpen(kDashBotBox)) {
      await Hive.openLazyBox(kDashBotBox);
    }
    
    return true;
  } catch (e) {
    debugPrint("ERROR OPEN HIVE BOXES: $e");
    return false;
  }
}

Future<void> clearHiveBoxes() async {
  try {
    for (var box in [kDataBox, kEnvironmentBox, kHistoryMetaBox]) {
      if (Hive.isBoxOpen(box)) {
        await Hive.box(box).clear();
      }
    }
    for (var lazyBox in [kHistoryLazyBox, kDashBotBox]) {
      if (Hive.isBoxOpen(lazyBox)) {
        await Hive.lazyBox(lazyBox).clear();
      }
    }
  } catch (e) {
    debugPrint("ERROR CLEAR HIVE BOXES: $e");
  }
}

Future<void> deleteHiveBoxes() async {
  try {
    for (var box in [kDataBox, kEnvironmentBox, kHistoryMetaBox]) {
      if (Hive.isBoxOpen(box)) {
        await Hive.box(box).deleteFromDisk();
      }
    }
    for (var lazyBox in [kHistoryLazyBox, kDashBotBox]) {
      if (Hive.isBoxOpen(lazyBox)) {
        await Hive.lazyBox(lazyBox).deleteFromDisk();
      }
    }
    await Hive.close();
  } catch (e) {
    debugPrint("ERROR DELETE HIVE BOXES: $e");
  }
}

final hiveHandler = HiveHandler();

class HiveHandler {
  late final Box dataBox;
  late final Box environmentBox;
  late final Box historyMetaBox;
  late final LazyBox historyLazyBox;
  late final LazyBox dashBotBox;
  
  // Shared storage adapter for cross-interface compatibility
  final FlutterStorageAdapter _adapter = FlutterStorageAdapter();

  HiveHandler() {
    debugPrint("Trying to open Hive boxes");
    dataBox = Hive.box(kDataBox);
    environmentBox = Hive.box(kEnvironmentBox);
    historyMetaBox = Hive.box(kHistoryMetaBox);
    historyLazyBox = Hive.lazyBox(kHistoryLazyBox);
    dashBotBox = Hive.lazyBox(kDashBotBox);
  }

  // ─────────────────────────────────────────────
  // Shared Operations (via FlutterStorageAdapter)
  // ─────────────────────────────────────────────

  dynamic getIds() => dataBox.get(kKeyDataBoxIds);
  Future<void> setIds(List<String>? ids) async {
    await dataBox.put(kKeyDataBoxIds, ids);
  }

  dynamic getRequestModel(String id) => dataBox.get(id);
  Future<void> setRequestModel(
          String id, Map<String, dynamic>? requestModelJson) async {
    await dataBox.put(id, requestModelJson);
  }

  void delete(String key) => dataBox.delete(key);

  // Environment operations (shared with CLI/MCP)
  dynamic getEnvironmentIds() => environmentBox.get(kKeyEnvironmentBoxIds);
  Future<void> setEnvironmentIds(List<String>? ids) async {
    await environmentBox.put(kKeyEnvironmentBoxIds, ids);
    // Environments are managed by shared storage
    // (sync happens via setEnvironment which is called by UI)
  }

  dynamic getEnvironment(String id) => environmentBox.get(id);
  Future<void> setEnvironment(
          String id, Map<String, dynamic>? environmentJson) async {
    await environmentBox.put(id, environmentJson);
    // Sync to shared storage
    try {
      // Extract variables from environment JSON and sync
      if (environmentJson != null && environmentJson['values'] is List) {
        final variables = <String, String>{};
        for (final value in environmentJson['values'] as List) {
          if (value is Map && value['enabled'] != false) {
            variables[value['key'] as String] = value['value'] as String;
          }
        }
        await _adapter.saveEnvironment(id, variables);
      }
    } catch (e) {
      debugPrint('Warning: Could not sync environment: $e');
    }
  }

  Future<void> deleteEnvironment(String id) async {
    await environmentBox.delete(id);
    // Also delete from shared storage
    try {
      await _adapter.deleteEnvironment(id);
    } catch (e) {
      debugPrint('Warning: Could not delete from shared storage: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Flutter-Specific Operations (History, DashBot)
  // ─────────────────────────────────────────────

  dynamic getHistoryIds() => historyMetaBox.get(kHistoryBoxIds);
  Future<void> setHistoryIds(List<String>? ids) =>
      historyMetaBox.put(kHistoryBoxIds, ids);

  dynamic getHistoryMeta(String id) => historyMetaBox.get(id);
  Future<void> setHistoryMeta(
          String id, Map<String, dynamic>? historyMetaJson) =>
      historyMetaBox.put(id, historyMetaJson);

  Future<void> deleteHistoryMeta(String id) => historyMetaBox.delete(id);

  Future<dynamic> getHistoryRequest(String id) async =>
      await historyLazyBox.get(id);
  Future<void> setHistoryRequest(
          String id, Map<String, dynamic>? historyRequestJson) =>
      historyLazyBox.put(id, historyRequestJson);

  Future<void> deleteHistoryRequest(String id) => historyLazyBox.delete(id);

  Future<dynamic> getDashbotMessages() async =>
      await dashBotBox.get(kKeyDashBotBoxIds);
  Future<void> saveDashbotMessages(String messages) =>
      dashBotBox.put(kKeyDashBotBoxIds, messages);

  Future clearAllHistory() async {
    await historyMetaBox.clear();
    await historyLazyBox.clear();
  }

  Future clear() async {
    await dataBox.clear();
    await environmentBox.clear();
    await historyMetaBox.clear();
    await historyLazyBox.clear();
    await dashBotBox.clear();
  }

  Future<void> removeUnused() async {
    var ids = getIds();
    if (ids != null) {
      ids = ids as List;
      for (var key in dataBox.keys.toList()) {
        if (key != kKeyDataBoxIds && !ids.contains(key)) {
          await dataBox.delete(key);
        }
      }
    }
    var environmentIds = getEnvironmentIds();
    if (environmentIds != null) {
      environmentIds = environmentIds as List;
      for (var key in environmentBox.keys.toList()) {
        if (key != kKeyEnvironmentBoxIds && !environmentIds.contains(key)) {
          await environmentBox.delete(key);
        }
      }
    }
  }
}
