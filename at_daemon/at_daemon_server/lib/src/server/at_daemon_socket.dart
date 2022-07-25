import 'dart:convert';

import 'package:async/async.dart';
import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:at_daemon_server/src/server/at_daemon_server.dart';
import 'package:at_daemon_server/src/util/exceptions.dart';
import 'package:at_daemon_server/src/worker/worker.dart';
import 'package:crypton/crypton.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AtDaemonSocket {
  final WebSocketChannel socketChannel;
  final StreamQueue messages;
  late Session _session;
  late WorkerIsolateChannel _channel;
  final ConnectionRequestHandler connectionRequestHandler;

  AtDaemonSocket({required this.socketChannel, required this.connectionRequestHandler})
      : messages = StreamQueue(socketChannel.stream);

  Future<void> start() async {
    await handshake();
    _channel = await WorkerManager().getWorkerIsolateChannel(_session.atSign);
  }

  Future<void> handshake() async {
    RSAKeypair keyPair = EncryptionUtil.generateRSAKeys();

    SessionSyn syn = SessionSyn.fromJson(jsonDecode(await messages.next));
    _session = Session.fromSyn(syn);

    ConnectionResult connectionResult = await connectionRequestHandler.handleConnectionRequest(syn);
    switch (connectionResult) {
      case ConnectionResult.whitelistBoth:
      case ConnectionResult.whitelistAtSign:
      case ConnectionResult.whitelistDomain:
        // WhitelistService.add(syn, connectionResult);
      case ConnectionResult.allowOnce:
        break;
      case ConnectionResult.blacklistBoth:
      case ConnectionResult.blacklistAtSign:
      case ConnectionResult.blacklistDomain:
        // BlacklistService.add(syn, connectionResult);
      case ConnectionResult.denyOnce:
      default:
        return;
    }

    SessionSynAck synAck = SessionSynAck(publicKey: keyPair.publicKey.toString());
    socketChannel.sink.add(jsonEncode(synAck.toJson()));

    SessionAck ack = SessionAck.fromJson(jsonDecode(await messages.next));
    _session.sessionKey = EncryptionUtil.decryptKey(ack.encryptedSessionKey, keyPair.privateKey.toString());
  }

  Future<void> listen() async {
    while (await messages.hasNext) {
      var event = await messages.next;
    }
    // Websocket closed, closing worker
    _channel.sendPort?.send(KillAction());
    var message = await _channel.streamQueue.next;
    if (!message is Killed) {
      throw IsolateException('Unexpected final message: expected Killed(), got $message');
    }
  }
}
