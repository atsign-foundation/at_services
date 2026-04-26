import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_lookup/at_lookup.dart';
import 'package:at_secondary_proxy/src/secondary_websocket_bridge.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'lib/mock/mocks.dart';

const dummyProxyUrl = 'proxy.example';

WebSocketMock _newClient() {
  final ws = WebSocketMock();
  return ws;
}

SecurityContext _ctx() => SecurityContext(withTrustedRoots: true);

void main() {
  setUpAll(() {
    registerFallbackValue(SecurityContext(withTrustedRoots: true));
  });

  group('SecondaryWebSocketBridge opening state', () {
    late WebSocketMock clientWs;
    late SecondaryAddressFinderMock addressFinder;
    late WebSocketCreatorMock creator;

    setUp(() {
      clientWs = _newClient();
      addressFinder = SecondaryAddressFinderMock();
      creator = WebSocketCreatorMock();
    });

    test('sends "@" prompt as a single text frame on construction', () {
      SecondaryWebSocketBridge(
        dummyProxyUrl,
        clientWs,
        addressFinder,
        _ctx(),
        webSocketCreator: creator,
      );

      expect(clientWs.sent, equals(<dynamic>['@']));
      verifyNever(() => addressFinder.findSecondary(any()));
      verifyNever(() => creator.create(any(), any(), any()));
    });

    test('valid single-frame from: triggers lookup and forwards bytes',
        () async {
      final upstreamWs = WebSocketMock();
      when(() => addressFinder.findSecondary('@alice'))
          .thenAnswer((_) async => SecondaryAddress('secondary.example', 64));
      when(() => creator.create('secondary.example', 64, any()))
          .thenAnswer((_) async => upstreamWs);

      SecondaryWebSocketBridge(
        dummyProxyUrl,
        clientWs,
        addressFinder,
        _ctx(),
        webSocketCreator: creator,
      );

      clientWs.controller.add('from:@alice\n');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => addressFinder.findSecondary('@alice')).called(1);
      verify(() => creator.create('secondary.example', 64, any())).called(1);
      // Buffered command bytes were forwarded as one frame.
      expect(upstreamWs.sent, hasLength(1));
      expect(utf8.decode(upstreamWs.sent.single as List<int>),
          equals('from:@alice\n'));
    });

    test('multi-frame from: is accumulated until newline', () async {
      final upstreamWs = WebSocketMock();
      when(() => addressFinder.findSecondary('@alice'))
          .thenAnswer((_) async => SecondaryAddress('secondary.example', 64));
      when(() => creator.create(any(), any(), any()))
          .thenAnswer((_) async => upstreamWs);

      SecondaryWebSocketBridge(
        dummyProxyUrl,
        clientWs,
        addressFinder,
        _ctx(),
        webSocketCreator: creator,
      );

      clientWs.controller.add('from:');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      verifyNever(() => addressFinder.findSecondary(any()));

      clientWs.controller.add('@alice\n');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => addressFinder.findSecondary('@alice')).called(1);
      expect(upstreamWs.sent, hasLength(1));
      expect(utf8.decode(upstreamWs.sent.single as List<int>),
          equals('from:@alice\n'));
    });

    test('mixed text+binary frames in opening accumulate as bytes', () async {
      final upstreamWs = WebSocketMock();
      when(() => addressFinder.findSecondary('@alice'))
          .thenAnswer((_) async => SecondaryAddress('secondary.example', 64));
      when(() => creator.create(any(), any(), any()))
          .thenAnswer((_) async => upstreamWs);

      SecondaryWebSocketBridge(
        dummyProxyUrl,
        clientWs,
        addressFinder,
        _ctx(),
        webSocketCreator: creator,
      );

      // text frame: "from:"
      clientWs.controller.add('from:');
      // binary frame: "@alice\n"
      clientWs.controller.add(<int>[0x40, 0x61, 0x6c, 0x69, 0x63, 0x65, 0x0a]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => addressFinder.findSecondary('@alice')).called(1);
      expect(utf8.decode(upstreamWs.sent.single as List<int>),
          equals('from:@alice\n'));
    });

    test('non-from first command sends proxyUrl error frame and closes',
        () async {
      SecondaryWebSocketBridge(
        dummyProxyUrl,
        clientWs,
        addressFinder,
        _ctx(),
        webSocketCreator: creator,
      );

      clientWs.controller.add('hello\n');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // sent: ['@', 'proxy.example\n']
      expect(clientWs.sent, equals(<dynamic>['@', '$dummyProxyUrl\n']));
      expect(clientWs.closeArgs?.code, WebSocketStatus.policyViolation);
      verifyNever(() => addressFinder.findSecondary(any()));
      verifyNever(() => creator.create(any(), any(), any()));
    });

    test('findSecondary failure sends error frame and closes', () async {
      when(() => addressFinder.findSecondary('@bob'))
          .thenThrow(Exception('not found'));

      SecondaryWebSocketBridge(
        dummyProxyUrl,
        clientWs,
        addressFinder,
        _ctx(),
        webSocketCreator: creator,
      );

      clientWs.controller.add('from:@bob\n');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(clientWs.sent.length, 2);
      expect(clientWs.sent.first, '@');
      expect(clientWs.sent.last, contains('not found'));
      expect(clientWs.closeArgs?.code, WebSocketStatus.policyViolation);
      verifyNever(() => creator.create(any(), any(), any()));
    });

    test('upstream connect failure sends error frame and closes', () async {
      when(() => addressFinder.findSecondary('@alice'))
          .thenAnswer((_) async => SecondaryAddress('secondary.example', 64));
      when(() => creator.create(any(), any(), any()))
          .thenThrow(SocketException('refused'));

      SecondaryWebSocketBridge(
        dummyProxyUrl,
        clientWs,
        addressFinder,
        _ctx(),
        webSocketCreator: creator,
      );

      clientWs.controller.add('from:@alice\n');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(clientWs.sent.length, 2);
      expect(clientWs.sent.last, contains('refused'));
      expect(clientWs.closeArgs?.code, WebSocketStatus.internalServerError);
    });

    test('buffer overflow before newline closes with policyViolation',
        () async {
      SecondaryWebSocketBridge(
        dummyProxyUrl,
        clientWs,
        addressFinder,
        _ctx(),
        webSocketCreator: creator,
      );

      // Send > 511 bytes with no newline.
      clientWs.controller.add('a' * 600);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(clientWs.sent, contains('Too much\n'));
      expect(clientWs.closeArgs?.code, WebSocketStatus.policyViolation);
      verifyNever(() => addressFinder.findSecondary(any()));
    });
  });

  group('SecondaryWebSocketBridge open state', () {
    late WebSocketMock clientWs;
    late WebSocketMock upstreamWs;
    late SecondaryAddressFinderMock addressFinder;
    late WebSocketCreatorMock creator;

    setUp(() async {
      clientWs = _newClient();
      upstreamWs = WebSocketMock();
      addressFinder = SecondaryAddressFinderMock();
      creator = WebSocketCreatorMock();

      when(() => addressFinder.findSecondary('@alice'))
          .thenAnswer((_) async => SecondaryAddress('secondary.example', 64));
      when(() => creator.create(any(), any(), any()))
          .thenAnswer((_) async => upstreamWs);

      SecondaryWebSocketBridge(
        dummyProxyUrl,
        clientWs,
        addressFinder,
        _ctx(),
        webSocketCreator: creator,
      );
      clientWs.controller.add('from:@alice\n');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Drop the bootstrap-forward and prompt frames so each test starts
      // counting from a clean slate.
      clientWs.sent.clear();
      upstreamWs.sent.clear();
    });

    test('upstream text frames forwarded to client preserving frame type',
        () async {
      upstreamWs.controller.add('@');
      upstreamWs.controller.add('data:proof:xyz\n@alice@');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(clientWs.sent, equals(<dynamic>['@', 'data:proof:xyz\n@alice@']));
      expect(clientWs.sent.every((e) => e is String), isTrue);
    });

    test('client binary frames forwarded as binary upstream', () async {
      final binary = <int>[0xDE, 0xAD, 0xBE, 0xEF];
      clientWs.controller.add(binary);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(upstreamWs.sent, equals(<dynamic>[binary]));
      expect(upstreamWs.sent.single, isA<List<int>>());
    });

    test('client text frames forwarded as text upstream', () async {
      clientWs.controller.add('lookup:phone@alice\n');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(upstreamWs.sent, equals(<dynamic>['lookup:phone@alice\n']));
      expect(upstreamWs.sent.single, isA<String>());
    });

    test('upstream close tears down client', () async {
      await upstreamWs.closeController();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(clientWs.closeArgs, isNotNull);
    });

    test('client close tears down upstream', () async {
      await clientWs.closeController();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(upstreamWs.closeArgs, isNotNull);
    });
  });
}
