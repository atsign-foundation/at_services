// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetRequest _$GetRequestFromJson(Map<String, dynamic> json) => GetRequest(
      json['key'] as String,
      isDedicated: json['isDedicated'] as bool? ?? false,
    );

Map<String, dynamic> _$GetRequestToJson(GetRequest instance) =>
    <String, dynamic>{
      'key': instance.key,
      'isDedicated': instance.isDedicated,
    };

PutRequest _$PutRequestFromJson(Map<String, dynamic> json) => PutRequest(
      json['key'] as String,
      json['value'],
      isDedicated: json['isDedicated'] as bool? ?? false,
    );

Map<String, dynamic> _$PutRequestToJson(PutRequest instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'isDedicated': instance.isDedicated,
    };

GetKeysRequest _$GetKeysRequestFromJson(Map<String, dynamic> json) =>
    GetKeysRequest(
      regex: json['regex'] as String?,
      sharedBy: json['sharedBy'] as String?,
      sharedWith: json['sharedWith'] as String?,
      showHiddenKeys: json['showHiddenKeys'] as bool? ?? false,
      isDedicated: json['isDedicated'] as bool? ?? false,
    );

Map<String, dynamic> _$GetKeysRequestToJson(GetKeysRequest instance) =>
    <String, dynamic>{
      'regex': instance.regex,
      'sharedBy': instance.sharedBy,
      'sharedWith': instance.sharedWith,
      'showHiddenKeys': instance.showHiddenKeys,
      'isDedicated': instance.isDedicated,
    };
