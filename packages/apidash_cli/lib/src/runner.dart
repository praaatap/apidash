import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'cli_runner.dart';

/// Main entry point for the API Dash CLI.
///
/// Parses command-line arguments and runs the appropriate command.
Future<void> runCli(List<String> rawArguments) async {
  final log = Logger();
  final runner = CliRunner();

  try {
    await runner.run(rawArguments);
  } on UsageException catch (e) {
    log.err(e.message);
    log.info(e.usage);
  } catch (e) {
    log.err('Error: $e');
  }
}
