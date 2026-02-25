import 'package:args/args.dart';
import 'package:better_networking/better_networking.dart';

import '../services/output_formatter.dart';

class SendCommand {
  static ArgParser parser() => ArgParser()
    ..addOption('method', abbr: 'X', defaultsTo: 'GET', help: 'HTTP method')
    ..addMultiOption('header', abbr: 'H', help: 'Header in "K:V" format')
    ..addOption('data', abbr: 'd', help: 'Request body')
    ..addOption('api-type', defaultsTo: 'rest', help: 'rest or graphql')
    ..addFlag('verbose',
        abbr: 'v', defaultsTo: false, help: 'Show response headers');

  static Future<void> run(ArgResults args) async {
    final rest = args.rest;
    if (rest.isEmpty) {
      print('Usage: apidash send <url> [options]\n${parser().usage}');
      return;
    }

    final formatter = OutputFormatter();
    final url = rest.first;
    final method = _parseMethod(args['method'] as String);
    final apiType = (args['api-type'] as String).toLowerCase() == 'graphql'
        ? APIType.graphql
        : APIType.rest;

    final headers = <NameValueModel>[];
    for (final h in args['header'] as List<String>) {
      final idx = h.indexOf(':');
      if (idx > 0) {
        headers.add(NameValueModel(
            name: h.substring(0, idx).trim(),
            value: h.substring(idx + 1).trim()));
      }
    }

    final requestModel = HttpRequestModel(
      url: url,
      method: method,
      headers: headers.isEmpty ? null : headers,
      body: args['data'] as String?,
    );

    print('${formatter.formatMethodUrl(method.name, url)}\n');
    final (response, duration, error) = await sendHttpRequest(
        'cli-${DateTime.now().millisecondsSinceEpoch}', apiType, requestModel);

    if (error != null) {
      print(formatter.formatError(error));
      return;
    }
    if (response == null) {
      print(formatter.formatError('No response received'));
      return;
    }

    print(
        '${formatter.formatStatusCode(response.statusCode)}  ${formatter.formatElapsed(duration ?? Duration.zero)}\n');
    if (args['verbose'] as bool) {
      print(
          '${formatter.sectionHeader('Response Headers')}\n${formatter.formatHeaders(response.headers)}\n');
    }
    print(
        '${formatter.sectionHeader('Response Body')}\n${formatter.formatBody(response.body)}');
  }

  static HTTPVerb _parseMethod(String m) =>
      HTTPVerb.values.firstWhere((e) => e.name.toUpperCase() == m.toUpperCase(),
          orElse: () => HTTPVerb.get);
}
