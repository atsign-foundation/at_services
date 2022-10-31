part of 'worker.dart';

abstract class WorkerMessage {}

abstract class WorkerAction implements WorkerMessage {}
abstract class WorkerActionResult implements WorkerMessage {}

abstract class WorkerVerb implements WorkerAction {
  final String? requestId;
  WorkerVerb(this.requestId);
}
abstract class WorkerVerbResult implements WorkerActionResult {
  final String? requestId;
  WorkerVerbResult(this.requestId);
}

// Kill
class KillAction implements WorkerAction {
  KillAction() {
    // TODO gkc added this to help with figuring out where and why a KillAction is created if things go wrong
    try {
      throw Exception('KillAction created');
    } catch (e, st) {
      atDaemonLogger.shout('KillAction constructed. StackTrace: $st');
    }
  }
}

class Killed implements WorkerActionResult {}

// Onboard
class OnboardAction implements WorkerAction {
  final String atSign;
  final String keyFilePath;
  final String logLevel;
  const OnboardAction({required this.atSign, required this.keyFilePath, String? logLevel})
      : logLevel = logLevel ?? 'info';
}

class Onboarded implements WorkerActionResult {
  final bool isOnboarded;
  const Onboarded(this.isOnboarded);
}

// Create Session
class CreateSessionAction implements WorkerAction {
  final SendPort sendPort;
  final String atSign;
  const CreateSessionAction(this.sendPort, this.atSign);
}

// Echo a message
class EchoAction implements WorkerAction {
  final String atSign;
  final Iterable<String> message;
  const EchoAction(this.atSign, this.message);
}

// VERBS
class GetVerb extends WorkerVerb {
  final AtKey key;
  final bool isDedicated;
  GetVerb(super.requestId, this.key, {this.isDedicated = false});

  @override
  String toString() {
    return 'GetVerb{key: $key, isDedicated: $isDedicated}';
  }
}

class GetResult extends WorkerVerbResult {
  final String? value;
  Exception? exception;

  GetResult(super.requestId, {this.value, this.exception});

  Map toJson() => {
    'requestId': requestId,
    'value': value,
    'exception': exception?.toString()
  };

  @override
  String toString() {
    return 'GetResult{value: $value, exception: $exception}';
  }
}

class PutVerb extends WorkerVerb {
  final AtKey key;
  final String? value;
  final bool isDedicated;
  PutVerb(super.requestId, this.key, this.value, {this.isDedicated = false});

  @override
  String toString() {
    return 'PutVerb{key: $key, value: $value, isDedicated: $isDedicated}';
  }
}

class PutResult extends WorkerVerbResult {
  bool? result;
  Exception? exception;

  PutResult(super.requestId, {this.result, this.exception});

  Map toJson() => {
    'requestId': requestId,
    'result': result,
    'exception': exception?.toString()
  };

  @override
  String toString() {
    return 'PutResult{result: $result, exception: $exception}';
  }
}

class GetKeysVerb extends WorkerVerb {
  final String? regex;
  final String? sharedBy;
  final String? sharedWith;
  final bool showHiddenKeys;
  final bool isDedicated;
  GetKeysVerb(super.requestId, {this.regex, this.sharedBy, this.sharedWith, this.showHiddenKeys = false, this.isDedicated = false});

  @override
  String toString() {
    return 'GetKeysVerb{regex: $regex, sharedBy: $sharedBy, sharedWith: $sharedWith, showHiddenKeys: $showHiddenKeys, isDedicated: $isDedicated}';
  }
}

class GetKeysResult extends WorkerVerbResult {
  List<String>? keys;
  Exception? exception;

  GetKeysResult(super.requestId, {this.keys, this.exception});

  Map toJson() => {
    'requestId': requestId,
    'keys': keys,
    'exception': exception?.toString()
  };

  @override
  String toString() {
    return 'GetKeysResult{keys: $keys, exception: $exception}';
  }
}

class NotifyUpdateVerb extends WorkerVerb {
  final AtKey key;
  dynamic value;

  NotifyUpdateVerb(super.requestId, this.key, this.value);

  @override
  String toString() {
    return 'NotifyUpdateVerb{key: $key, value: $value}';
  }
}

class NotifyUpdateResult extends WorkerVerbResult {
  String? notificationID;
  Exception? exception;

  NotifyUpdateResult(super.requestId, {this.notificationID, this.exception});

  Map toJson() => {
    'requestId': requestId,
    'notificationID': notificationID,
    'exception': exception?.toString()
  };

  @override
  String toString() {
    return 'NotifyUpdateResult{notificationID: $notificationID, exception: $exception}';
  }
}

class NotifyDeleteVerb extends WorkerVerb {
  final AtKey key;

  NotifyDeleteVerb(super.requestId, this.key);

  @override
  String toString() {
    return 'NotifyDeleteVerb{key: $key}';
  }
}

class NotifyDeleteResult extends WorkerVerbResult {
  String? notificationID;
  Exception? exception;

  NotifyDeleteResult(super.requestId, {this.notificationID, this.exception});

  Map toJson() => {
    'requestId': requestId,
    'notificationID': notificationID,
    'exception': exception?.toString()
  };

  @override
  String toString() {
    return 'NotifyDeleteResult{notificationID: $notificationID, exception: $exception}';
  }
}

