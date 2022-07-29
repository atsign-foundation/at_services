part of 'worker.dart';

abstract class WorkerMessage {}

abstract class WorkerAction implements WorkerMessage {}

abstract class WorkerVerb implements WorkerMessage {}

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

// Get

// Put

