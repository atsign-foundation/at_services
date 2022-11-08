import 'dart:io';

import 'package:args/args.dart' show ArgResults;
import 'package:args/command_runner.dart' show CommandRunner, UsageException;
import 'package:at_daemon_cli/src/commands/echo.dart';
import 'package:at_daemon_cli/src/commands/exit.dart';
import 'package:at_daemon_cli/src/commands/kill.dart';
import 'package:at_daemon_cli/src/commands/ls_keys.dart';
import 'package:at_daemon_cli/src/commands/onboard.dart';
import 'package:at_daemon_cli/src/commands/ps.dart';
import 'package:chalkdart/chalk.dart' show chalk;
import 'package:at_utils/at_logger.dart';

const String name = '';
const String description = '';

class AtCommandRunner extends CommandRunner<bool> {
  AtCommandRunner() : super(name, description) {
    argParser.addFlag('verbose', negatable: false, abbr: 'v', help: 'Verbose logging');
    addCommand(ExitCommand());
    addCommand(OnboardCommand());
    addCommand(EchoCommand());
    addCommand(KillCommand());
    addCommand(PsCommand());
    addCommand(LsKeysCommand());
  }

  @override
  String get invocation => '<command> [arguments]';

  @override
  String get executableName => '';

  @override
  String get usage => super.usage.splitMapJoin(
        '"$executableName help',
        onMatch: (_) => '"help',
        onNonMatch: (m) => m,
      );

  @override
  Future<bool> run(Iterable<String> args) async {
    try {
      final _argResults = parse(args);
      return await runCommand(_argResults);
    } on FormatException catch (e) {
      stdout.writeln(chalk.red(e.message));
      stdout.writeln(usage);
    } on UsageException catch (e) {
      stdout.writeln(chalk.red(e.message));
      stdout.writeln(e.usage);
    }
    return false;
  }

  @override
  Future<bool> runCommand(ArgResults topLevelResults) async {
    AtSignLogger.root_level = 'severe';
    if (topLevelResults.wasParsed('verbose')) {
      AtSignLogger.root_level = 'info';
    }
    return await super.runCommand(topLevelResults) ?? false;
  }
}
