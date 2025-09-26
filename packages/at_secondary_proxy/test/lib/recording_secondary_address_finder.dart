import 'dart:async';

import 'package:at_lookup/at_lookup.dart';

/// A SecondaryAddressFinder that records lookups and delegates to a handler.
class RecordingSecondaryAddressFinder implements SecondaryAddressFinder {
  RecordingSecondaryAddressFinder(this._handler);

  final Future<SecondaryAddress> Function(String atSign) _handler;
  final List<String> lookups = <String>[];

  @override
  Future<SecondaryAddress> findSecondary(String atSign) {
    lookups.add(atSign);
    return _handler(atSign);
  }
}
