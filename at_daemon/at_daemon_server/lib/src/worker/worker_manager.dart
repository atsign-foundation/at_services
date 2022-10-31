part of 'worker.dart';

/// [AtSignWorkerManager] is responsible for overseeing the creation of each worker isolate
abstract class AtSignWorkerManager {
  static final AtSignWorkerManager _singleton = _WorkerManager();
  factory AtSignWorkerManager() => _singleton;

  Future<WorkerIsolateChannel> create(String atSign);
  Future<WorkerIsolateChannel> getChannel(String atSign);
  Future<Iterable<WorkerIsolateChannel>> getAllChannels();
  Map<String, WorkerIsolateChannel> getChannelMap();
  Future<bool> kill(String atSign);
}

class _WorkerManager implements AtSignWorkerManager {
  static final Map<String, WorkerIsolateChannel> _workerChannelMap = {};

  @override
  Future<WorkerIsolateChannel> create(String atSign) async {
    if (_workerChannelMap.containsKey(atSign)) {
      final String message = 'Isolate for $atSign already spawned.';
      atDaemonLogger.severe(message);
      throw IsolateException(message);
    }

    WorkerIsolateChannel channel = WorkerIsolateChannel();

    await Isolate.spawn(workerEntry, channel.receivePort.sendPort);
    channel.sendPort = await channel.streamQueue.next as SendPort;

    return _workerChannelMap[atSign] = channel;
  }

  @override
  Future<WorkerIsolateChannel> getChannel(String atSign) async {
    return _workerChannelMap[atSign] ?? await create(atSign);
  }

  @override
  Future<Iterable<WorkerIsolateChannel>> getAllChannels() async {
    return _workerChannelMap.values;
  }

  @override
  Map<String, WorkerIsolateChannel> getChannelMap() {
    return Map.from(_workerChannelMap);
  }

  @override
  Future<bool> kill(String atSign) async {
    WorkerIsolateChannel? channel = _workerChannelMap.remove(atSign);
    if (channel?.sendPort == null) return false;
    channel!.sendPort!.send(KillAction());
    return (await channel.streamQueue.next is Killed);
  }
}
