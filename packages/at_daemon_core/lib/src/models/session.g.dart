// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionSyn _$SessionSynFromJson(Map<String, dynamic> json) => SessionSyn(
      atSign: json['atSign'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String?,
      syncSpace: json['syncSpace'] as String? ?? '.*',
      version: json['version'] as int? ?? 1,
    );

Map<String, dynamic> _$SessionSynToJson(SessionSyn instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'syncSpace': instance.syncSpace,
      'atSign': instance.atSign,
      'version': instance.version,
    };

SessionSynAck _$SessionSynAckFromJson(Map<String, dynamic> json) =>
    SessionSynAck(
      publicKey: json['publicKey'] as String,
    );

Map<String, dynamic> _$SessionSynAckToJson(SessionSynAck instance) =>
    <String, dynamic>{
      'publicKey': instance.publicKey,
    };

SessionAck _$SessionAckFromJson(Map<String, dynamic> json) => SessionAck(
      encryptedSessionKey: json['encryptedSessionKey'] as String,
    );

Map<String, dynamic> _$SessionAckToJson(SessionAck instance) =>
    <String, dynamic>{
      'encryptedSessionKey': instance.encryptedSessionKey,
    };

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
      atSign: json['atSign'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String?,
      syncSpace: json['syncSpace'] as String? ?? '.*',
      sessionKey: json['sessionKey'] as String?,
    );

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'syncSpace': instance.syncSpace,
      'atSign': instance.atSign,
      'sessionKey': instance.sessionKey,
    };
