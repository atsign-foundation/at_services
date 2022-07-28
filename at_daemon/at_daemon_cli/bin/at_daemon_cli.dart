import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';
import 'package:at_daemon_cli/at_daemon_cli.dart';
import 'package:at_daemon_cli/src/services/cli_connection_request_handler.dart';
import 'package:at_daemon_cli/src/services/cli_onboarding_handler.dart';
import 'package:at_daemon_server/at_daemon_server.dart';

Future<void> main() async {
  stdout.writeln('Starting at_daemon server...');

  await AtDaemonServer(
    connectionRequestHandler: CliConnectionRequestHandler(),
    onboardingHandler: CliOnboardingHandler(),
  ).start();

  while (true) {
    stdout.write('> ');
    String command = await readLine();
    Iterable<String> args = command.split(' ');
    try {
      await AtCommandRunner().run(args);
    } finally {}
  }
}

Future<void> startServer() async {

}

var _stdinLines = StreamQueue(LineSplitter().bind(Utf8Decoder().bind(stdin)));

Future<String> readLine([String? query]) async {
  if (query != null) stdout.write(query);
  return _stdinLines.next;
}
