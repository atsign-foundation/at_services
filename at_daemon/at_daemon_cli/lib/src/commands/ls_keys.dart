import 'dart:io';

import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:path/path.dart' show basename;
import 'package:at_daemon_cli/src/models/command_base.dart';

const _name = 'ls-keys';
const _description = 'list previously onboarded keys';

class LsKeysCommand extends CommandBase<bool> {
  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Future<bool> run() async {
    ConfigService cs = ConfigService();
    await cs.load();
    for (var atSign in cs.listOnboarded()) {
      stdout.writeln('$atSign - ${basename(cs.getOnboarded(atSign) ?? 'MISSING FILE')}');
    }
    return true;
  }
}
