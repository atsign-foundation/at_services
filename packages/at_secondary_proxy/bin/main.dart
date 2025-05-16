import 'package:at_lookup/at_lookup.dart';
import 'package:at_secondary_proxy/at_secondary_proxy.dart';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  String proxyUrl = 'vip.ve.atsign.zone:64';
  String rootUrl = 'root.atsign.org:64';
  String rootHost = 'root.atsign.org';
  int proxyListenPort = 64;
  int rootPort = 64;
  if (arguments.length == 2) {
    proxyUrl = arguments[0];
    rootUrl = arguments[1];
  } else {
    error();
  }
  try {
    proxyListenPort = int.parse(proxyUrl.split(':')[1]);
    rootHost = rootUrl.split(':')[0];
    rootPort = int.parse(rootUrl.split(':')[1]);
  } catch (e) {
    error;
  }
  var server = SecondaryProxyServer(proxyUrl, proxyListenPort, CacheableSecondaryAddressFinder(rootHost, rootPort));
  server.startServing();
}

void error() {
  print('Usage: at_proxyserver <this proxies URL> <upstream atDirectory URL>');
  print(' E.g. at_proxyserver vip.ve.atsign.zone:64 root.atsign.org:64');
  exit(1);
}
