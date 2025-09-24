import 'dart:io';
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
)

void main() {}
