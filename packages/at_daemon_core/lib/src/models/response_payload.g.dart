// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnknownCommandResponse _$UnknownCommandResponseFromJson(
        Map<String, dynamic> json) =>
    UnknownCommandResponse(
      json['requestId'] as String?,
    );

Map<String, dynamic> _$UnknownCommandResponseToJson(
        UnknownCommandResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
    };

GetResponse _$GetResponseFromJson(Map<String, dynamic> json) => GetResponse(
      json['requestId'] as String?,
      json['value'],
    );

Map<String, dynamic> _$GetResponseToJson(GetResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'value': instance.value,
    };

PutResponse _$PutResponseFromJson(Map<String, dynamic> json) => PutResponse(
      json['requestId'] as String?,
      json['result'] as bool,
    );

Map<String, dynamic> _$PutResponseToJson(PutResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'result': instance.result,
    };

GetKeysResponse _$GetKeysResponseFromJson(Map<String, dynamic> json) =>
    GetKeysResponse(
      json['requestId'] as String?,
      (json['keys'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$GetKeysResponseToJson(GetKeysResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'keys': instance.keys,
    };

NotifyUpdateResponse _$NotifyUpdateResponseFromJson(
        Map<String, dynamic> json) =>
    NotifyUpdateResponse(
      json['requestId'] as String?,
      json['notificationID'] as String,
      json['key'] as String,
    );

Map<String, dynamic> _$NotifyUpdateResponseToJson(
        NotifyUpdateResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'notificationID': instance.notificationID,
      'key': instance.key,
    };

NotifyDeleteResponse _$NotifyDeleteResponseFromJson(
        Map<String, dynamic> json) =>
    NotifyDeleteResponse(
      json['requestId'] as String?,
      json['notificationID'] as String,
      json['key'] as String,
    );

Map<String, dynamic> _$NotifyDeleteResponseToJson(
        NotifyDeleteResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'notificationID': instance.notificationID,
      'key': instance.key,
    };
