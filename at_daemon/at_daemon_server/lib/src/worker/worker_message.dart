part of 'worker.dart';

abstract class WorkerMessage {}

abstract class WorkerAction implements WorkerMessage {}

abstract class WorkerVerb implements WorkerAction {}

abstract class WorkerResult implements WorkerMessage {}

// Kill
class KillAction implements WorkerAction {}

class Killed implements WorkerResult {}

// Onboard
class OnboardAction implements WorkerAction {
  final String atSign;
  final String keyFilePath;
  final String logLevel;
  const OnboardAction({required this.atSign, required this.keyFilePath, String? logLevel})
      : logLevel = logLevel ?? 'severe';
}

class Onboarded implements WorkerResult {
  final bool isOnboarded;
  const Onboarded(this.isOnboarded);
}

// Create Session
class CreateSessionAction implements WorkerAction {
  final SendPort sendPort;
  const CreateSessionAction(this.sendPort);
}

// Echo a message
class EchoAction implements WorkerAction {
  final String atSign;
  final Iterable<String> message;
  const EchoAction(this.atSign, this.message);
}

// VERBS
class GetVerb implements WorkerVerb {
  final AtKey key;
  final bool isDedicated;
  const GetVerb(this.key, {this.isDedicated = false});
}

class GetResult implements WorkerResult {
  final dynamic value;
  const GetResult(this.value);
}

class PutVerb implements WorkerVerb {
  final AtKey key;
  final dynamic value;
  final bool isDedicated;
  const PutVerb(this.key, this.value, {this.isDedicated = false});
}

class PutResult implements WorkerResult {
  final bool result;
  const PutResult(this.result);
}

class GetKeysVerb implements WorkerVerb {
  final String? regex;
  final String? sharedBy;
  final String? sharedWith;
  final bool showHiddenKeys;
  final bool isDedicated;
  GetKeysVerb({this.regex, this.sharedBy, this.sharedWith, this.showHiddenKeys = false, this.isDedicated = false});
}

class GetKeysResult implements WorkerResult {
  final List<String> keys;
  GetKeysResult(this.keys);
}
