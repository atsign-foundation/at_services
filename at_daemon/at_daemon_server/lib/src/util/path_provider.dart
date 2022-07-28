import 'dart:io';

// Get the home directory or null if unknown.
String? getHomeDirectory() {
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      return Platform.environment['HOME'];
    case 'windows':
      return Platform.environment['USERPROFILE'];
    case 'android':
    case 'ios':
    case 'fuchsia':
    default:
      return null;
  }
}

String? getAtsignDirectory() => getHomeDirectory()?.concat('/.atsign');
String? getKeysDirectory() => getAtsignDirectory()?.concat('/keys');
String? getDaemonDirectory() => getAtsignDirectory()?.concat('/at_daemon');

// Used to keep the functions in path_provider.dart clean
// Shortens the syntax of returning null when attempting to concatenate a String to null
extension Concat on String {
  String concat(String o) => this + o;
}
