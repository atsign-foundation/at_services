import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:at_secondary_proxy/src/secondary_proxy_server.dart';

/// Waits for [condition] to return true or throws after [timeout].
Future<void> waitFor(bool Function() condition,
    {Duration timeout = const Duration(seconds: 3)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not met before $timeout elapsed');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Returns the private symbol [name] from the [SecondaryProxyServer] library.
Symbol privateSymbol(String name) {
  final library = reflectClass(SecondaryProxyServer).owner as LibraryMirror;
  return MirrorSystem.getSymbol(name, library);
}

/// Retrieves the private `_secureServerSocket` field from [SecondaryProxyServer].
SecureServerSocket getSecureServerSocket(SecondaryProxyServer server) {
  final instance = reflect(server);
  return instance.getField(privateSymbol('_secureServerSocket')).reflectee
      as SecureServerSocket;
}

/// Sets the private `_running` flag on [SecondaryProxyServer].
void setRunning(SecondaryProxyServer server, bool value) {
  final instance = reflect(server);
  instance.setField(privateSymbol('_running'), value);
}
