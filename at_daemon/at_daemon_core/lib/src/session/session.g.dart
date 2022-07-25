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
    );

Map<String, dynamic> _$SessionSynToJson(SessionSyn instance) =>
    <String, dynamic>{
      'atSign': instance.atSign,
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'syncSpace': instance.syncSpace,
    };

SessionSynAck _$SessionSynAckFromJson(Map<String, dynamic> json) =>
    SessionSynAck(
      sessionId: json['sessionId'] as String,
      publicKey: json['publicKey'] as String,
    );

Map<String, dynamic> _$SessionSynAckToJson(SessionSynAck instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'publicKey': instance.publicKey,
    };

SessionAck _$SessionAckFromJson(Map<String, dynamic> json) => SessionAck(
      sessionId: json['sessionId'] as String,
      sessionKey: json['sessionKey'] as String,
    );

Map<String, dynamic> _$SessionAckToJson(SessionAck instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'sessionKey': instance.sessionKey,
    };
