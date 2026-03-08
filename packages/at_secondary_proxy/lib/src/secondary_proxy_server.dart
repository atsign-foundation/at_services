import 'dart:io';
import 'package:at_commons/at_commons.dart' hide StringBuffer;
import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_utils.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

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
  final ioClient = IOClient(HttpClient(
      context: SecurityContext(withTrustedRoots: true)
        ..setAlpnProtocols(['http/1.1'], false)));

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
    serverContext.setAlpnProtocols(['atProtocol/1.0', 'http/1.1'], true);
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
    // ALPN support.
    // Make a PseudoServerSocket to which we will pass sockets which
    // have a selectedProtocol which is neither null nor 'atProtocol/1.0'.
    // See later in this method for where we pass sockets received on the real
    // serverSocket to the pseudoServerSocket.
    final pseudoServerSocket = PseudoServerSocket(secureServerSocket);
    // Second, make an HttpServer which is handling sockets which are passed
    // to the pseudoServerSocket
    HttpServer httpServer = HttpServer.listenOn(pseudoServerSocket);
    httpServer.listen((HttpRequest req) {
      if (req.uri.path == '/ws') {
        //   // Upgrade to a WebSocket connection
        //   logger.info('Upgraded to WebSocket connection');
        //   WebSocketTransformer.upgrade(req)
        //       .then((WebSocket ws) => webSocketListener(ws));
      } else {
        handleHttpRequest(req);
      }
    });

    // Listen for new socket connections
    // If protocol is atProtocol/1.0 or is null, treat as standard atProtocol
    // If protocol is http, handle as a http request
    logger.finer('serverSocket _listen : ${secureServerSocket.runtimeType}');
    secureServerSocket.listen(((clientSocket) {
      if (!_running) {
        logger.info('Server cannot accept connections now.');
        return;
      }
      logger.info(
          'New client socket: selectedProtocol ${clientSocket.selectedProtocol}');
      if (clientSocket.selectedProtocol == 'atProtocol/1.0' ||
          clientSocket.selectedProtocol == null) {
        logger.info(
            'New client socket connection with peerCertificate : ${clientSocket.peerCertificate}');

        SecondaryConnectionBridge(
          proxyUrl,
          clientSocket,
          secondaryAddressFinder,
          clientContext,
        );
      } else {
        // ALPN support
        // selectedProtocol is neither null nor 'atProtocol/1.0'
        // TODO check specifically for http/1.1
        logger.info('Transferring socket to HttpServer for handling');
        pseudoServerSocket.add(clientSocket);
      }
    }), onError: (error) {
      // We've got no action to take here, let's just log a warning
      logger.warning("ServerSocket.listen called onError with '$error'");
    });
  }

  Future<void> handleHttpRequest(
    HttpRequest request,
  ) async {
    try {
      if (request.uri.toString().length > 1000) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }
      if (request.method != 'GET') {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write('Unauthorized');
      }

      String decodedRequestPath = Uri.decodeComponent(request.uri.path);
      logger.info('GET $decodedRequestPath');

      if (decodedRequestPath.startsWith('/')) {
        decodedRequestPath = decodedRequestPath.substring(1);
      }
      if (decodedRequestPath.startsWith('@')) {
        decodedRequestPath = decodedRequestPath.substring(1);
      }
      List<String> pathParts = decodedRequestPath.split('/');
      String atSignToLookUp;
      String encodedRedirectPath = '';
      atSignToLookUp = pathParts.removeAt(0);
      if (pathParts.isNotEmpty) {
        encodedRedirectPath =
            pathParts.map((s) => Uri.encodeComponent(s)).join('/');
      }

      String address;
      try {
        logger.info('Looking up $atSignToLookUp');
        address = (await secondaryAddressFinder.findSecondary(atSignToLookUp))
            .toString();
      } on SecondaryNotFoundException catch (e) {
        logger.info('Failed lookup $atSignToLookUp: $e');
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('${HttpStatus.notFound} not found');
        return;
      } catch (e) {
        logger.info('Failed lookup $atSignToLookUp: $e');
        request.response.statusCode = HttpStatus.badGateway;
        request.response.write('${HttpStatus.badGateway}'
            ' Failed to lookup $atSignToLookUp: $e');
        return;
      }

      if (encodedRedirectPath.isEmpty) {
        // getting just an atServer address - we're done
        request.response.statusCode = HttpStatus.ok;
        request.response.write(address);
        return;
      }
      // getting some data from a specific atServer
      final atServerRequestPath = StringBuffer('https://$address');
      atServerRequestPath.write('/$encodedRedirectPath');
      if (request.uri.query.isNotEmpty) {
        atServerRequestPath.write('?${request.uri.query}');
      }

      // send the request
      http.Response atServerResponse = await ioClient.get(
        Uri.parse(atServerRequestPath.toString()),
      );

      // send statusCode, headers & body as this server's response
      request.response.statusCode = atServerResponse.statusCode;
      atServerResponse.headers
          .forEach((k, v) => request.response.headers.add(k, v));
      request.response.add(atServerResponse.bodyBytes);
    } catch (e) {
      logger.info('Error while handling http req'
          ' ${Uri.decodeFull(request.requestedUri.toString())}'
          ' : $e');
    } finally {
      await request.response.close();
    }
  }
}
