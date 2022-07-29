import 'dart:io';

import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connection_request_handler.dart';
import 'at_daemon_socket.dart';

export 'connection_request_handler.dart';
export 'at_daemon_socket.dart';

class AtDaemonServer {
  ConnectionRequestHandler connectionRequestHandler;
  AtDaemonServer({required this.connectionRequestHandler});

  Future<void> start() async {
    await shelf_io.serve(webSocketHandler(_handleSocket), AtDaemonConstants.address, AtDaemonConstants.port);
    stdout.writeln('Serving at ${AtDaemonConstants.socketUrl}');
  }

  void _handleSocket(WebSocketChannel socketChannel) {
    AtDaemonSocket(socketChannel: socketChannel, connectionRequestHandler: connectionRequestHandler).start();
  }
}
