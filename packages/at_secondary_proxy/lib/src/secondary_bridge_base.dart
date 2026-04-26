import 'dart:async';
import 'dart:convert';
import 'dart:io' show SecurityContext, WebSocketStatus;

import 'package:at_commons/at_commons.dart' hide StringBuffer;
import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_utils.dart';

enum BridgeState { opening, open, closing, closed }

/// Shared state machine for the proxy's two bridge implementations
/// ([SecondaryConnectionBridge] for raw `SecureSocket`s and
/// [SecondaryWebSocketBridge] for `WebSocket`s). Owns:
/// * the [BridgeState] lifecycle,
/// * the opening-state buffer accumulation, `from:` parsing, atSign lookup,
///   upstream-connect, and bootstrap-forward,
/// * the symmetric done/error → teardown orchestration.
///
/// Transport-specific operations (writing the `@` prompt, forwarding frames
/// preserving frame type, destroying sockets, etc.) are abstract and live
/// on the subclass.
abstract class SecondaryBridgeBase {
  final String proxyUrl;
  final SecondaryAddressFinder _secondaryAddressFinder;
  final SecurityContext clientContext;

  BridgeState _state = BridgeState.opening;
  BridgeState get state => _state;

  late String _atSign;
  String get atSign => _atSign;

  AtSignLogger _logger;
  AtSignLogger get logger => _logger;

  final ByteBuffer _buffer = ByteBuffer(terminatingChar: '\n', capacity: 511);

  SecondaryBridgeBase(
    this.proxyUrl,
    this._secondaryAddressFinder,
    this.clientContext, {
    required AtSignLogger initialLogger,
  }) : _logger = initialLogger;

  /// Subclasses call this from their inbound listener for each frame /
  /// chunk from the client. [bytes] is the byte view used for buffer
  /// accumulation (text WebSocket frames pre-encoded as UTF-8). [original]
  /// is what gets forwarded as-is in [BridgeState.open] so frame type
  /// (text vs binary) survives.
  Future<void> handleClientData(List<int> bytes, dynamic original) async {
    switch (_state) {
      case BridgeState.opening:
        if (_buffer.isOverFlow(bytes)) {
          await writeErrorAndClose('Too much');
          return;
        }
        _buffer.append(bytes);
        if (_buffer.isEnd()) {
          await _processFromCommand();
        }
        break;
      case BridgeState.open:
        forwardToSecondaryOpen(original);
        break;
      case BridgeState.closing:
      case BridgeState.closed:
        break;
    }
  }

  Future<void> _processFromCommand() async {
    var command = utf8.decode(_buffer.getData()).trim();
    if (!command.startsWith('from:')) {
      _logger.info('First command was not "from:" — sending proxyUrl');
      await writeErrorAndClose(proxyUrl);
      return;
    }

    _logger.info('Got "from" command: $command');
    _atSign = command.split(':')[1];
    _logger = AtSignLogger('$runtimeType $_atSign');

    late SecondaryAddress secondaryAddress;
    try {
      _logger.info('Looking up secondary for $_atSign');
      secondaryAddress = await _secondaryAddressFinder.findSecondary(_atSign);
    } catch (e) {
      await writeErrorAndClose(e.toString());
      return;
    }

    try {
      _logger.info('Connecting to $secondaryAddress');
      await connectSecondary(secondaryAddress.host, secondaryAddress.port);
    } catch (e) {
      await writeErrorAndClose(e.toString(),
          closeCode: WebSocketStatus.internalServerError);
      return;
    }

    try {
      _logger
          .info('Forwarding ${_buffer.length()} buffered bytes to secondary');
      forwardBufferedToSecondary(_buffer.getData(), command);
      _logger.info('Bridge is open');
      _state = BridgeState.open;
    } catch (e) {
      await writeErrorAndClose(e.toString(),
          closeCode: WebSocketStatus.internalServerError);
      destroySecondary();
      return;
    }
  }

  Future<void> handleSecondaryData(dynamic data) async {
    switch (_state) {
      case BridgeState.opening:
        _logger
            .severe('handleSecondaryData called while BridgeState is $_state');
        break;
      case BridgeState.open:
        forwardToClientOpen(data);
        break;
      case BridgeState.closing:
      case BridgeState.closed:
        break;
    }
  }

  Future<void> handleClientDone() async {
    _logger.info('handleClientDone()');
    if (_state == BridgeState.open) {
      _destroySecondaryThenClient();
    }
  }

  Future<void> handleSecondaryDone() async {
    _logger.info('handleSecondaryDone()');
    if (_state == BridgeState.open) {
      _destroyClientThenSecondary();
    }
  }

  Future<void> handleClientError(Object? error) async {
    _logger.severe('handleClientError(${error?.toString()})');
    if (_state == BridgeState.open) {
      _destroySecondaryThenClient();
    }
  }

  Future<void> handleSecondaryError(Object? error) async {
    _logger.severe('handleSecondaryError(${error?.toString()})');
    if (_state == BridgeState.open) {
      _destroyClientThenSecondary();
    }
  }

  /// Sends [msg] to the client (transport-specific shape) and then closes
  /// the inbound side. [closeCode] is honoured by transports that carry
  /// close codes (WebSocket); transports that don't (raw socket) ignore it.
  Future<void> writeErrorAndClose(String msg,
      {int closeCode = WebSocketStatus.policyViolation}) async {
    _state = BridgeState.closing;
    _logger.info('writeErrorAndClose : $msg');

    try {
      await writeErrorToClient(msg);
    } catch (_) {
      // ignore — client may already be gone
    }

    try {
      await closeClient(closeCode: closeCode, reason: msg);
    } catch (_) {
      // ignore
    }

    _state = BridgeState.closed;
  }

  void _destroySecondaryThenClient() {
    _logger.info('_destroySecondaryThenClient()');
    _state = BridgeState.closing;
    destroySecondary();
    destroyClient();
    _state = BridgeState.closed;
  }

  void _destroyClientThenSecondary() {
    _logger.info('_destroyClientThenSecondary()');
    _state = BridgeState.closing;
    destroyClient();
    destroySecondary();
    _state = BridgeState.closed;
  }

  // -------------------------------------------------------------------------
  // Transport-specific operations supplied by subclasses.
  // -------------------------------------------------------------------------

  /// Send the initial `@` prompt to the client.
  void sendPrompt();

  /// Send an error message to the client (newline-terminated for raw socket
  /// callers; a single text frame for WebSocket callers).
  Future<void> writeErrorToClient(String msg);

  /// Close the inbound side. [closeCode]/[reason] are advisory — transports
  /// that don't carry them may ignore them.
  Future<void> closeClient({int? closeCode, String? reason});

  /// Open the outbound connection to the upstream atServer at [host]/[port]
  /// and wire its inbound listener to [handleSecondaryData] /
  /// [handleSecondaryDone] / [handleSecondaryError].
  Future<void> connectSecondary(String host, int port);

  /// Forward the buffered initial bytes ([bufferedBytes]) plus the parsed
  /// command ([parsedCommand], without trailing newline) to the upstream.
  /// Subclasses choose whether to send the raw buffer or the rebuilt
  /// `'$parsedCommand\n'` — both are valid for atProtocol.
  void forwardBufferedToSecondary(
      List<int> bufferedBytes, String parsedCommand);

  /// Forward a frame received from the client to the upstream (open state),
  /// preserving frame type for transports that distinguish.
  void forwardToSecondaryOpen(dynamic data);

  /// Forward a frame received from the upstream to the client (open state),
  /// preserving frame type for transports that distinguish.
  void forwardToClientOpen(dynamic data);

  /// Tear down the inbound side immediately (no graceful close).
  void destroyClient();

  /// Tear down the outbound side immediately (no graceful close).
  void destroySecondary();
}
