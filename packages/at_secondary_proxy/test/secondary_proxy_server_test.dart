import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:at_lookup/at_lookup.dart';
import 'package:test/test.dart';

import 'package:at_secondary_proxy/src/secondary_proxy_server.dart';

class RecordingSecondaryAddressFinder implements SecondaryAddressFinder {
  RecordingSecondaryAddressFinder(this._handler);

  final Future<SecondaryAddress> Function(String atSign) _handler;
  final List<String> lookups = <String>[];

  @override
  Future<SecondaryAddress> findSecondary(String atSign) {
    lookups.add(atSign);
    return _handler(atSign);
  }
}

Future<void> _waitFor(bool Function() condition,
    {Duration timeout = const Duration(seconds: 3)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not met before $timeout elapsed');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Symbol _privateSymbol(String name) {
  final library = reflectClass(SecondaryProxyServer).owner as LibraryMirror;
  return MirrorSystem.getSymbol(name, library);
}

SecureServerSocket _getSecureServerSocket(SecondaryProxyServer server) {
  final instance = reflect(server);
  return instance.getField(_privateSymbol('_secureServerSocket')).reflectee
      as SecureServerSocket;
}

void _setRunning(SecondaryProxyServer server, bool value) {
  final instance = reflect(server);
  instance.setField(_privateSymbol('_running'), value);
}

void main() {
  late Directory originalCwd;

  setUpAll(() {
    originalCwd = Directory.current;
    final certFile = File('certs/fullchain.pem');
    if (!certFile.existsSync()) {
      final packageDir =
          Directory('${originalCwd.path}/packages/at_secondary_proxy');
      if (!packageDir.existsSync()) {
        throw StateError('Expected package directory at ${packageDir.path}');
      }
      Directory.current = packageDir;
    }
  });

  tearDownAll(() {
    Directory.current = originalCwd;
  });

  group('SecondaryProxyServer', () {
    late SecondaryProxyServer server;
    late RecordingSecondaryAddressFinder addressFinder;

    setUp(() async {
      addressFinder = RecordingSecondaryAddressFinder(
        (_) => Future<SecondaryAddress>.error(Exception('no secondary')),
      );
      server = SecondaryProxyServer('proxy.example', 9449, 0, addressFinder);
      server.startServing();
      await _waitFor(() => server.running);
    });

    tearDown(() async {
      try {
        final socket = _getSecureServerSocket(server);
        await socket.close();
      } on Object {
        // ignore close failures in tests
      }
    });

    test('startServing sets running and accepts client connections', () async {
      final serverSocket = _getSecureServerSocket(server);
      final port = serverSocket.port;

      final promptCompleter = Completer<String>();

      final client = await SecureSocket.connect(
        InternetAddress.loopbackIPv4,
        port,
        onBadCertificate: (_) => true,
      );

      client.listen((data) {
        final text = utf8.decode(data);
        if (!promptCompleter.isCompleted) {
          promptCompleter.complete(text);
        }
      });

      final prompt =
          await promptCompleter.future.timeout(const Duration(seconds: 1));
      expect(prompt, contains('@'));
      expect(server.running, isTrue);

      client.write('from:@alice\n');
      await client.flush();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(addressFinder.lookups, contains('@alice'));

      await client.close();
    });

    test('does not create bridge when running flag is false', () async {
      final serverSocket = _getSecureServerSocket(server);
      final port = serverSocket.port;

      _setRunning(server, false);
      addressFinder.lookups.clear();

      final client = await SecureSocket.connect(
        InternetAddress.loopbackIPv4,
        port,
        onBadCertificate: (_) => true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(addressFinder.lookups, isEmpty);

      await client.close();
    });
  });
}
