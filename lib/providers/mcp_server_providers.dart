import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:apidash_shared_storage/apidash_shared_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as path;

import 'settings_providers.dart';

@immutable
class McpServerState {
  const McpServerState({
    this.isRunning = false,
    this.pid,
    this.lastError,
  });

  final bool isRunning;
  final int? pid;
  final String? lastError;

  McpServerState copyWith({
    bool? isRunning,
    int? pid,
    String? lastError,
  }) {
    return McpServerState(
      isRunning: isRunning ?? this.isRunning,
      pid: pid,
      lastError: lastError,
    );
  }
}

final mcpServerProvider =
    StateNotifierProvider<McpServerNotifier, McpServerState>((ref) {
      return McpServerNotifier(ref);
    });

class McpServerNotifier extends StateNotifier<McpServerState> {
  McpServerNotifier(this._ref) : super(const McpServerState());

  final Ref _ref;

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  final StringBuffer _stderrBuffer = StringBuffer();
  bool _isStopping = false;

  Future<bool> start() async {
    if (state.isRunning) return true;

    final spec = _resolveStartSpec();
    if (spec == null) {
      state = state.copyWith(
        isRunning: false,
        pid: null,
        lastError: 'Unable to locate APIDash CLI/MCP startup command.',
      );
      return false;
    }

    final workspacePath = _ref.read(settingsProvider).workspaceFolderPath;
    final List<String> finalArgs = [...spec.args];
    if (workspacePath != null && workspacePath.trim().isNotEmpty) {
      finalArgs.addAll(['--workspace', workspacePath]);
    }

    try {
      final process = await Process.start(
        spec.command,
        finalArgs,
        runInShell: false,
        workingDirectory: spec.workingDirectory,
        environment: _buildProcessEnvironment(),
      );

      _process = process;
      _isStopping = false;
      _stderrBuffer.clear();
      _stdoutSub = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        debugPrint('[APIDash MCP] $line');
      });
      _stderrSub = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (_stderrBuffer.isNotEmpty) {
          _stderrBuffer.writeln();
        }
        _stderrBuffer.write(line);
        debugPrint('[APIDash MCP][stderr] $line');
      });

      final startupStatus = await Future.any<Object?>([
        process.exitCode,
        Future<void>.delayed(const Duration(milliseconds: 600)),
      ]);
      if (startupStatus is int) {
        final stderr = _stderrBuffer.toString().trim();
        await _clearProcess();
        state = state.copyWith(
          isRunning: false,
          pid: null,
          lastError: stderr.isEmpty
              ? 'MCP server exited immediately with code $startupStatus.'
              : 'MCP server exited immediately with code $startupStatus: $stderr',
        );
        return false;
      }

      unawaited(
        process.exitCode.then((exitCode) async {
          final wasStopping = _isStopping;
          final stderr = _stderrBuffer.toString().trim();
          await _clearProcess();
          state = state.copyWith(
            isRunning: false,
            pid: null,
            lastError: wasStopping || exitCode == 0
                ? state.lastError
                : (stderr.isEmpty
                    ? 'MCP server exited with code $exitCode.'
                    : 'MCP server exited with code $exitCode: $stderr'),
          );
        }),
      );

      state = state.copyWith(
        isRunning: true,
        pid: process.pid,
        lastError: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        pid: null,
        lastError: 'Failed to start MCP server: $e',
      );
      return false;
    }
  }

  Map<String, String> _buildProcessEnvironment() {
    final env = Map<String, String>.from(Platform.environment);
    final workspacePath = _ref.read(settingsProvider).workspaceFolderPath;
    if (workspacePath != null && workspacePath.trim().isNotEmpty) {
      env[kApiDashWorkspaceEnvVar] = workspacePath;
    }
    return env;
  }

  Future<void> stop() async {
    final process = _process;
    if (process == null) {
      state = state.copyWith(isRunning: false, pid: null);
      return;
    }

    _isStopping = true;
    final graceful = process.kill(ProcessSignal.sigterm);
    if (!graceful) {
      process.kill();
    }

    await _clearProcess();
    state = state.copyWith(isRunning: false, pid: null);
  }

  Future<void> _clearProcess() async {
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _process = null;
    _isStopping = false;
  }

  _McpStartSpec? _resolveStartSpec() {
    final cwd = Directory.current.path;
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final envCommand = Platform.environment['APIDASH_MCP_COMMAND']?.trim();
    if (envCommand != null && envCommand.isNotEmpty) {
      return _McpStartSpec(envCommand, const []);
    }

    // Check pub global activated version first (fastest)
    final pubCacheBin = path.join(
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '',
      'AppData',
      'Local',
      'Pub',
      'Cache',
      'bin',
    );
    if (Platform.isWindows) {
      final globalMcpExe = File(path.join(pubCacheBin, 'apidash_mcp.exe'));
      if (globalMcpExe.existsSync()) {
        return _McpStartSpec(globalMcpExe.path, const []);
      }
      final globalCliExe = File(path.join(pubCacheBin, 'apidash.exe'));
      if (globalCliExe.existsSync()) {
        return _McpStartSpec(globalCliExe.path, const ['mcp']);
      }
    }

    // Collect candidate roots to search
    final candidateRoots = <String>{
      cwd,
      exeDir,
      path.join(exeDir, 'bin'),
      path.normalize(path.join(exeDir, '..')),
      // Add parent directories up to 3 levels up
      path.normalize(path.join(cwd, '..')),
      path.normalize(path.join(cwd, '..', '..')),
      path.normalize(path.join(cwd, '..', '..', '..')),
    };

    // Search for compiled executables first
    for (final root in candidateRoots) {
      if (!Directory(root).existsSync()) continue;
      
      if (Platform.isWindows) {
        final mcpExe = File(path.join(root, 'apidash_mcp.exe'));
        if (mcpExe.existsSync()) {
          return _McpStartSpec(mcpExe.path, const []);
        }
        final cliExe = File(path.join(root, 'apidash_cli.exe'));
        if (cliExe.existsSync()) {
          return _McpStartSpec(cliExe.path, const ['mcp']);
        }
        final apidashExe = File(path.join(root, 'apidash.exe'));
        if (apidashExe.existsSync()) {
          return _McpStartSpec(apidashExe.path, const ['mcp']);
        }
      } else {
        final mcpExe = File(path.join(root, 'apidash_mcp'));
        if (mcpExe.existsSync()) {
          return _McpStartSpec(mcpExe.path, const []);
        }
        final cliExe = File(path.join(root, 'apidash_cli'));
        if (cliExe.existsSync()) {
          return _McpStartSpec(cliExe.path, const ['mcp']);
        }
        final apidashExe = File(path.join(root, 'apidash'));
        if (apidashExe.existsSync()) {
          return _McpStartSpec(apidashExe.path, const ['mcp']);
        }
      }
    }

    // Search for Dart entrypoints in packages directory
    for (final root in candidateRoots) {
      if (!Directory(root).existsSync()) continue;
      
      // Check for CLI entrypoint
      final cliEntrypoint = File(path.join(root, 'packages', 'apidash_cli', 'bin', 'apidash_cli.dart'));
      if (cliEntrypoint.existsSync()) {
        return _McpStartSpec('dart', [
          'run',
          cliEntrypoint.path,
          'mcp',
        ], workingDirectory: root);
      }

      // Check for MCP entrypoint
      final mcpEntrypoint = File(path.join(root, 'packages', 'apidash_mcp', 'bin', 'apidash_mcp.dart'));
      if (mcpEntrypoint.existsSync()) {
        return _McpStartSpec('dart', [
          'run',
          mcpEntrypoint.path,
        ], workingDirectory: root);
      }
    }

    // Fallback: Try to use pub global run
    return _McpStartSpec('dart', const [
      'pub',
      'global',
      'run',
      'apidash_mcp',
    ]);
  }

  @override
  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _process?.kill();
    super.dispose();
  }
}

class _McpStartSpec {
  const _McpStartSpec(this.command, this.args, {this.workingDirectory});

  final String command;
  final List<String> args;
  final String? workingDirectory;
}
