import 'package:at_daemon_core/src/models/payload.dart';
import 'package:json_annotation/json_annotation.dart';

part 'request_payload.g.dart';

abstract class RequestPayload extends Payload {
  String? requestId;

  RequestPayload(this.requestId);
}

@JsonSerializable()
class GetRequest extends RequestPayload {
  static final String type = 'get';
  final String key;
  final bool isDedicated;

  GetRequest(super.requestId, this.key, {this.isDedicated = false});

  factory GetRequest.fromJson(json) => _$GetRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$GetRequestToJson(this)};
  }
}

@JsonSerializable()
class PutRequest extends RequestPayload {
  static final String type = 'put';
  final String key;
  final dynamic value;
  final bool isDedicated;

  PutRequest(super.requestId, this.key, this.value, {this.isDedicated = false});

  factory PutRequest.fromJson(json) => _$PutRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$PutRequestToJson(this)};
  }
}

@JsonSerializable()
class GetKeysRequest extends RequestPayload {
  static final String type = 'getkeys';
  final String? regex;
  final String? sharedBy;
  final String? sharedWith;
  final bool showHiddenKeys;
  final bool isDedicated;
  GetKeysRequest(super.requestId, {this.regex, this.sharedBy, this.sharedWith, this.showHiddenKeys = false, this.isDedicated = false});

  factory GetKeysRequest.fromJson(json) => _$GetKeysRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$GetKeysRequestToJson(this)};
  }
}

@JsonSerializable()
class NotifyUpdateRequest extends RequestPayload {
  static final String type = 'notifyUpdate';
  final String key;
  final dynamic value;

  NotifyUpdateRequest(super.requestId, this.key, this.value);

  factory NotifyUpdateRequest.fromJson(json) => _$NotifyUpdateRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$NotifyUpdateRequestToJson(this)};
  }
}

@JsonSerializable()
class NotifyDeleteRequest extends RequestPayload {
  static final String type = 'notifyDelete';
  final String key;

  NotifyDeleteRequest(super.requestId, this.key);

  factory NotifyDeleteRequest.fromJson(json) => _$NotifyDeleteRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$NotifyDeleteRequestToJson(this)};
  }
}
