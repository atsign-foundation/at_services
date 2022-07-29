// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnknownCommandResponse _$UnknownCommandResponseFromJson(
        Map<String, dynamic> json) =>
    UnknownCommandResponse();

Map<String, dynamic> _$UnknownCommandResponseToJson(
        UnknownCommandResponse instance) =>
    <String, dynamic>{};

GetResponse _$GetResponseFromJson(Map<String, dynamic> json) => GetResponse(
      json['value'],
    );

Map<String, dynamic> _$GetResponseToJson(GetResponse instance) =>
    <String, dynamic>{
      'value': instance.value,
    };

PutResponse _$PutResponseFromJson(Map<String, dynamic> json) => PutResponse(
      json['result'] as bool,
    );

Map<String, dynamic> _$PutResponseToJson(PutResponse instance) =>
    <String, dynamic>{
      'result': instance.result,
    };

GetKeysResponse _$GetKeysResponseFromJson(Map<String, dynamic> json) =>
    GetKeysResponse(
      (json['keys'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$GetKeysResponseToJson(GetKeysResponse instance) =>
    <String, dynamic>{
      'keys': instance.keys,
    };
