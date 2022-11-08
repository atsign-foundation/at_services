import 'package:at_daemon_core/src/models/client_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session.g.dart';

@JsonSerializable()
class SessionSyn extends ClientInfo {
  final String atSign;
  final int version;

  SessionSyn({
    required this.atSign,
    required super.clientId,
    super.clientName,
    super.syncSpace,
    this.version = 1,
  });

  SessionSyn.fromClientInfo(ClientInfo clientInfo, {required this.atSign, this.version = 1})
      : super(
          clientId: clientInfo.clientId,
          clientName: clientInfo.clientName,
          syncSpace: clientInfo.syncSpace,
        );

  factory SessionSyn.fromJson(Map<String, dynamic> json) => _$SessionSynFromJson(json);
  Map<String, dynamic> toJson() => _$SessionSynToJson(this);
}

@JsonSerializable()
class SessionSynAck {
  final String publicKey;

  SessionSynAck({
    required this.publicKey,
  });

  factory SessionSynAck.fromJson(Map<String, dynamic> json) => _$SessionSynAckFromJson(json);
  Map<String, dynamic> toJson() => _$SessionSynAckToJson(this);
}

@JsonSerializable()
class SessionAck {
  final String encryptedSessionKey;

  SessionAck({
    required this.encryptedSessionKey,
  });

  factory SessionAck.fromJson(Map<String, dynamic> json) => _$SessionAckFromJson(json);
  Map<String, dynamic> toJson() => _$SessionAckToJson(this);
}

@JsonSerializable()
class Session extends SessionSyn {
  String? sessionKey;

  Session({
    required super.atSign,
    required super.clientId,
    super.clientName,
    super.syncSpace,
    this.sessionKey,
  });

  Session.fromSyn(SessionSyn syn, {this.sessionKey})
      : super(
          atSign: syn.atSign,
          clientId: syn.clientId,
          clientName: syn.clientName,
          syncSpace: syn.syncSpace,
        );

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SessionToJson(this);
}
