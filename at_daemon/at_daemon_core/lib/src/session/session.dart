import 'package:json_annotation/json_annotation.dart';

part 'session.g.dart';

@JsonSerializable()
class SessionSyn {
  final String atSign; // Isolate
  final String clientId; // Web URL or applicationId
  final String clientName; // Human readable / pretty version of clientId
  final String syncSpace; // Requesting application's syncSpace

  SessionSyn({
    required this.atSign,
    required this.clientId,
    String? clientName, // defaults to match clientId
    this.syncSpace = '.*', // defaults to everything
  }) : clientName = clientName ?? clientId;

  factory SessionSyn.fromJson(Map<String, dynamic> json) => _$SessionSynFromJson(json);
  Map<String, dynamic> toJson() => _$SessionSynToJson(this);
}

@JsonSerializable()
class SessionSynAck {
  final String sessionId;
  final String publicKey;

  SessionSynAck({
    required this.sessionId,
    required this.publicKey,
  });

  factory SessionSynAck.fromJson(Map<String, dynamic> json) => _$SessionSynAckFromJson(json);
  Map<String, dynamic> toJson() => _$SessionSynAckToJson(this);
}

@JsonSerializable()
class SessionAck {
  final String sessionId;
  final String sessionKey; // client session key encrypted with daemon pub key

  SessionAck({
    required this.sessionId,
    required this.sessionKey,
  });

  factory SessionAck.fromJson(Map<String, dynamic> json) => _$SessionAckFromJson(json);
  Map<String, dynamic> toJson() => _$SessionAckToJson(this);
}
