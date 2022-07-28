import 'package:at_daemon_core/at_daemon_core.dart';
import 'dart:async';

import 'package:at_daemon_server/at_daemon_server.dart';

class CliConnectionRequestHandler implements ConnectionRequestHandler {
  @override
  FutureOr<ConnectionResult> handleConnectionRequest(SessionSyn syn) {
    // TODO
    return ConnectionResult.allowOnce();
  }
}
