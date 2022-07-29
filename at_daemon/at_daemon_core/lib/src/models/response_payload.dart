import 'package:at_daemon_core/src/models/payload.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response_payload.g.dart';

abstract class ResponsePayload extends Payload {}

@JsonSerializable()
class UnknownCommandResponse extends ResponsePayload {
  static final String type = 'unknown_command_response';

  UnknownCommandResponse();

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

  GetResponse(this.value);

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

  PutResponse(this.result);

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

  GetKeysResponse(this.keys);

  factory GetKeysResponse.fromJson(Map<String, dynamic> json) => _$GetKeysResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, ..._$GetKeysResponseToJson(this)};
  }
}
