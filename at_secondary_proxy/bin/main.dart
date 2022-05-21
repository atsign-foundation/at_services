import 'package:at_lookup/at_lookup.dart';
import 'package:at_secondary_proxy/at_secondary_proxy.dart';

Future<void> main(List<String> arguments) async {
  String rootHost = 'vip.ve.atsign.zone';
  if (arguments.isNotEmpty) {
    rootHost = arguments[0];
  }
  var server = SecondaryProxyServer(64000, CacheableSecondaryAddressFinder(rootHost, 64));
  server.startServing();
}
