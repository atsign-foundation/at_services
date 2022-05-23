import 'package:at_lookup/at_lookup.dart';
import 'package:at_secondary_proxy/at_secondary_proxy.dart';

Future<void> main(List<String> arguments) async {
  String rootHost = 'vip.ve.atsign.zone';
  int proxyListenPort = 64000;
  if (arguments.isNotEmpty) {
    rootHost = arguments[0];
  }
  if (arguments.length > 1) {
    proxyListenPort = int.parse(arguments[1]);
  }
  var server = SecondaryProxyServer(proxyListenPort, CacheableSecondaryAddressFinder(rootHost, 64));
  server.startServing();
}
