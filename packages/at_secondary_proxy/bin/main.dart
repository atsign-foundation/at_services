import 'dart:io';
import 'package:args/args.dart';
import 'package:at_secondary_proxy/at_secondary_proxy.dart';
import 'package:at_secondary_proxy/src/ttl_secondary_address_finder.dart';
import 'package:at_utils/at_logger.dart';

Future<void> main(List<String> arguments) async {
  AtSignLogger.defaultLoggingHandler = AtSignLogger.stdErrLoggingHandler;

  final bool isPositional = arguments.isNotEmpty && !arguments[0].startsWith('-');

  final SecondaryProxyServer server = isPositional
      ? _serverFromPositionalArgs(arguments) // legacy
      : _serverFromFlagArgs(arguments); // new flags (recommended usage)

  server.startServing();
}

SecondaryProxyServer _serverFromPositionalArgs(List<String> arguments) {
  if (arguments.length < 2 || arguments.length > 3) {
    _printUsage(null);
    exit(1);
  }

  final String proxyUrl = arguments[0];
  final String rootUrl = arguments[1];

  int proxyBindPort = 443;
  if (arguments.length == 3) {
    proxyBindPort = int.tryParse(arguments[2]) ?? -1;
    if (proxyBindPort == -1) {
      stderr.writeln('Error: "${arguments[2]}" is not a valid port number');
      exit(1);
    }
  }

  final List<String> proxyParts = proxyUrl.split(':');
  final List<String> rootParts = rootUrl.split(':');

  if (proxyParts.length != 2 || int.tryParse(proxyParts[1]) == null) {
    stderr.writeln('Error: invalid proxy-url "$proxyUrl" — expected host:port');
    exit(1);
  }
  if (rootParts.length != 2 || int.tryParse(rootParts[1]) == null) {
    stderr.writeln('Error: invalid root-url "$rootUrl" — expected host:port');
    exit(1);
  }

  return SecondaryProxyServer(
    proxyUrl,
    int.parse(proxyParts[1]),
    proxyBindPort,
    TtlSecondaryAddressFinder(rootParts[0], int.parse(rootParts[1])),
  );
}

SecondaryProxyServer _serverFromFlagArgs(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('proxy-url',
      mandatory: true,
      help: 'Public-facing proxy address, e.g. vip.ve.atsign.zone:443')
    ..addOption('root-url',
      mandatory: true,
      help: 'upstream atDirectory address, e.g. vip.ve.atsign.zone:64')
    ..addOption('bind-port',
      mandatory: true,
      help: 'Local port to bind (defaults to the port in --proxy-url)')
    ..addOption('cert-dir',
      mandatory: false,
      help: 'Directory containing fullchain.pem, privkey.pem, cacert.pem',
      defaultsTo: 'certs')
    ..addFlag('help', 
      abbr: 'h',
      negatable: false, 
      help: 'Show this help');

  late final ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    stderr.writeln('Error: $e');
    _printUsage(parser);
    exit(1);
  }

  if (results['help'] as bool) {
    _printUsage(parser);
    exit(0);
  }

  final String proxyUrl = results['proxy-url'] as String? ?? '';
  final String rootUrl = results['root-url'] as String? ?? '';
  final String certDir = results['cert-dir'] as String;

  if (proxyUrl.isEmpty || rootUrl.isEmpty) {
    stderr.writeln('Error: --proxy-url and --root-url are required');
    _printUsage(parser);
    exit(1);
  }

  int proxyBindPort;
  final String? bindPortStr = results['bind-port'] as String?;
  if (bindPortStr != null) {
    proxyBindPort = int.tryParse(bindPortStr) ?? -1;
    if (proxyBindPort == -1) {
      stderr.writeln('Error: "$bindPortStr" is not a valid port number');
      exit(1);
    }
  } else {
    proxyBindPort = int.tryParse(proxyUrl.split(':').last) ?? 443;
  }

  final List<String> proxyParts = proxyUrl.split(':');
  final List<String> rootParts = rootUrl.split(':');

  if (proxyParts.length != 2 || int.tryParse(proxyParts[1]) == null) {
    stderr.writeln('Error: invalid proxy-url "$proxyUrl" — expected host:port');
    exit(1);
  }
  if (rootParts.length != 2 || int.tryParse(rootParts[1]) == null) {
    stderr.writeln('Error: invalid root-url "$rootUrl" — expected host:port');
    exit(1);
  }

  return SecondaryProxyServer(
    proxyUrl,
    int.parse(proxyParts[1]),
    proxyBindPort,
    TtlSecondaryAddressFinder(rootParts[0], int.parse(rootParts[1])),
    certDir: certDir,
  );
}

void _printUsage(ArgParser? parser) {
  stderr.writeln('Usage:      at_proxyserver --proxy-url <host:port> --root-url <host:port> [--bind-port <port>] [--cert-dir <dir>]');
  stderr.writeln('Usage (legacy): at_proxyserver <proxy-url> <root-url> [bind-port]');
  stderr.writeln('');
  stderr.writeln('Examples:');
  stderr.writeln('  at_proxyserver --proxy-url vip.ve.atsign.zone:443 --root-url vip.ve.atsign.zone:64 --bind-port 1443 --cert-dir /atsign/proxy/certs');
  stderr.writeln('  at_proxyserver vip.ve.atsign.zone:443 vip.ve.atsign.zone:64 1443');
  if (parser != null) {
    stderr.writeln('');
    stderr.writeln(parser.usage);
  }
}
