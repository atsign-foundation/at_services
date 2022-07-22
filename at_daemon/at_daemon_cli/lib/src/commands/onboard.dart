import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_daemon_cli/src/services/onboarding.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_utils.dart';
import 'package:interact/interact.dart';
import 'package:path_provider/path_provider.dart';

const _name = 'onboard';
const _description = 'Onboard an atSign to the system';

class OnboardCommand extends Command<bool> {
  @override
  String get name => _name;

  @override
  String get description => _description;

  OnboardCommand() {
    //TODO add commandline options to skip interactive
  }

  @override
  Future<bool> run() async {
    String? atSign;
    try {
      atSign = validateAtSignArg();
    } on InvalidAtSignException catch(e) {
      throw FormatException(e.message);
    }

    Directory supportDir = await getApplicationSupportDirectory();
    String storage = supportDir.path;

    AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
      ..isLocalStoreRequired = true
      ..hiveStoragePath = '$storage/hive'
      ..downloadPath = '$storage/files'
      ..commitLogPath = '$storage/commitLog'
      ..rootDomain = 'root.atsign.org';

    const keyOptions = ['atKeys File', 'Private Key'];
    final selectedKeyOption = Select(prompt: 'Onboard your keys using:', options: keyOptions).interact();

    switch(selectedKeyOption) {
      case 0:
        atOnboardingPreference.atKeysFilePath = Input(prompt: 'Path to the atKeys file:').interact();
        break;
      case 1:

        atOnboardingPreference.privateKey = Password(prompt: 'Private Key').interact();
        break;
      default: break;
    }

    AtOnboardingService onboardingService = AtOnboardingServiceImpl(atSign, atOnboardingPreference);
    OnboardingManager().onboardingServiceMap[atSign] = onboardingService;

    bool result =  await onboardingService.authenticate();

    if(result) {
      OnboardingManager().currentAtSign = atSign;
    }

    return result;
  }

  String validateAtSignArg() {
    if (argResults!.rest.isEmpty) {
      throw UsageException('No atSign specified for onboarding.', usage);
    }

    if (argResults!.rest.length > 1) {
      throw UsageException('Too many arguments specified.', usage);
    }

    return AtUtils.fixAtSign(AtUtils.formatAtSign(argResults!.rest.single)!);
  }

}
