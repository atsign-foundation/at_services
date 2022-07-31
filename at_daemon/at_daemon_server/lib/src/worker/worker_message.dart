part of 'worker.dart';

abstract class WorkerMessage {}

abstract class WorkerAction implements WorkerMessage {}

abstract class WorkerVerb implements WorkerAction {}

abstract class WorkerResult implements WorkerMessage {}

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

class Killed implements WorkerResult {}

// Onboard
class OnboardAction implements WorkerAction {
  final String atSign;
  final String keyFilePath;
  final String logLevel;
  const OnboardAction({required this.atSign, required this.keyFilePath, String? logLevel})
      : logLevel = logLevel ?? 'info';

  @override
  String toString() {
    return 'OnboardAction{atSign: $atSign, keyFilePath: $keyFilePath, logLevel: $logLevel}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardAction &&
          runtimeType == other.runtimeType &&
          atSign == other.atSign &&
          keyFilePath == other.keyFilePath &&
          logLevel == other.logLevel;

  @override
  int get hashCode => atSign.hashCode ^ keyFilePath.hashCode ^ logLevel.hashCode;
}

class Onboarded implements WorkerResult {
  final bool isOnboarded;
  const Onboarded(this.isOnboarded);

  @override
  String toString() {
    return 'Onboarded{isOnboarded: $isOnboarded}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Onboarded && runtimeType == other.runtimeType && isOnboarded == other.isOnboarded;

  @override
  int get hashCode => isOnboarded.hashCode;
}

// Create Session
class CreateSessionAction implements WorkerAction {
  final SendPort sendPort;
  final String atSign;
  const CreateSessionAction(this.sendPort, this.atSign);

  @override
  String toString() {
    return 'CreateSessionAction{sendPort: $sendPort}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CreateSessionAction && runtimeType == other.runtimeType && sendPort == other.sendPort;

  @override
  int get hashCode => sendPort.hashCode;
}

// Echo a message
class EchoAction implements WorkerAction {
  final String atSign;
  final Iterable<String> message;
  const EchoAction(this.atSign, this.message);

  @override
  String toString() {
    return 'EchoAction{atSign: $atSign, message: $message}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EchoAction && runtimeType == other.runtimeType && atSign == other.atSign && message == other.message;

  @override
  int get hashCode => atSign.hashCode ^ message.hashCode;
}

// VERBS
class GetVerb implements WorkerVerb {
  final AtKey key;
  final bool isDedicated;
  const GetVerb(this.key, {this.isDedicated = false});

  @override
  String toString() {
    return 'GetVerb{key: $key, isDedicated: $isDedicated}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetVerb && runtimeType == other.runtimeType && key == other.key && isDedicated == other.isDedicated;

  @override
  int get hashCode => key.hashCode ^ isDedicated.hashCode;
}

class GetResult implements WorkerResult {
  final String? value;
  Exception? exception;

  GetResult({this.value, this.exception});

  Map toJson() => {
    'value': value,
    'exception': exception?.toString()
  };

  @override
  String toString() {
    return 'GetResult{value: $value, exception: $exception}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetResult && runtimeType == other.runtimeType && value == other.value && exception == other.exception;

  @override
  int get hashCode => value.hashCode ^ exception.hashCode;
}

class PutVerb implements WorkerVerb {
  final AtKey key;
  final String? value;
  final bool isDedicated;
  const PutVerb(this.key, this.value, {this.isDedicated = false});

  @override
  String toString() {
    return 'PutVerb{key: $key, value: $value, isDedicated: $isDedicated}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PutVerb && runtimeType == other.runtimeType && key == other.key && value == other.value && isDedicated == other.isDedicated;

  @override
  int get hashCode => key.hashCode ^ value.hashCode ^ isDedicated.hashCode;
}

class PutResult implements WorkerResult {
  bool? result;
  Exception? exception;

  PutResult({this.result, this.exception});

  Map toJson() => {
    'result': result,
    'exception': exception?.toString()
  };

  @override
  String toString() {
    return 'PutResult{result: $result, exception: $exception}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PutResult && runtimeType == other.runtimeType && result == other.result && exception == other.exception;

  @override
  int get hashCode => result.hashCode ^ exception.hashCode;
}

class GetKeysVerb implements WorkerVerb {
  final String? regex;
  final String? sharedBy;
  final String? sharedWith;
  final bool showHiddenKeys;
  final bool isDedicated;
  GetKeysVerb({this.regex, this.sharedBy, this.sharedWith, this.showHiddenKeys = false, this.isDedicated = false});

  @override
  String toString() {
    return 'GetKeysVerb{regex: $regex, sharedBy: $sharedBy, sharedWith: $sharedWith, showHiddenKeys: $showHiddenKeys, isDedicated: $isDedicated}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetKeysVerb &&
          runtimeType == other.runtimeType &&
          regex == other.regex &&
          sharedBy == other.sharedBy &&
          sharedWith == other.sharedWith &&
          showHiddenKeys == other.showHiddenKeys &&
          isDedicated == other.isDedicated;

  @override
  int get hashCode => regex.hashCode ^ sharedBy.hashCode ^ sharedWith.hashCode ^ showHiddenKeys.hashCode ^ isDedicated.hashCode;
}

class GetKeysResult implements WorkerResult {
  List<String>? keys;
  Exception? exception;

  GetKeysResult({this.keys, this.exception});

  Map toJson() => {
    'keys': keys,
    'exception': exception?.toString()
  };

  @override
  String toString() {
    return 'GetKeysResult{keys: $keys, exception: $exception}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetKeysResult && runtimeType == other.runtimeType && keys == other.keys && exception == other.exception;

  @override
  int get hashCode => keys.hashCode ^ exception.hashCode;
}
