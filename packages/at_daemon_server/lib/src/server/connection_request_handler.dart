import 'dart:async';

import 'package:at_daemon_core/at_daemon_core.dart';

abstract class ConnectionRequestHandler {
  FutureOr<ConnectionResult> handleConnectionRequest(SessionSyn syn);
}

abstract class ConnectionResult {
  final bool allow;
  final bool whitelist;
  final bool blacklist;
  final DateTime? until;

  ConnectionResult(this.allow, {this.whitelist = false, this.blacklist = false, this.until});

  factory ConnectionResult.allowOnce() => AllowOnceResult();
  factory ConnectionResult.denyOnce() => DenyOnceResult();
  factory ConnectionResult.allowAlways() => AllowAlwaysResult();
  factory ConnectionResult.denyAlways() => DenyAlwaysResult();
  factory ConnectionResult.allowUntil(DateTime until) => AllowUntilResult(until);
  factory ConnectionResult.denyUntil(DateTime until) => DenyUntilResult(until);
}

class AllowOnceResult extends ConnectionResult {
  AllowOnceResult() : super(true);
}

class DenyOnceResult extends ConnectionResult {
  DenyOnceResult() : super(false);
}

class AllowAlwaysResult extends ConnectionResult {
  AllowAlwaysResult() : super(true, whitelist: true);
}

class DenyAlwaysResult extends ConnectionResult {
  DenyAlwaysResult() : super(false, blacklist: true);
}

class AllowUntilResult extends ConnectionResult {
  AllowUntilResult(DateTime until) : super(true, whitelist: true, until: until);
}

class DenyUntilResult extends ConnectionResult {
  DenyUntilResult(DateTime until) : super(false, blacklist: true, until: until);
}
