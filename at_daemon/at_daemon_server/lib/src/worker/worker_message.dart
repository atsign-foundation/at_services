part of 'worker.dart';

abstract class WorkerMessage {}

abstract class WorkerAction implements WorkerMessage {}
abstract class WorkerResult implements WorkerMessage {}

class KillAction implements WorkerAction {}

class OnboardAction implements WorkerAction {
  String atSign;
  OnboardAction(this.atSign);
}


class Killed implements WorkerResult {}