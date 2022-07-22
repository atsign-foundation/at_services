import 'package:at_onboarding_cli/at_onboarding_cli.dart';

class OnboardingManager {
  static final OnboardingManager _singleton = OnboardingManager._();
  OnboardingManager._();
  factory OnboardingManager() => _singleton;

  Map<String, AtOnboardingService> onboardingServiceMap = {};
  String? currentAtSign;
}