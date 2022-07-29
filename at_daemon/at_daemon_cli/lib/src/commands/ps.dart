import 'dart:io';

import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:at_daemon_cli/src/models/command_base.dart';

const _name = 'ps';
const _description = 'list running at clients';

class PsCommand extends CommandBase<bool> {
  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Future<bool> run() async {
    Iterable<String> procs = AtSignWorkerManager().getChannelMap().keys;
    for (var p in procs) {
      stdout.writeln(p);
    }
    return true;
  }
}
