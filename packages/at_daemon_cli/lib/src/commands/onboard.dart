import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_daemon_cli/src/models/command_base.dart';
import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:chalkdart/chalk.dart';

const _name = 'onboard';
const _description = 'onboard an atSign - e.g. "onboard @alice -k /path/to/keys/file"';

class OnboardCommand extends AtSignCommandBase<bool> {
  @override
  String get name => _name;

  @override
  String get description => _description;

  OnboardCommand() {
    argParser.addOption('key-file', abbr: 'k');
    argParser.addOption(
      'log-level',
      abbr: 'l',
      allowed: ['info', 'shout', 'severe', 'warning', 'finer', 'finest', 'all'],
      defaultsTo: 'severe',
    );
  }

  @override
  Future<bool> run() async {
    try {
      String atSign = validateAtSignArg();
      File keyFile;

      if (argResults!.wasParsed('key-file')) {
        keyFile = File(argResults!['key-file']);
      } else {
        ConfigService cs = ConfigService();
        await cs.load();
        String? keyFilePath = cs.getOnboarded(atSign);

        if (keyFilePath == null) {
          stdout.writeln(chalk.red('No key file previously loaded for $atSign'));
          stdout.writeln(chalk.red('Please specify a path with "-k <path-to-key-file>"'));
          return false;
        }

        keyFile = File(keyFilePath);
      }
      bool result =
          await OnboardingManager().onboard(atSign: atSign, keyFile: keyFile, logLevel: argResults!['log-level']);
      if (result) {
        stdout.writeln('Successfully onboarded $atSign');
      } else {
        stdout.writeln(chalk.red('Failed to onboard $atSign'));
      }

      return result;
    } on InvalidAtSignException catch (e) {
      throw FormatException(e.message);
    }
  }
}
