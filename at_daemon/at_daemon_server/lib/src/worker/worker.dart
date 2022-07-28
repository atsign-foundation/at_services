import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:at_daemon_server/at_daemon_server.dart';

import '../util/exceptions.dart';

part 'isolate_channel.dart';
part 'worker_message.dart';
part 'worker_manager.dart';

void workerEntry(SendPort port) {
  AtClientWorker(port).listen();
}

abstract class Worker {
  final IsolateChannel channel;
  Worker(SendPort port) : channel = IsolateChannel(port) {
    port.send(channel.receivePort.sendPort);
  }

  FutureOr<void> listen();
}

class AtClientWorker extends Worker {
  AtClientWorker(super.port);

  @override
  Future<void> listen() async {
    channel.receivePort.listen((event) async {
      if (event is OnboardAction) {
        try {
          bool result =  await OnboardingManager().handler.onboard(atSign: event.atSign);
          channel.sendPort!.send(Onboarded(result));
          return;
        } on OnboardException catch (e) {
          Isolate.exit(channel.sendPort, e);
        }
      }
      if (event is CreateSessionAction) {
        SessionWorker(event.sendPort);
      }
      if (event is KillAction) Isolate.exit(channel.sendPort, null);
    });
  }
}

class SessionWorker extends Worker {
  SessionWorker(super.port);

  @override
  Future<void> listen() async {
    // TODO verb implementations

    channel.receivePort.listen((event) {
      if (event is KillAction) {
        channel.receivePort.close();
        channel.sendPort!.send(Killed());
      }
    });
  }
}
