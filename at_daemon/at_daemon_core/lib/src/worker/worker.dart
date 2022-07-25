// The entry point for the client's isolate
import 'dart:isolate';
import 'package:at_daemon_core/src/worker/worker_action.dart';

import 'package:at_daemon_core/src/worker/isolate_channel.dart';
import 'package:at_daemon_core/src/utils/onboard_worker.dart';
import 'package:at_daemon_core/src/utils/exceptions.dart';

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
