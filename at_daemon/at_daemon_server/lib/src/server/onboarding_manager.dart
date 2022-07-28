import 'dart:async';

class OnboardingManager {
  static final OnboardingManager _singleton = OnboardingManager._();
  factory OnboardingManager() => _singleton;
  OnboardingManager._();

  late OnboardingHandler handler;
}

abstract class OnboardingHandler {
  FutureOr<bool> onboard({required String atSign});
}
