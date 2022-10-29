// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_tuple.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListTuple _$ListTupleFromJson(Map<String, dynamic> json) => ListTuple(
      json['atSign'] as String,
      json['clientId'] as String,
      until: json['until'] == null
          ? null
          : DateTime.parse(json['until'] as String),
    );

Map<String, dynamic> _$ListTupleToJson(ListTuple instance) => <String, dynamic>{
      'atSign': instance.atSign,
      'clientId': instance.clientId,
      'until': instance.until?.toIso8601String(),
    };
