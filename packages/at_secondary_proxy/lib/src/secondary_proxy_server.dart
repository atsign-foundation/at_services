import 'dart:io';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_utils.dart';

import 'secondary_connection_bridge.dart';

class SecondaryProxyServer {
  static final String _certificateChainLocation = 'certs/fullchain.pem';
  static final String _privateKeyLocation = 'certs/privkey.pem';
  static final String _trustedCertificateLocation = 'certs/cacert.pem';

  static final logger = AtSignLogger('AtSecondaryProxy');

  final int proxyPort;
  final int bindPort;
  final String proxyUrl;
  final SecondaryAddressFinder secondaryAddressFinder;

  late SecureServerSocket _secureServerSocket;

  bool _running = false;

  bool get running => _running;

  SecondaryProxyServer(this.proxyUrl, this.proxyPort, this.bindPort,
      this.secondaryAddressFinder);

  void startServing() {
    SecurityContext serverContext = SecurityContext(withTrustedRoots: true);

    serverContext.useCertificateChain(_certificateChainLocation);
    serverContext.usePrivateKey(_privateKeyLocation);
    serverContext.setTrustedCertificates(_trustedCertificateLocation);

    SecureServerSocket.bind(InternetAddress.anyIPv4, bindPort, serverContext)
        .then((SecureServerSocket secureServerSocket) {
      logger.info('Secure Socket listening on port $bindPort');
      _secureServerSocket = secureServerSocket;
      SecurityContext clientContext = SecurityContext(withTrustedRoots: true);
      _listen(_secureServerSocket, clientContext);
      _running = true;
    });
  }

  void stopServing() {}

  void _listen(
    SecureServerSocket secureServerSocket,
    SecurityContext clientContext,
  ) {
    secureServerSocket.listen(((clientSocket) {
      if (!_running) {
        logger.info('Server cannot accept connections now.');
        return;
      }
      logger.info(
          'New client socket connection with peerCertificate : ${clientSocket.peerCertificate}');

      SecondaryConnectionBridge(
        proxyUrl,
        clientSocket,
        secondaryAddressFinder,
        clientContext,
      );
    }), onError: (error) {
      logger.warning('listen.onError : $error');
    });
  }
}
