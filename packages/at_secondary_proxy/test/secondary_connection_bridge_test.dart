import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:at_lookup/at_lookup.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:at_secondary_proxy/src/secondary_connection_bridge.dart';

import 'lib/mock/mocks.dart';

const dummyProxyUrl = 'proxy.example';

void main() {
  group('SecondaryConnectionBridge start state', () {
    // a mock SecureSocket to simulate client connection
    late SecureSocketMock clientSocket;

    // a mock SecondaryAddressFinder, we don't care about its behavior in these tests
    late SecondaryAddressFinderMock addressFinder;

    // to capture what gets written to the client socket
    late List<String> writes;

    setUp(() {
      // create Mocks
      clientSocket = SecureSocketMock();
      clientSocket.setDoneFuture(Future<
          void>.value()); // simulate a socket that is open and not closed
      addressFinder = SecondaryAddressFinderMock();
      writes = <String>[];

      // define how clientSocket responds to .write
      when(() => clientSocket.write(any())).thenAnswer((invocation) {
        // capture what is written to the socket
        writes.add(invocation.positionalArguments[0] as String);
        return;
      });

      registerFallbackValue(
        SecurityContext(withTrustedRoots: true),
      );

      // create the SecondaryConnectionBridge
      SecondaryConnectionBridge(
        dummyProxyUrl,
        clientSocket,
        addressFinder,
        SecurityContext(withTrustedRoots: true),
      );
    });

    test('SecondaryConnectionBridge sends "@" prompt upon construction',
        () async {
      // in this test,
      // we expect it to send back "@" prompt when the connection is established
      // this indicates that the proxy server created a bridge for us to that atServer

      // create SecondaryConnectionBridge
      expect(writes, contains('@'));
    });

    test(
        'SecondaryConnectionBridge is in `opening` state and rejects non-`from:` commands',
        () async {
      // in this test,
      // we send a non-valid command to the proxy server
      // we expect it to return the address of the proxy server back to us (Which is the same address we connected with anyways)

      // simulate sending an invalid command
      final Uint8List invalidCommand =
          Uint8List.fromList('invalid_command\n'.codeUnits);
      clientSocket.controller.add(invalidCommand);

      // give some time for the async processing to complete
      await Future.delayed(Duration(milliseconds: 100));

      // the SecondaryConnectionBridge should respond with the proxyUrl
      // because the command was invalid, so it is telling us to potentially reconnect via the proxyUrl
      expect(writes, contains('$dummyProxyUrl\n'));
    });

    tearDown(() async {
      await clientSocket.closeController();
    });
  });

  group('SecondaryConnectionBridge race conditions', () {
    // a mock SecureSocket to simulate client connection
    late SecureSocketMock clientSocket;

    late SecureSocketMock mockSecondarySocket;

    List<String> reads = <String>[];

    // a mock SecondaryAddressFinder, we don't care about its behavior in these tests
    late SecondaryAddressFinderMock addressFinder;

    // a mock SocketCreator to simulate creating secondary connections
    late SocketCreatorMock socketCreator;

    setUp(() {
      clientSocket = SecureSocketMock();
      clientSocket.setDoneFuture(Future<
          void>.value()); // simulate a socket that is open and not closed
      addressFinder = SecondaryAddressFinderMock();
      socketCreator = SocketCreatorMock();
      mockSecondarySocket = SecureSocketMock();
    });
    test('SecondaryConnectionBridge does not fail when writing concurrently',
        () async {
      when(() => mockSecondarySocket.add(any())).thenAnswer((invocation) {
        // capture what is written to the socket
        mockSecondarySocket.controller
            .add(invocation.positionalArguments[0] as Uint8List);
        reads.add(utf8.decode(invocation.positionalArguments[0] as Uint8List));
        return;
      });

      when(() => socketCreator.create(any(), any(), any()))
          .thenAnswer((_) async => mockSecondarySocket);

      when(() => addressFinder.findSecondary(any()))
          .thenAnswer((_) async => SecondaryAddress('secondary.example', 64));
      // create the SecondaryConnectionBridge
      SecondaryConnectionBridge(dummyProxyUrl, clientSocket, addressFinder,
          SecurityContext(withTrustedRoots: true),
          socketCreator: socketCreator);
      // simulate sending a valid from: command
      final Uint8List validCommand =
          Uint8List.fromList('from:@alice\n'.codeUnits);
      clientSocket.controller.add(validCommand);

      // give some time for the async processing to complete
      await Future.delayed(Duration(milliseconds: 500));

      // Simulate multiple writes happening concurrently
      clientSocket.controller.add(Uint8List.fromList("Hello".codeUnits));
      clientSocket.controller.add(Uint8List.fromList("World".codeUnits));
      clientSocket.controller.add(Uint8List.fromList("!\n".codeUnits));

      // give some time for the async processing to complete
      await Future.delayed(Duration(milliseconds: 100));
      expect(reads, containsAll(['Hello', 'World', '!\n']));
    });
  });
}
