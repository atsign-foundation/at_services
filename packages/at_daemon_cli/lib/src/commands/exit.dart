import 'dart:io';

import 'package:at_daemon_cli/src/models/command_base.dart';
import 'package:at_daemon_server/at_daemon_server.dart';

const _name = 'exit';
const _description = 'exit the daemon';
const _aliases = ['q', 'quit'];

class ExitCommand extends CommandBase<bool> {
  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  List<String> get aliases => _aliases;

  @override
  Future<bool> run() async {
    stdout.writeln('Closing background processes...');
    await Future.wait(
      await AtSignWorkerManager().getAllChannels().then(
            (iter) => iter.map(
              (WorkerIsolateChannel channel) async {
                channel.sendPort!.send(KillAction());
                await channel.streamQueue.next;
              },
            ),
          ),
    );
    exit(0);
  }
}
