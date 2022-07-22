import 'dart:io';

import 'concat.dart';

// Get the home directory or null if unknown.
String? getHomeDirectory() {
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      return Platform.environment['HOME'];
    case 'windows':
      return Platform.environment['USERPROFILE'];
    case 'android':
      // Probably want internal storage.
      return '/storage/sdcard0';
    case 'ios':
    case 'fuchsia':
    default:
      return null;
  }
}

String? getAtsignDirectory() => getHomeDirectory()?.concat('/.atsign');

String? getKeysDirectory() => getAtsignDirectory()?.concat('/keys');
String? getDaemonDirectory() => getAtsignDirectory()?.concat('/at_daemon');

String? getConfigDirectory(String atSign) => getDaemonDirectory()?.concat('/$atSign');

String? getWhitelistFile(String atSign) => getConfigDirectory(atSign)?.concat('/whitelist.json');
String? getBlacklistFile(String atSign) => getConfigDirectory(atSign)?.concat('/blacklist.json');
String? getOnboardedFile(String atSign) => getConfigDirectory(atSign)?.concat('/onboarded.json');
