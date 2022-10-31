import 'dart:async';
import 'dart:io';

import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:path/path.dart' show basename;

class OnboardingManager {
  static final OnboardingManager _singleton = OnboardingManager._();
  factory OnboardingManager() => _singleton;
  OnboardingManager._();

  ConfigService configService = ConfigService();

  Future<bool> onboard({required String atSign, required File keyFile, required String logLevel}) async {
    Directory keysDir = Directory(getKeysDirectory() ?? (throw PathException('Could not get .atsign directory path')));
    File storedKeyFile;

    if (keyFile.parent.path == keysDir.path) {
      storedKeyFile = keyFile;
    } else {
      storedKeyFile = File('${keysDir.path}/${basename(keyFile.path)}');
      if (!await storedKeyFile.exists()) await storedKeyFile.create(recursive: true);
      await storedKeyFile.openWrite().addStream(keyFile.openRead());
    }

    WorkerIsolateChannel channel = await AtSignWorkerManager().getChannel(atSign);
    channel.sendPort!.send(OnboardAction(atSign: atSign, keyFilePath: storedKeyFile.absolute.path, logLevel: logLevel));
    Onboarded result = await channel.streamQueue.next;

    await configService.load();
    if (result.isOnboarded) {
      configService.addOnboarded(atSign, storedKeyFile.absolute.path);
    } else {
      configService.removeOnboarded(atSign);
    }
    await configService.save();

    return result.isOnboarded;
  }
}
