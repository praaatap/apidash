import 'dart:convert';
import 'dart:io';

class _Ansi {
  static const reset = '\x1B[0m';
  static const bold = '\x1B[1m';
  static const dim = '\x1B[2m';
  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const blue = '\x1B[34m';
  static const cyan = '\x1B[36m';
  static const white = '\x1B[37m';
  static const bgGreen = '\x1B[42m';
  static const bgYellow = '\x1B[43m';
  static const bgRed = '\x1B[41m';
  static const bgBlue = '\x1B[44m';
}

class OutputFormatter {
  final bool useColors;

  OutputFormatter({bool? useColors})
      : useColors = useColors ?? stdout.hasTerminal;

  String formatStatusCode(int statusCode) {
    final bg = _statusBackground(statusCode);
    final label = _statusLabel(statusCode);
    if (!useColors) return '[$statusCode $label]';
    return '$bg${_Ansi.bold} $statusCode $label ${_Ansi.reset}';
  }

  String _statusBackground(int code) {
    if (code < 200) return _Ansi.bgBlue;
    if (code < 300) return _Ansi.bgGreen;
    if (code < 400) return _Ansi.bgBlue;
    if (code < 500) return _Ansi.bgYellow;
    return _Ansi.bgRed;
  }

  String _statusLabel(int code) {
    const labels = {
      200: 'OK',
      201: 'Created',
      204: 'No Content',
      301: 'Moved',
      302: 'Found',
      304: 'Not Modified',
      400: 'Bad Request',
      401: 'Unauthorized',
      403: 'Forbidden',
      404: 'Not Found',
      500: 'Internal Server Error',
    };
    return labels[code] ?? '';
  }

  String formatHeaders(Map<String, String> headers) {
    if (headers.isEmpty) return '  (no headers)';
    final maxKeyLen =
        headers.keys.fold<int>(0, (m, k) => k.length > m ? k.length : m);
    final buf = StringBuffer();
    for (final entry in headers.entries) {
      final key = entry.key.padRight(maxKeyLen);
      final val = entry.value;
      buf.writeln(
          '  ${useColors ? _Ansi.cyan : ""}$key${useColors ? _Ansi.reset : ""}  $val');
    }
    return buf.toString().trimRight();
  }

  String formatBody(String body) {
    if (body.isEmpty) return '  (empty body)';
    try {
      final decoded = jsonDecode(body);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      return useColors ? _colorizeJson(pretty) : pretty;
    } catch (_) {
      return body;
    }
  }

  String _colorizeJson(String json) {
    return json
        .replaceAllMapped(RegExp(r'"([^"]+)"\s*:'),
            (m) => '${_Ansi.cyan}"${m.group(1)}"${_Ansi.reset}:')
        .replaceAllMapped(RegExp(r':\s*"([^"]*)"'),
            (m) => ': ${_Ansi.green}"${m.group(1)}"${_Ansi.reset}')
        .replaceAllMapped(RegExp(r':\s*(\d+\.?\d*)'),
            (m) => ': ${_Ansi.yellow}${m.group(1)}${_Ansi.reset}');
  }

  String sectionHeader(String title) =>
      useColors ? '${_Ansi.dim}── $title ──${_Ansi.reset}' : '── $title ──';
  String formatElapsed(Duration duration) => useColors
      ? '${_Ansi.dim}⏱ ${duration.inMilliseconds}ms${_Ansi.reset}'
      : '⏱ ${duration.inMilliseconds}ms';
  String formatMethodUrl(String method, String url) => useColors
      ? '${_Ansi.bold}${_Ansi.white}${method.toUpperCase()}${_Ansi.reset} ${_Ansi.blue}$url${_Ansi.reset}'
      : '${method.toUpperCase()} $url';
  String formatError(String msg) =>
      useColors ? '${_Ansi.red}✗ Error: $msg${_Ansi.reset}' : '✗ Error: $msg';
  String formatSuccess(String msg) =>
      useColors ? '${_Ansi.green}✓ $msg${_Ansi.reset}' : '✓ $msg';
  String formatInfo(String msg) =>
      useColors ? '${_Ansi.dim}ℹ $msg${_Ansi.reset}' : 'ℹ $msg';
}
