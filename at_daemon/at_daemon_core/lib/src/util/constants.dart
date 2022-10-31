import 'dart:io';

class AtDaemonConstants {
  static final InternetAddress address = InternetAddress.loopbackIPv4;
  static final String ip = address.address;
  static const int port = 64640;
  static final String socketUrl = 'ws://$ip:$port';
}
