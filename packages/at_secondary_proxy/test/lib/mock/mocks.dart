import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:at_lookup/at_lookup.dart';
import 'package:at_secondary_proxy/src/secondary_connection_bridge.dart';
import 'package:at_secondary_proxy/src/secondary_websocket_bridge.dart';
import 'package:mocktail/mocktail.dart';

// Lightweight hand-written mocks so we can control listen/done behavior in unit tests.
class SecureSocketMock extends Mock implements SecureSocket {
  final StreamController<Uint8List> _controller = StreamController<Uint8List>();
  StreamController<Uint8List> get controller =>
      _controller; // a way to add data to the stream manually, useful for testing

  // `done` is used for error handling
  // this mirrors SecureSocket.done which is a Future that completes when the socket is closed
  Future<void> _doneFuture = Future<void>.value();

  void setDoneFuture(Future<void> future) {
    _doneFuture = future;
  }

  @override
  Future<void> get done => _doneFuture;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List data)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<dynamic> flush() {
    return _controller.addStream(_controller.stream);
  }

  Future<void> closeController() async {
    await _controller.close();
  }
}

// Simple server stub that lets tests inject fake client sockets via emitClient.
class SecureServerSocketMock extends Mock implements SecureServerSocket {
  StreamController<SecureSocket>? _controller;
  void Function(SecureSocket socket)? _onData;

  StreamController<SecureSocket> get controller =>
      _controller ??= StreamController<SecureSocket>();

  @override
  StreamSubscription<SecureSocket> listen(
    void Function(SecureSocket socket)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _onData = onData;
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void emitClient(SecureSocket socket) {
    _onData?.call(socket);
  }

  Future<void> closeController() async {
    await _controller?.close();
  }

  @override
  Future<SecureServerSocket> close() async {
    await closeController();
    return this;
  }
}

class SecondaryAddressFinderMock extends Mock
    implements SecondaryAddressFinder {}

class SecondaryConnectionBridgeMock extends Mock
    implements SecondaryConnectionBridge {}

class SocketCreatorMock extends Mock implements SocketCreator {}

/// Hand-written WebSocket mock paralleling [SecureSocketMock]. Tests drive
/// inbound frames via [controller.add] and inspect what was sent via [sent]
/// and [closeArgs].
class WebSocketMock extends Mock implements WebSocket {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  StreamController<dynamic> get controller => _controller;

  /// Frames the bridge wrote to this WebSocket via [add], in order. Each
  /// entry is the original Dart object passed (`String` or `List<int>`).
  final List<dynamic> sent = <dynamic>[];

  /// Captures the (code, reason) that the bridge passed to [close].
  ({int? code, String? reason})? closeArgs;

  final Completer<void> _doneCompleter = Completer<void>();

  @override
  Future<void> get done => _doneCompleter.future;

  /// Marks the connection as remotely closed (mirrors the underlying
  /// connection going away). Tests that need to drive an upstream close
  /// downstream can call this and then [closeController].
  void completeDone() {
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();
  }

  @override
  StreamSubscription<dynamic> listen(
    void Function(dynamic data)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  void add(dynamic data) {
    sent.add(data);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    closeArgs = (code: code, reason: reason);
    completeDone();
    await closeController();
  }

  Future<void> closeController() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

class WebSocketCreatorMock extends Mock implements WebSocketCreator {}
