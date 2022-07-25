abstract class WorkerAction {}

class KillAction implements WorkerAction {}

class OnboardAction implements WorkerAction {
  String atSign;
  OnboardAction(this.atSign);
}
