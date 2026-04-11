/// Command-line interface for API Dash
///
/// This is the main entry point for the apidash CLI executable.
library;

import 'package:apidash_cli/apidash_cli.dart';

Future<void> main(List<String> arguments) async {
  await runCli(arguments);
}
