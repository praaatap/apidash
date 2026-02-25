// ignore_for_file: avoid_print
import 'dart:io';
import '../lib/src/cli_runner.dart';

void main() async {
  print('--- Executing apidash send example ---\n');
  await CliRunner.run(
      ['send', 'https://jsonplaceholder.typicode.com/todos/1', '--verbose']);

  print('\n--- Executing apidash curl example ---\n');
  await CliRunner.run([
    'curl',
    'curl -X POST https://httpbin.org/post -H "Content-Type: application/json" -d \'{"hello": "world"}\'',
    '--execute'
  ]);

  exit(0);
}
