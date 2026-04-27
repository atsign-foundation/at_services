import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_utils.dart';

import 'secondary_bridge_base.dart';

/// Bridges an inbound [WebSocket] from an atClient to an outbound [WebSocket]
/// on the upstream atServer's `/ws` endpoint. State machine and
/// orchestration live in [SecondaryBridgeBase]; this class supplies the
/// `WebSocket`-specific transport ops.
class SecondaryWebSocketBridge extends SecondaryBridgeBase {
  final WebSocket _clientWs;
  late WebSocket _secondaryWs;

  final WebSocketCreator _webSocketCreator;

  SecondaryWebSocketBridge(
    String proxyUrl,
    this._clientWs,
    SecondaryAddressFinder secondaryAddressFinder,
    SecurityContext clientContext, {
    WebSocketCreator? webSocketCreator,
  })  : _webSocketCreator = webSocketCreator ?? DefaultWebSocketCreator(),
        super(
          proxyUrl,
          secondaryAddressFinder,
          clientContext,
          initialLogger: AtSignLogger('SecondaryWebSocketBridge'),
        ) {
    _clientWs.listen(
      (dynamic data) {
        final List<int> bytes =
            data is String ? utf8.encode(data) : data as List<int>;
        handleClientData(bytes, data);
      },
      onDone: handleClientDone,
      onError: handleClientError,
    );

    logger.info('Sending @ prompt; started listening on new client WebSocket');
    sendPrompt();
  }

  @override
  void sendPrompt() => _clientWs.add('@');

  @override
  Future<void> writeErrorToClient(String msg) async {
    _clientWs.add('$msg\n');
  }

  @override
  Future<void> closeClient({int? closeCode, String? reason}) async {
    final r = reason == null ? null : _truncateUtf8(reason, 123);
    await _clientWs.close(closeCode, r);
  }

  @override
  Future<void> connectSecondary(String host, int port) async {
    _secondaryWs = await _webSocketCreator.create(host, port, clientContext);
    logger.info('Setting up secondary WebSocket listen');
    _secondaryWs.listen(
      handleSecondaryData,
      onDone: handleSecondaryDone,
      onError: handleSecondaryError,
    );
  }

  @override
  void forwardBufferedToSecondary(
      List<int> bufferedBytes, String parsedCommand) {
    // Forward as a single binary frame. The atServer's
    // InboundMessageListener._messageHandler appends inbound text-frame
    // bytes (utf8.encode) and binary-frame bytes identically, so binary
    // is byte-equivalent and avoids re-encoding what we already have as
    // bytes.
    _secondaryWs.add(bufferedBytes);
  }

  @override
  void forwardToSecondaryOpen(dynamic data) {
    _secondaryWs.add(data);
  }

  @override
  void forwardToClientOpen(dynamic data) {
    _clientWs.add(data);
  }

  @override
  void destroyClient() {
    try {
      _clientWs.close();
    } catch (_) {}
  }

  @override
  void destroySecondary() {
    try {
      _secondaryWs.close();
    } catch (_) {}
  }
}

/// Truncates [s] so that its UTF-8 encoding fits within [maxBytes], without
/// splitting a multi-byte character.
String _truncateUtf8(String s, int maxBytes) {
  final bytes = utf8.encode(s);
  if (bytes.length <= maxBytes) return s;
  var end = maxBytes;
  while (end > 0 && (bytes[end] & 0xC0) == 0x80) {
    end--;
  }
  return utf8.decode(bytes.sublist(0, end), allowMalformed: true);
}

abstract interface class WebSocketCreator {
  Future<WebSocket> create(
    String host,
    int port,
    SecurityContext clientContext,
  );
}

class DefaultWebSocketCreator implements WebSocketCreator {
  @override
  Future<WebSocket> create(
    String host,
    int port,
    SecurityContext clientContext,
  ) {
    final httpClient = HttpClient(context: clientContext);
    return WebSocket.connect(
      'wss://$host:$port/ws',
      customClient: httpClient,
    );
  }
}
