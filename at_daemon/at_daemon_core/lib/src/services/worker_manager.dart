import 'dart:async';
import 'dart:isolate';

import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:at_daemon_core/src/models/worker_action.dart';
import 'package:at_daemon_core/src/models/isolate_channel.dart';
import 'package:at_daemon_core/src/services/worker.dart';
import 'package:at_daemon_core/src/utils/exceptions.dart';

/// [WorkerManager] is responsible for overseeing the creation of each worker isolate
abstract class WorkerManager {
  static final WorkerManager _singleton = _WorkerManager();
  factory WorkerManager() => _singleton;

  Future<WorkerIsolateChannel> createWorkerIsolate(String atSign);
  Future<WorkerIsolateChannel> getWorkerIsolateChannel(String atSign);
  void killWorkerIsolate(String atSign);
}

class _WorkerManager implements WorkerManager {
  static final Map<String, WorkerIsolateChannel> _workerChannelMap = {};

  @override
  Future<WorkerIsolateChannel> createWorkerIsolate(String atSign) async {
    if (_workerChannelMap.containsKey(atSign)) {
      final String message = 'Isolate for $atSign already spawned.';
      logger.severe(message);
      throw IsolateException(message);
    }

    WorkerIsolateChannel channel = WorkerIsolateChannel();

    await Isolate.spawn(workerEntry, channel.receivePort.sendPort);
    channel.sendPort = await channel.streamQueue.next as SendPort;

    _workerChannelMap[atSign] = channel;
    return channel;
  }

  @override
  Future<WorkerIsolateChannel> getWorkerIsolateChannel(String atSign) async {
    return _workerChannelMap[atSign] ?? await createWorkerIsolate(atSign);
  }

  @override
  Future<void> killWorkerIsolate(String atSign) async {
    WorkerIsolateChannel? channel = _workerChannelMap.remove(atSign);
    if (channel?.sendPort == null) return;
    channel!.sendPort!.send(KillAction());
    await channel.streamQueue.next;
  }
}
