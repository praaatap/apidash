import 'dart:io';
import 'package:args/args.dart';
import 'package:apidash_core/apidash_core.dart'
    show Curl, convertCurlToHttpRequestModel;
import 'package:better_networking/better_networking.dart';

import '../services/output_formatter.dart';

class CurlCommand {
  static ArgParser parser() => ArgParser()
    ..addOption('file', abbr: 'f', help: 'Read cURL from file')
    ..addFlag('execute',
        abbr: 'e', defaultsTo: false, help: 'Execute the parsed request');

  static Future<void> run(ArgResults args) async {
    final formatter = OutputFormatter();
    String curlString;
    if (args['file'] != null) {
      final file = File(args['file'] as String);
      if (!file.existsSync()) {
        print(formatter.formatError('File not found'));
        return;
      }
      curlString = file.readAsStringSync().trim();
    } else if (args.rest.isNotEmpty) {
      curlString = args.rest.join(' ');
    } else {
      print('Usage: apidash curl <curl_command>\n${parser().usage}');
      return;
    }

    try {
      final curl = Curl.parse(curlString);
      final model = convertCurlToHttpRequestModel(curl);
      print(
          '${formatter.sectionHeader('Parsed Request')}\n  Method: ${model.method.name.toUpperCase()}\n  URL: ${model.url}');
      if (model.headersMap.isNotEmpty) {
        print('  Headers:');
        model.headersMap.forEach((k, v) => print('    $k: $v'));
      }

      if (args['execute'] as bool) {
        print('\n${formatter.formatMethodUrl(model.method.name, model.url)}\n');
        final (resp, dur, err) = await sendHttpRequest(
            'cli-curl-${DateTime.now().millisecondsSinceEpoch}',
            APIType.rest,
            model);
        if (err != null) {
          print(formatter.formatError(err));
          return;
        }
        if (resp == null) {
          print(formatter.formatError('No response'));
          return;
        }
        print(
            '${formatter.formatStatusCode(resp.statusCode)}  ${formatter.formatElapsed(dur ?? Duration.zero)}\n');
        print(
            '${formatter.sectionHeader('Response Body')}\n${formatter.formatBody(resp.body)}');
      }
    } catch (e) {
      print(formatter.formatError('Failed to parse cURL: $e'));
    }
  }
}
