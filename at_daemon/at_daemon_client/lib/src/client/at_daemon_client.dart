import 'dart:convert';
import 'dart:html';

import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:async/async.dart';

class AtDaemonClient {
  static late ClientInfo _clientInfo;

  static void initialize(ClientInfo clientInfo) {
    _clientInfo = clientInfo;
  }

  final String atSign;
  final WebSocket socket;
  late Session _session;
  late final StreamQueue messages;

  AtDaemonClient(this.atSign) : socket = WebSocket(AtDaemonConstants.socketUrl) {
    messages = StreamQueue(socket.onMessage);
  }

  Future<void> connect() async {
    SessionSyn syn = SessionSyn.fromClientInfo(_clientInfo, atSign: atSign);
    socket.send(jsonEncode(syn.toJson()));

    _session = Session.fromSyn(syn, sessionKey: EncryptionUtil.generateAESKey());
    String publicKey = SessionSynAck.fromJson(jsonDecode(await messages.next)).publicKey;

    SessionAck ack = SessionAck(encryptedSessionKey: EncryptionUtil.encryptKey(_session.sessionKey!, publicKey));
    socket.send(jsonEncode(ack.toJson()));

    return;
  }

  Session get session => _session;
}
