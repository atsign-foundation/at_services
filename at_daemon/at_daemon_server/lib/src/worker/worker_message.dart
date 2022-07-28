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
  final String? keyFile;
  OnboardAction(this.atSign, {this.keyFile});
}

class Onboarded implements WorkerResult {
  final bool isOnboarded;
  Onboarded(this.isOnboarded);
}

// Create Session
class CreateSessionAction implements WorkerAction {
  final SendPort sendPort;
  CreateSessionAction(this.sendPort);
}

// VERBS

//Get

// Put

