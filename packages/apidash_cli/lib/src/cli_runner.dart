import 'package:args/args.dart';

import 'commands/commands.dart';

class CliRunner {
  static ArgParser buildParser() {
    final parser = ArgParser()
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Print usage info');

    parser.addCommand('send', SendCommand.parser());
    parser.addCommand('curl', CurlCommand.parser());

    return parser;
  }

  static Future<void> run(List<String> arguments) async {
    final parser = buildParser();
    ArgResults results;

    try {
      results = parser.parse(arguments);
    } catch (e) {
      print(e.toString());
      _printUsage(parser);
      return;
    }

    if (results['help'] == true || results.command == null) {
      _printUsage(parser);
      return;
    }

    final command = results.command!;
    switch (command.name) {
      case 'send':
        await SendCommand.run(command);
        break;
      case 'curl':
        await CurlCommand.run(command);
        break;
    }
  }

  static void _printUsage(ArgParser parser) {
    print('API Dash CLI - Run API requests from the terminal.\n');
    print('Usage: apidash <command> [arguments]\n');
    print('Global options:');
    print(parser.usage);
    print('\nCommands:');
    print('  send     Send an HTTP request');
    print('  curl     Parse and optionally execute a cURL command');
  }
}
