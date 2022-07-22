import 'dart:io';

import 'package:args/args.dart' show ArgResults;
import 'package:args/command_runner.dart' show CommandRunner, UsageException;
import 'package:at_daemon_cli/src/commands/exit.dart';
import 'package:at_daemon_cli/src/commands/onboard.dart';
import 'package:chalkdart/chalk.dart' show chalk;
import 'package:at_utils/at_logger.dart';

const String name = 'exec';
const String description = 'The internal command handler.';

class AtCommandRunner extends CommandRunner<bool> {

  AtCommandRunner() : super(name, description) {
    argParser.addFlag(
      'verbose',
      negatable: false,
      abbr: 'v',
      help: 'Verbose logging'
    );
    addCommand(ExitCommand());
    addCommand(OnboardCommand());
  }

  @override
  Future<bool> run(Iterable<String> args) async {
    try {
      final _argResults = parse(args);
      return await runCommand(_argResults) as Future<bool>;
    } on FormatException catch (e) {
      stdout.writeAll([chalk.red(e.message), usage]);
    } on UsageException catch (e) {
      stdout.writeAll([chalk.red(e.message), e.usage]);
    }
    return false;
  }

  @override
  Future<bool> runCommand(ArgResults topLevelResults) async {
    AtSignLogger.root_level = 'severe';
    if(topLevelResults.wasParsed('verbose')) {
      AtSignLogger.root_level = 'info';
    }
    return super.runCommand(topLevelResults) as Future<bool>;
  }
}


