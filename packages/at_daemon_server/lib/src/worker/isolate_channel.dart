part of 'worker.dart';

/// A channel to another [Isolate]
/// [sendPort] is the port for sending information to the other [Isolate]
/// [receivePort] is the port that receives information from the other [Isolate]
class IsolateChannel {
  SendPort? sendPort;
  final ReceivePort receivePort = ReceivePort();
  IsolateChannel([this.sendPort]);
}

/// A channel specifically used for sharing information with a worker [Isolate]
/// [streamQueue] is a wrapper around [receivePort]
class WorkerIsolateChannel extends IsolateChannel {
  late StreamQueue streamQueue;
  WorkerIsolateChannel([super.sendPort]) {
    streamQueue = StreamQueue(receivePort);
  }
}
