import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:at_daemon_core/at_daemon_core.dart';

import '../util/exceptions.dart';

part 'isolate_channel.dart';
part 'onboard_worker.dart';
part 'worker_message.dart';
part 'worker_manager.dart';

void workerEntry(SendPort port) {
  Worker(port).listen();
}

class Worker {
  final IsolateChannel channel;
  Worker(SendPort port) : channel = IsolateChannel(port) {
    port.send(channel.receivePort);
  }

  Future<void> listen() async {
    channel.receivePort.listen((event) async {
      if (event is WorkerAction) return await handleWorkerAction(event);
    });
  }

  Future<void> handleWorkerAction(WorkerAction event) async {
    if (event is OnboardAction) {
      try {
        return await onboardWorker(event.atSign);
      } on OnboardException catch (e) {
        Isolate.exit(channel.sendPort, e);
      }
    }
    if (event is KillAction) Isolate.exit(channel.sendPort, null);
  }
}
