import 'dart:convert';

import 'package:async/async.dart';
import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:at_daemon_server/src/config/config_service.dart';
import 'package:at_daemon_server/src/config/list_tuple.dart';
import 'package:at_daemon_server/src/server/at_daemon_server.dart';
import 'package:at_daemon_server/src/server/payload_handler.dart';
import 'package:at_daemon_server/src/server/payload_manager.dart';
import 'package:at_daemon_server/src/util/exceptions.dart';
import 'package:at_daemon_server/src/worker/worker.dart';
import 'package:crypton/crypton.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AtDaemonSocket {
  final WebSocketChannel socketChannel;
  final StreamQueue messages;
  late Session _session;
  final WorkerIsolateChannel _channel;
  final ConnectionRequestHandler connectionRequestHandler;

  AtDaemonSocket({required this.socketChannel, required this.connectionRequestHandler})
      : messages = StreamQueue(socketChannel.stream),
        _channel = WorkerIsolateChannel();

  Future<void> start() async {
    try {
      if (!await handshake()) return;
      await createSessionChannel();
    } catch (e) {
      atDaemonLogger.severe(e);
    }
    await listen();
  }

  // Create the session on the websocket side
  Future<bool> handshake() async {
    RSAKeypair keyPair = EncryptionUtil.generateRSAKeys();

    SessionSyn syn = SessionSyn.fromJson(jsonDecode(await messages.next));
    _session = Session.fromSyn(syn);

    ConnectionResult connectionResult = await connectionRequestHandler.handleConnectionRequest(syn);
    if (connectionResult.whitelist) {
      ConfigService().addWhitelist(
        ListTuple(_session.atSign, _session.clientId, until: connectionResult.until),
      );
    }
    if (connectionResult.blacklist) {
      ConfigService().addBlacklist(
        ListTuple(_session.atSign, _session.clientId, until: connectionResult.until),
      );
    }
    if (!connectionResult.allow) return false;

    SessionSynAck synAck = SessionSynAck(publicKey: keyPair.publicKey.toString());
    socketChannel.sink.add(jsonEncode(synAck.toJson()));

    SessionAck ack = SessionAck.fromJson(jsonDecode(await messages.next));
    _session.sessionKey = EncryptionUtil.decryptKey(ack.encryptedSessionKey, keyPair.privateKey.toString());

    return true;
  }

  // Create the session on the dart isolate side
  Future<void> createSessionChannel() async {
    var mainChannel = await AtSignWorkerManager().getChannel(_session.atSign);
    mainChannel.sendPort!.send(CreateSessionAction(_channel.receivePort.sendPort));
    _channel.sendPort = await _channel.streamQueue.next;
  }

  Future<void> listen() async {
    while (await messages.hasNext) {
      // TODO improve this layer using existing transformers in at_client
      // Transformers first need to be decoupled from AtClient in order to use them.
      String payload = await messages.next;
      late WorkerMessage action;

      PayloadHandler? handler = PayloadManager().getPayloadHandler(payload);

      if (handler == null) {
        socketChannel.sink.add(jsonEncode(UnknownCommandResponse().toJson()));
        continue;
      }

      action = handler.getAction(handler.transformPayload(payload));

      _channel.sendPort!.send(action);
      var result = await _channel.streamQueue.next;

      socketChannel.sink.add(result);
    }
    // Websocket closed, closing worker
    _channel.sendPort?.send(KillAction());
    var message = await _channel.streamQueue.next;
    if (!message is Killed) {
      throw IsolateException('Unexpected final message: expected Killed(), got $message');
    }
  }
}
