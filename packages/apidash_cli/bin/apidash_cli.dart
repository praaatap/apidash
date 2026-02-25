import 'dart:io';
import '../lib/src/cli_runner.dart';

void main(List<String> arguments) async {
  await CliRunner.run(arguments);
  exit(0);
}
