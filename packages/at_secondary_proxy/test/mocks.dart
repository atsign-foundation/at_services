import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:at_lookup/at_lookup.dart';
import 'package:at_secondary_proxy/src/secondary_connection_bridge.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks(
  [
    SecureSocket,
    SecureServerSocket,
    SecondaryAddressFinder,
    SecondaryConnectionBridge,
  ],
  customMocks: [
    MockSpec<StreamSubscription<Uint8List>>(
        as: #MockUint8ListStreamSubscription),
    MockSpec<StreamSubscription<SecureSocket>>(
        as: #MockSecureSocketStreamSubscription),
  ],
)

void main() {}
