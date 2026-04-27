import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_utils.dart';

import 'secondary_bridge_base.dart';

export 'secondary_bridge_base.dart' show BridgeState;

/// Bridges an inbound atProtocol [SecureSocket] from an atClient to an
/// outbound [SecureSocket] on the upstream atServer. State machine and
/// orchestration live in [SecondaryBridgeBase]; this class supplies the
/// `SecureSocket`-specific transport ops.
class SecondaryConnectionBridge extends SecondaryBridgeBase {
  final SecureSocket _clientSocket;
  late SecureSocket _secondarySocket;

  final SocketCreator _socketCreator;

  SecondaryConnectionBridge(
    String proxyUrl,
    this._clientSocket,
    SecondaryAddressFinder secondaryAddressFinder,
    SecurityContext clientContext, {
    SocketCreator? socketCreator,
  })  : _socketCreator = socketCreator ?? DefaultSocketCreator(),
        super(
          proxyUrl,
          secondaryAddressFinder,
          clientContext,
          initialLogger: AtSignLogger('SecondaryConnectionBridge'),
        ) {
    _clientSocket.listen(
      (Uint8List data) => handleClientData(data, data),
      onDone: handleClientDone,
      onError: handleClientError,
    );
    _clientSocket.done.onError((error, _) => handleClientError(error));

    logger.info('Sending @ prompt; started listening on new client socket');
    sendPrompt();
  }

  @override
  void sendPrompt() => _clientSocket.write('@');

  @override
  Future<void> writeErrorToClient(String msg) async {
    _clientSocket.write('$msg\n');
    await _clientSocket.flush();
  }

  @override
  Future<void> closeClient({int? closeCode, String? reason}) async {
    destroyClient();
  }

  @override
  Future<void> connectSecondary(String host, int port) async {
    _secondarySocket = await _socketCreator.create(host, port, clientContext);
    logger.info('Setting up secondary socket listen');
    _secondarySocket.listen(
      (Uint8List data) => handleSecondaryData(data),
      onDone: handleSecondaryDone,
      onError: handleSecondaryError,
    );
    unawaited(
        _secondarySocket.done.onError((error, _) => handleClientError(error)));
  }

  @override
  void forwardBufferedToSecondary(
      List<int> bufferedBytes, String parsedCommand) {
    // Preserves the historical behaviour of writing the trim-normalised
    // command back, rather than the raw buffered bytes.
    _secondarySocket.write('$parsedCommand\n');
  }

  @override
  void forwardToSecondaryOpen(dynamic data) {
    _secondarySocket.add(data as List<int>);
  }

  @override
  void forwardToClientOpen(dynamic data) {
    _clientSocket.add(data as List<int>);
  }

  @override
  void destroyClient() {
    try {
      _clientSocket.destroy();
    } catch (_) {}
  }

  @override
  void destroySecondary() {
    try {
      _secondarySocket.destroy();
    } catch (_) {}
  }
}

abstract interface class SocketCreator {
  Future<SecureSocket> create(
    String host,
    int port,
    SecurityContext clientContext,
  );
}

class DefaultSocketCreator implements SocketCreator {
  @override
  Future<SecureSocket> create(
    String host,
    int port,
    SecurityContext clientContext,
  ) {
    return SecureSocket.connect(host, port, context: clientContext);
  }
}
