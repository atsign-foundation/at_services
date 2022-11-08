import 'dart:io';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_utils.dart';

import 'secondary_connection_bridge.dart';

class SecondaryProxyServer {
  static final String _certificateChainLocation = 'certs/fullchain.pem';
  static final String _privateKeyLocation = 'certs/privkey.pem';
  static final String _trustedCertificateLocation = '/etc/cacert/cacert.pem';

  static final logger = AtSignLogger('AtSecondaryProxy');

  final int port;
  final SecondaryAddressFinder secondaryAddressFinder;

  late SecureServerSocket _secureServerSocket;

  bool _running = false;
  bool get running => _running;
  
  SecondaryProxyServer(this.port, this.secondaryAddressFinder);

  void startServing() {
    var secCon = SecurityContext();

    secCon.useCertificateChain(_certificateChainLocation);
    secCon.usePrivateKey(_privateKeyLocation);
    secCon.setTrustedCertificates(_trustedCertificateLocation);

    SecureServerSocket.bind(
        InternetAddress.anyIPv4, port, secCon,
        requestClientCertificate: true)
        .then((SecureServerSocket secureServerSocket) {
      logger.info('Secure Socket listening on port $port');
      _secureServerSocket = secureServerSocket;
      _listen(_secureServerSocket);
      _running = true;
    });

  }
  void stopServing() {

  }

  void _listen(secureServerSocket) {
    secureServerSocket.listen(((clientSocket) {
      if (! _running) {
        logger.info('Server cannot accept connections now.');
        return;
      }
      logger.info('New client socket connection with peerCertificate : ${clientSocket.peerCertificate}');

      SecondaryConnectionBridge(clientSocket, secondaryAddressFinder);
    }), onError: (error) {
      logger.warning('listen.onError : $error');
    });
  }
}
