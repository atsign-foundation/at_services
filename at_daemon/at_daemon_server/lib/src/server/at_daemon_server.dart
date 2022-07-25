import 'dart:async';

import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:at_daemon_server/src/server/at_daemon_socket.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AtDaemonServer {
  ConnectionRequestHandler connectionRequestHandler;

  AtDaemonServer(this.connectionRequestHandler);

  void start() {
    shelf_io.serve(webSocketHandler(handleSocket), AtDaemonConstants.address, AtDaemonConstants.port).then((server) {
      print('Serving at ${AtDaemonConstants.socketUrl}');
    });
  }

  void handleSocket(WebSocketChannel socketChannel) {
    AtDaemonSocket(socketChannel: socketChannel, connectionRequestHandler: connectionRequestHandler).start();
  }
}

abstract class ConnectionRequestHandler {
  FutureOr<ConnectionResult> handleConnectionRequest(SessionSyn syn);
}

enum ConnectionResult {
  allowOnce,
  denyOnce,
  whitelistDomain,
  whitelistAtSign,
  whitelistBoth,
  blacklistDomain,
  blacklistAtSign,
  blacklistBoth,
}
