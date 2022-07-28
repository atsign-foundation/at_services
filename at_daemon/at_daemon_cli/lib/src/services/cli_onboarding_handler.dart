import 'dart:async';
import 'dart:io';

import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:interact/interact.dart';

class CliOnboardingHandler implements OnboardingHandler {
  @override
  Future<bool> onboard({required String atSign}) async {
    Directory supportDir = Directory(getKeysDirectory() ?? (throw PathException('Could not get Keys path')));
    String storage = supportDir.path;

    AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
      ..isLocalStoreRequired = true
      ..hiveStoragePath = '$storage/hive'
      ..downloadPath = '$storage/files'
      ..commitLogPath = '$storage/commitLog'
      ..rootDomain = 'root.atsign.org';

    const keyOptions = ['atKeys File', 'Private Key'];
    final selectedKeyOption = Select(prompt: 'Onboard your keys using:', options: keyOptions).interact();

    switch (selectedKeyOption) {
      case 0:
        atOnboardingPreference.atKeysFilePath = Input(prompt: 'Path to the atKeys file:').interact();
        break;
      case 1:
        atOnboardingPreference.privateKey = Password(prompt: 'Private Key').interact();
        break;
      default:
        break;
    }

    AtOnboardingService onboardingService = AtOnboardingServiceImpl(atSign, atOnboardingPreference);

    bool result = await onboardingService.authenticate();
    return result;
  }
}
