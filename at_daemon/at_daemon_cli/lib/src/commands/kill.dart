import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:at_utils/at_utils.dart';

const _name = 'kill';
const _description = 'kill an AtClient for an atSign';

class KillCommand extends Command<bool> {
  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Future<bool> run() async {
    String? atSign;
    try {
      atSign = validateAtSignArg();
      bool result = await AtSignWorkerManager().kill(atSign);
      String message = result ? 'Killed $atSign' : 'Failed to kill $atSign (could already be dead).';
      stdout.writeln(message);
      return result;
    } on InvalidAtSignException catch (e) {
      throw FormatException(e.message);
    }
  }

  String validateAtSignArg() {
    if (argResults!.rest.isEmpty) {
      throw UsageException('No atSign specified for onboarding.', usage);
    }

    if (argResults!.rest.length > 1) {
      throw UsageException('Too many arguments specified.', usage);
    }

    return AtUtils.fixAtSign(AtUtils.formatAtSign(argResults!.rest.single)!);
  }
}
