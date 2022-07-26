import 'dart:convert';

import 'package:async/async.dart';
import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:at_daemon_server/src/config/blacklist_service.dart';
import 'package:at_daemon_server/src/config/whitelist_service.dart';
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
    if (!await handshake()) return;
    _channel = await WorkerManager().getWorkerIsolateChannel(_session.atSign);
  }

  Future<bool> handshake() async {
    RSAKeypair keyPair = EncryptionUtil.generateRSAKeys();

    SessionSyn syn = SessionSyn.fromJson(jsonDecode(await messages.next));
    _session = Session.fromSyn(syn);

    ConnectionResult connectionResult = await connectionRequestHandler.handleConnectionRequest(syn);
    if (connectionResult.whitelist) WhitelistService().add(_session.atSign, until: connectionResult.until);
    if (connectionResult.blacklist) BlacklistService().add(_session.atSign, until: connectionResult.until);
    if (!connectionResult.allow) return false;

    SessionSynAck synAck = SessionSynAck(publicKey: keyPair.publicKey.toString());
    socketChannel.sink.add(jsonEncode(synAck.toJson()));

    SessionAck ack = SessionAck.fromJson(jsonDecode(await messages.next));
    _session.sessionKey = EncryptionUtil.decryptKey(ack.encryptedSessionKey, keyPair.privateKey.toString());
    return true;
  }

  Future<void> listen() async {
    while (await messages.hasNext) {
      var event = await messages.next;
      // TODO
    }
    // Websocket closed, closing worker
    _channel.sendPort?.send(KillAction());
    var message = await _channel.streamQueue.next;
    if (!message is Killed) {
      throw IsolateException('Unexpected final message: expected Killed(), got $message');
    }
  }
}
