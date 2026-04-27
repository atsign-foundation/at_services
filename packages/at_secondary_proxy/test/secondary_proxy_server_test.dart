import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_lookup/at_lookup.dart';
import 'package:test/test.dart';

import 'lib/recording_secondary_address_finder.dart';
import 'lib/secondary_proxy_server_test_helpers.dart';
import 'package:at_secondary_proxy/src/secondary_proxy_server.dart';

void main() {
  group('SecondaryProxyServer', () {
    late SecondaryProxyServer server;
    late RecordingSecondaryAddressFinder addressFinder;

    // runs for each test
    setUp(() async {
      // set up an addressFinder that always fails
      addressFinder = RecordingSecondaryAddressFinder(
        (_) => Future<SecondaryAddress>.error(Exception('no secondary')),
      );

      // set up and start the server
      server = SecondaryProxyServer('proxy.example', 9449, 0, addressFinder);
      server.startServing();

      // wait until the server is running
      await waitFor(() => server.running);
    });

    // runs after each test
    tearDown(() async {
      try {
        final socket = getSecureServerSocket(server);
        await socket.close();
      } catch (_) {
        // ignore close failures in tests
      }
    });

    test('startServing sets running and accepts client connections', () async {
      // in this test,
      // we expect that after running SecondaryProxyServer.startServing(),
      // the server is running and accepts client connections
      final serverSocket = getSecureServerSocket(server);
      final port = serverSocket.port;

      // this completer will complete when we receive data from the server
      final promptCompleter = Completer<String>();

      // this socket represents a client connecting to the server
      final SecureSocket client = await SecureSocket.connect(
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

      // since we wrote @alice to the proxy secondary server and it is using a recording secondary address finder
      // we will expect that the address finder recorded a lookup for @alice
      // this means that the proxy server accepted the client connection and processed the input
      // and attempted addressFinder.findSecondary('@alice')
      print(addressFinder.lookups);
      expect(addressFinder.lookups, contains('@alice'));

      await client.close();
    });

    test('WebSocket on /ws receives @ prompt and triggers findSecondary',
        () async {
      final serverSocket = getSecureServerSocket(server);
      final port = serverSocket.port;

      // HttpClient that accepts the proxy's self-signed cert and negotiates
      // http/1.1 ALPN (matching what the proxy advertises on its inbound
      // listener).
      final httpClient = HttpClient(
          context: SecurityContext(withTrustedRoots: true)
            ..setAlpnProtocols(['http/1.1'], false))
        ..badCertificateCallback = (_, __, ___) => true;

      final ws = await WebSocket.connect(
        'wss://localhost:$port/ws',
        customClient: httpClient,
      );

      final received = <dynamic>[];
      final firstFrame = Completer<dynamic>();
      ws.listen(
        (frame) {
          received.add(frame);
          if (!firstFrame.isCompleted) firstFrame.complete(frame);
        },
        onError: (_) {},
        onDone: () {},
      );

      final prompt =
          await firstFrame.future.timeout(const Duration(seconds: 2));
      expect(prompt, '@');

      ws.add('from:@alice\n');
      // Give the proxy time to parse the command and invoke findSecondary
      // (which throws in this test, closing the bridge).
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(addressFinder.lookups, contains('@alice'));

      try {
        await ws.close();
      } catch (_) {}
      httpClient.close(force: true);
    });

    test('does not create bridge when running flag is false', () async {
      final serverSocket = getSecureServerSocket(server);
      final port = serverSocket.port;

      // manually set isRunning to false
      setRunning(server, false);
      addressFinder.lookups.clear();

      // create a socket to write to the server
      final client = await SecureSocket.connect(
        InternetAddress.loopbackIPv4,
        port,
        onBadCertificate: (_) => true,
      );

      client.write('from:@bob\n');
      await client.flush();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // since it's not running,
      // we expect that no lookups were made
      expect(addressFinder.lookups, isEmpty);

      await client.close();
    });
  });
}
