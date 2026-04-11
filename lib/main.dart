import 'dart:io';
import 'package:apidash_core/apidash_core.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:stac/stac.dart';
import 'models/models.dart';
import 'providers/providers.dart';
import 'services/services.dart';
import 'consts.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Stac.initialize();

  //Load all LLMs
  await ModelManager.fetchAvailableModels();

  var settingsModel = await getSettingsFromSharedPrefs();
  var onboardingStatus = await getOnboardingStatusFromSharedPrefs();

  if (kIsDesktop && settingsModel?.workspaceFolderPath == null) {
    final resolvedWorkspacePath = await resolveWorkspacePath();
    if (resolvedWorkspacePath != null) {
      final newDir = Directory(resolvedWorkspacePath);
      if (!newDir.existsSync()) {
        final homePath = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;
        final oldWorkspaceDir = Directory(p.join(homePath, 'apidash-workspace'));
        final docsDir = await getApplicationDocumentsDirectory();
        
        Directory? sourceDir;
        if (oldWorkspaceDir.existsSync() && oldWorkspaceDir.listSync().any((e) => e.path.endsWith('.hive'))) {
          sourceDir = oldWorkspaceDir;
        } else if (docsDir.existsSync() && docsDir.listSync().any((e) => e.path.endsWith('.hive'))) {
        }

        if (sourceDir != null) {
          try {
            newDir.createSync(recursive: true);
            for (final entity in sourceDir.listSync()) {
              if (entity is File && (entity.path.endsWith('.hive') || entity.path.endsWith('.lock'))) {
                entity.copySync(p.join(newDir.path, p.basename(entity.path)));
              }
            }
          } catch (e) {
            debugPrint("Migration failed: $e");
          }
        }
      }
      settingsModel = (settingsModel ?? const SettingsModel())
          .copyWithPath(workspaceFolderPath: resolvedWorkspacePath);
    }
  }

  if (kIsDesktop && settingsModel?.workspaceFolderPath != null) {
    final workspacePath = settingsModel!.workspaceFolderPath!;
    if (workspacePath.trim().isNotEmpty) {
      await writeGlobalWorkspaceConfig(
        generateApidashUri(expandPath(workspacePath)),
      );
    }
  }

  final initStatus = await initApp(
    kIsDesktop,
    settingsModel: settingsModel,
  );
  if (kIsDesktop) {
    await initWindow(settingsModel: settingsModel);
  }
  if (!initStatus) {
    settingsModel = settingsModel?.copyWithPath(workspaceFolderPath: null);
  }

  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => ThemeStateNotifier(settingsModel: settingsModel),
        ),
        userOnboardedProvider.overrideWith((ref) => onboardingStatus),
      ],
      child: const DashApp(),
    ),
  );
}

Future<bool> initApp(
  bool initializeUsingPath, {
  SettingsModel? settingsModel,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  try {
    debugPrint("initializeUsingPath: $initializeUsingPath");
    debugPrint("workspaceFolderPath: ${settingsModel?.workspaceFolderPath}");
    final openBoxesStatus = await initHiveBoxes(
      initializeUsingPath,
      settingsModel?.workspaceFolderPath,
    );
    debugPrint("openBoxesStatus: $openBoxesStatus");
    if (openBoxesStatus) {
      await autoClearHistory(settingsModel: settingsModel);
    }
    return openBoxesStatus;
  } catch (e) {
    debugPrint("initApp failed due to $e");
    return false;
  }
}

Future<void> initWindow({
  Size? sz,
  SettingsModel? settingsModel,
}) async {
  if (kIsLinux) {
    await setupInitialWindow(
      sz: sz ?? settingsModel?.size,
    );
  }
  if (kIsMacOS || kIsWindows) {
    if (sz != null) {
      await setupWindow(
        sz: sz,
        off: const Offset(100, 100),
      );
    } else {
      await setupWindow(
        sz: settingsModel?.size,
        off: settingsModel?.offset,
      );
    }
  }
}
