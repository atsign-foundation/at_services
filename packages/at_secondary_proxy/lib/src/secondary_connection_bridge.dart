import 'dart:convert';
import 'dart:io';
import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_utils.dart';
import 'package:at_lookup/at_lookup.dart';

enum BridgeState {opening, open, closing, closed}

class SecondaryConnectionBridge {
  final SecureSocket _clientSocket;
  late SecureSocket _secondarySocket;

  static final AtSignLogger _initialLogger = AtSignLogger('SecondaryConnectionBridge');

  AtSignLogger _logger = _initialLogger;

  BridgeState _state = BridgeState.opening;

  final SecondaryAddressFinder _secondaryAddressFinder;

  late String _atSign;

  SecondaryConnectionBridge(this._clientSocket, this._secondaryAddressFinder) {
    _clientSocket.listen(_clientOnData, onDone: _clientOnDone, onError: _clientOnError);
    _clientSocket.done.onError((error, stackTrace) => (_clientOnError(error)));

    _logger.info("Sending @ prompt; started listening on new client socket");
    _clientSocket.write("@");
  }

  final _buffer = ByteBuffer(terminatingChar: '\n', capacity: 511);

  Future<void> _clientOnData(data) async {
    switch(_state) {
      case BridgeState.opening:
        // Expecting to receive from:<atSign>\n
        if (_buffer.isOverFlow(data)) {
          _badOpening('Too much');
          return;
        }

        _buffer.append(data);

        if (_buffer.isEnd()) {
          // We've received the '\n'
          var command = utf8.decode(_buffer.getData());
          command = command.trim();
          // If we get to \n and the command doesn't start with "from:" then log something and close this bridge
          if (! command.startsWith("from:")) {
            _logger.info('Unexpected command: $command');
            _badOpening("Bad form");
            return;
          }

          // We've got a 'from:' command - let's get the atSign
          _logger.info('Got from command $command');
          _atSign = command.split(":")[1];
          _logger = AtSignLogger('SecondaryConnectionBridge $_atSign');

          // We've got the @-sign - let's look up the address
          late SecondaryAddress secondaryAddress;
          try {
            _logger.info("Looking up secondary for $_atSign");
            secondaryAddress = await _secondaryAddressFinder.findSecondary(_atSign);
          } catch (e) {
            _badOpening(e.toString());
            return;
          }

          // connect to the secondary
          try {
            _logger.info("Connecting to $secondaryAddress");
            _secondarySocket = await SecureSocket.connect(secondaryAddress.host, secondaryAddress.port);
          } catch (e) {
            _badOpening(e.toString());
            return;
          }
          _logger.info("Setting up secondary socket listen");
          _secondarySocket.listen(_secondaryOnData, onDone: _secondaryOnDone, onError: _secondaryOnError);
          _secondarySocket.done.onError((error, stackTrace) => (_clientOnError(error)));

          try {
            _logger.info("Writing command $command plus \\n");
            _secondarySocket.write('$command\n');
            await _secondarySocket.flush();

            _logger.info("Bridge is open");
            _state = BridgeState.open;
          } catch (e) {
            _badOpening(e.toString());
            _destroySecondarySocket();
            return;
          }
        }
        break;
      case BridgeState.open:
        var decoded = utf8.decode(data);
        _logger.info("From Client to Secondary : decoded to '$decoded'");
        _secondarySocket.add(data);
        await (_secondarySocket.flush());
        break;
      case BridgeState.closing:
        // Nothing to do here
        break;
      case BridgeState.closed:
        // Nothing to do here
        break;
    }
  }

  Future<void> _secondaryOnData(data) async {
    _logger.info('_secondaryOnData(${utf8.decode(data)}');
    switch (_state) {
      case BridgeState.opening:
        // Should not be possible
        _logger.severe("_serverMessageHandler called while BridgeState is $_state");
        break;
      case BridgeState.open:
        var decoded = utf8.decode(data);
        _logger.info("From Secondary to Client : decoded to '$decoded'");
        _clientSocket.add(data);
        await (_clientSocket.flush());
        break;
      case BridgeState.closing:
      // Nothing to do here
        break;
      case BridgeState.closed:
      // Nothing to do here
        break;
    }
  }

  Future<void> _clientOnDone() async {
    _logger.info('_clientOnDone()');
    if (_state == BridgeState.open) { // nothing to do for any other state
      _destroySecondaryThenClient();
    }
  }

  Future<void> _secondaryOnDone() async {
    _logger.info('_secondaryOnDone()');
    if (_state == BridgeState.open) { // nothing to do for any other state
      _destroyClientThenSecondary();
    }
  }

  Future<void> _clientOnError(error) async {
    _logger.severe('_clientOnError(${error.toString()})');
    if (_state == BridgeState.open) { // nothing to do for any other state
      _destroySecondaryThenClient();
    }
  }

  Future<void> _secondaryOnError(error) async {
    _logger.severe('_secondaryOnError(${error.toString()})');
    if (_state == BridgeState.open) { // nothing to do for any other state
      _destroyClientThenSecondary();
    }
  }

  Future<void> _badOpening(String msg) async {
    _state = BridgeState.closing;

    _logger.info("_badOpening : $msg");

    try {
      _clientSocket.write('$msg\n');
      await (_clientSocket.flush());
    }
    // ignore: empty_catches
    catch (ignore) {}

    _destroyClientSocket();

    _state = BridgeState.closed;
  }

  void _destroySecondaryThenClient() {
    _logger.info("_destroySecondaryThenClient()");
    _state = BridgeState.closing;
    _destroySecondarySocket();
    _destroyClientSocket();
    _state = BridgeState.closed;
  }

  void _destroyClientThenSecondary() {
    _logger.info("_destroyClientThenSecondary()");
    _state = BridgeState.closing;
    _destroyClientSocket();
    _destroySecondarySocket();
    _state = BridgeState.closed;
  }

  void _destroyClientSocket() {
    try {
      _clientSocket.destroy();
    }
    // ignore: empty_catches
    catch (ignore) {}
  }

  void _destroySecondarySocket() {
    try {
      _secondarySocket.destroy();
    }
    // ignore: empty_catches
    catch (ignore) {}
  }
}
