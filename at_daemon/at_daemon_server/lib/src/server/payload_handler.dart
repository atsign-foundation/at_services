import 'dart:convert';

import 'package:at_client/at_client.dart';
import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:at_daemon_server/at_daemon_server.dart';

abstract class PayloadHandler<P extends Payload> {
  bool accept(String payload);

  P transformPayload(String payload);

  WorkerAction getAction(P payload);
}

class GetRequestHandler extends PayloadHandler<GetRequest> {
  @override
  bool accept(String payload) {
    return jsonDecode(payload)['type'] == GetRequest.type;
  }

  @override
  WorkerAction getAction(GetRequest payload) {
    return GetVerb(payload.requestId, AtKey.fromString(payload.key), isDedicated: payload.isDedicated);
  }

  @override
  GetRequest transformPayload(String payload) {
    return GetRequest.fromJson(jsonDecode(payload));
  }
}

class PutRequestHandler extends PayloadHandler<PutRequest> {
  @override
  bool accept(String payload) {
    return jsonDecode(payload)['type'] == PutRequest.type;
  }

  @override
  WorkerAction getAction(PutRequest payload) {
    return PutVerb(payload.requestId, AtKey.fromString(payload.key), payload.value, isDedicated: payload.isDedicated);
  }

  @override
  PutRequest transformPayload(String payload) {
    return PutRequest.fromJson(jsonDecode(payload));
  }
}

class GetKeysRequestHandler extends PayloadHandler<GetKeysRequest> {
  @override
  bool accept(String payload) {
    return jsonDecode(payload)['type'] == GetKeysRequest.type;
  }

  @override
  WorkerAction getAction(GetKeysRequest payload) {
    return GetKeysVerb(
      payload.requestId,
      regex: payload.regex,
      sharedBy: payload.sharedBy,
      sharedWith: payload.sharedWith,
      showHiddenKeys: payload.showHiddenKeys,
      isDedicated: payload.isDedicated,
    );
  }

  @override
  GetKeysRequest transformPayload(String payload) {
    return GetKeysRequest.fromJson(jsonDecode(payload));
  }
}

class NotifyUpdateRequestHandler extends PayloadHandler<NotifyUpdateRequest> {
  @override
  bool accept(String payload) {
    return jsonDecode(payload)['type'] == NotifyUpdateRequest.type;
  }

  @override
  WorkerAction getAction(NotifyUpdateRequest payload) {
    return NotifyUpdateVerb(payload.requestId, AtKey.fromString(payload.key), payload.value);
  }

  @override
  NotifyUpdateRequest transformPayload(String payload) {
    return NotifyUpdateRequest.fromJson(jsonDecode(payload));
  }
}

class NotifyDeleteRequestHandler extends PayloadHandler<NotifyDeleteRequest> {
  @override
  bool accept(String payload) {
    return jsonDecode(payload)['type'] == NotifyDeleteRequest.type;
  }

  @override
  WorkerAction getAction(NotifyDeleteRequest payload) {
    return NotifyDeleteVerb(payload.requestId, AtKey.fromString(payload.key));
  }

  @override
  NotifyDeleteRequest transformPayload(String payload) {
    return NotifyDeleteRequest.fromJson(jsonDecode(payload));
  }
}

