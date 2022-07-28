import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:at_utils/at_utils.dart';

const _name = 'echo';
const _description = 'echo a string back';

class EchoCommand extends Command<bool> {
  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Future<bool> run() async {
    String? atSign;
    try {
      atSign = validateAtSignArg();
      Iterable<String> msg = argResults?.rest.skip(1) ?? [];
      WorkerIsolateChannel channel = await AtSignWorkerManager().getChannel(atSign);
      channel.sendPort!.send(EchoAction(atSign, msg));
      EchoAction result = await channel.streamQueue.next;
      stdout.writeAll(result.message, ' ');
      stdout.writeln('');
      return true;
    } on InvalidAtSignException catch (e) {
      throw FormatException(e.message);
    }
  }

  String validateAtSignArg() {
    return AtUtils.fixAtSign(AtUtils.formatAtSign(argResults!.rest.first)!);
  }
}
