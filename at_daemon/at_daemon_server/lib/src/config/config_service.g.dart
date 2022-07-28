// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigService _$ConfigServiceFromJson(Map<String, dynamic> json) =>
    ConfigService(
      blacklist: (json['blacklist'] as List<dynamic>?)
              ?.map((e) => ListTuple.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      whitelist: (json['whitelist'] as List<dynamic>?)
              ?.map((e) => ListTuple.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ConfigServiceToJson(ConfigService instance) =>
    <String, dynamic>{
      'blacklist': instance.blacklist,
      'whitelist': instance.whitelist,
    };
