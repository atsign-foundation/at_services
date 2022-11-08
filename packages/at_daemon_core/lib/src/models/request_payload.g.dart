// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetRequest _$GetRequestFromJson(Map<String, dynamic> json) => GetRequest(
      json['requestId'] as String?,
      json['key'] as String,
      isDedicated: json['isDedicated'] as bool? ?? false,
    );

Map<String, dynamic> _$GetRequestToJson(GetRequest instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'key': instance.key,
      'isDedicated': instance.isDedicated,
    };

PutRequest _$PutRequestFromJson(Map<String, dynamic> json) => PutRequest(
      json['requestId'] as String?,
      json['key'] as String,
      json['value'],
      isDedicated: json['isDedicated'] as bool? ?? false,
    );

Map<String, dynamic> _$PutRequestToJson(PutRequest instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'key': instance.key,
      'value': instance.value,
      'isDedicated': instance.isDedicated,
    };

GetKeysRequest _$GetKeysRequestFromJson(Map<String, dynamic> json) =>
    GetKeysRequest(
      json['requestId'] as String?,
      regex: json['regex'] as String?,
      sharedBy: json['sharedBy'] as String?,
      sharedWith: json['sharedWith'] as String?,
      showHiddenKeys: json['showHiddenKeys'] as bool? ?? false,
      isDedicated: json['isDedicated'] as bool? ?? false,
    );

Map<String, dynamic> _$GetKeysRequestToJson(GetKeysRequest instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'regex': instance.regex,
      'sharedBy': instance.sharedBy,
      'sharedWith': instance.sharedWith,
      'showHiddenKeys': instance.showHiddenKeys,
      'isDedicated': instance.isDedicated,
    };

NotifyUpdateRequest _$NotifyUpdateRequestFromJson(Map<String, dynamic> json) =>
    NotifyUpdateRequest(
      json['requestId'] as String?,
      json['key'] as String,
      json['value'],
    );

Map<String, dynamic> _$NotifyUpdateRequestToJson(
        NotifyUpdateRequest instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'key': instance.key,
      'value': instance.value,
    };

NotifyDeleteRequest _$NotifyDeleteRequestFromJson(Map<String, dynamic> json) =>
    NotifyDeleteRequest(
      json['requestId'] as String?,
      json['key'] as String,
    );

Map<String, dynamic> _$NotifyDeleteRequestToJson(
        NotifyDeleteRequest instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'key': instance.key,
    };
