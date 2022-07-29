import 'package:at_daemon_server/src/server/payload_handler.dart';

class PayloadManager {
  static final PayloadManager _singleton = PayloadManager._();
  factory PayloadManager() => _singleton;
  PayloadManager._();

  late List<PayloadHandler> _payloadHandlers;

  PayloadHandler? getPayloadHandler(String jsonEncodedPayload) {
    for (var handler in _payloadHandlers) {
      if (handler.accept(jsonEncodedPayload)) {
        return handler;
      }
    }
    return null;
  }

  void init() {
    _payloadHandlers = [];
    _payloadHandlers.add(GetRequestHandler());
    _payloadHandlers.add(PutRequestHandler());
    _payloadHandlers.add(GetKeysRequestHandler());
  }
}
