import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_daemon_cli/src/models/command_base.dart';
import 'package:at_daemon_server/at_daemon_server.dart';

const _name = 'kill';
const _description = 'kill an AtClient';

class KillCommand extends AtSignCommandBase<bool> {
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
}
