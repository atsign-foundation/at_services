import 'package:at_daemon_core/src/models/payload.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_payload.g.dart';

abstract class ResponsePayload extends Payload {
  String? requestId;

  ResponsePayload(this.requestId);
}

@JsonSerializable()
class UnknownCommandResponse extends ResponsePayload {
  static final String type = 'unknown_command_response';

  UnknownCommandResponse(super.requestId);

  factory UnknownCommandResponse.fromJson(Map<String, dynamic> json) => _$UnknownCommandResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$UnknownCommandResponseToJson(this)};
  }
}

@JsonSerializable()
class GetResponse extends ResponsePayload {
  static final String type = 'get:response';

  final dynamic value;

  GetResponse(super.requestId, this.value);

  factory GetResponse.fromJson(Map<String, dynamic> json) => _$GetResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$GetResponseToJson(this)};
  }
}

@JsonSerializable()
class PutResponse extends ResponsePayload {
  static final String type = 'put:response';
  final bool result;

  PutResponse(super.requestId, this.result);

  factory PutResponse.fromJson(Map<String, dynamic> json) => _$PutResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$PutResponseToJson(this)};
  }
}

@JsonSerializable()
class GetKeysResponse extends ResponsePayload {
  static final String type = 'getkeys:response';
  final List<String> keys;

  GetKeysResponse(super.requestId, this.keys);

  factory GetKeysResponse.fromJson(Map<String, dynamic> json) => _$GetKeysResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$GetKeysResponseToJson(this)};
  }
}

abstract class NotifyResponse extends ResponsePayload {
  String notificationID;
  String key;

  NotifyResponse(super.requestId, this.notificationID, this.key);
}
@JsonSerializable()
class NotifyUpdateResponse extends NotifyResponse {
  static final String type = 'notifyUpdate:response';

  NotifyUpdateResponse(super.requestId, super.notificationID, super.key);

  factory NotifyUpdateResponse.fromJson(Map<String, dynamic> json) => _$NotifyUpdateResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$NotifyUpdateResponseToJson(this)};
  }
}

@JsonSerializable()
class NotifyDeleteResponse extends NotifyResponse {
  static final String type = 'notifyDelete:response';

  NotifyDeleteResponse(super.requestId, super.notificationID, super.key);

  factory NotifyDeleteResponse.fromJson(Map<String, dynamic> json) => _$NotifyDeleteResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$NotifyDeleteResponseToJson(this)};
  }
}
