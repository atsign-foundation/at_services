import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:at_lookup/at_lookup.dart';
import 'package:at_secondary_proxy/src/secondary_connection_bridge.dart';
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
  Future<dynamic> flush(){
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