import 'dart:async';
import 'dart:typed_data';

import 'package:at_secondary_proxy/at_secondary_proxy.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:at_secondary_proxy/src/secondary_connection_bridge.dart';

import 'mock/mocks.dart';

const dummyProxyUrl = 'proxy.example';

void main() {
  group('SecondaryConnectionBridge start state', () {
    // create Mocks
    final clientSocket = SecureSocketMock();
    final addressFinder = SecondaryAddressFinderMock();

    final writes = <String>[];

    // define how clientSocket responds to .write
    when(clientSocket.write(any)).thenAnswer((invocation) {
      writes.add(invocation.positionalArguments[0] as String);
      return;
    });


    test('SecondaryConnectionBridge sends "@" prompt upon construction', () async {
      // in this test,
      // we expect it to send back "@" prompt when the connection is established
      // this indicates that the proxy server created a bridge for us to that atServer

      // create SecondaryConnectionBridge
      SecondaryConnectionBridge(dummyProxyUrl, clientSocket, addressFinder);
      expect(writes, contains('@'));
    });

    test('SecondaryConnectionBridge is in `opening` state and rejects non-`from:` commands', () async {
      // in this test,
      // we send a non-valid command to the proxy server
      // we expect it to return the address of the proxy server back to us (Which is the same address we connected with anyways)

      // simulate sending an invalid command
      final Uint8List invalidCommand = Uint8List.fromList('invalid_command\n'.codeUnits);
      clientSocket.controller.add(invalidCommand);

      // give some time for the async processing to complete
      await Future.delayed(Duration(milliseconds: 100));

      // the SecondaryConnectionBridge should respond with the proxyUrl
      // because the command was invalid, so it is telling us to potentially reconnect via the proxyUrl
      expect(writes, contains('$dummyProxyUrl\n'));
    });

    tearDownAll(() async {
      await clientSocket.closeController();
    });
  });
}
