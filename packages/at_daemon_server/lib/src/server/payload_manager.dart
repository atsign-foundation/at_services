import 'package:at_daemon_server/src/server/payload_handler.dart';
import 'package:at_daemon_core/at_daemon_core.dart';

class PayloadManager {
  static final PayloadManager _singleton = PayloadManager._();
  factory PayloadManager() => _singleton;
  PayloadManager._();

  late List<PayloadHandler> _payloadHandlers;

  PayloadHandler? getPayloadHandler(String jsonEncodedPayload) {
    for (var handler in _payloadHandlers) {
      try {
        if (handler.accept(jsonEncodedPayload)) {
          return handler;
        }
      } catch (e) {
        atDaemonLogger.warning('GetRequestHandler failed to jsonDecode with exception $e');
      }
    }
    atDaemonLogger.warning('No payloadHandler found which will accept $jsonEncodedPayload');
    return null;
  }

  void init() {
    _payloadHandlers = [];
    _payloadHandlers.add(GetRequestHandler());
    _payloadHandlers.add(PutRequestHandler());
    _payloadHandlers.add(GetKeysRequestHandler());
    _payloadHandlers.add(NotifyUpdateRequestHandler());
    _payloadHandlers.add(NotifyDeleteRequestHandler());
  }
}
