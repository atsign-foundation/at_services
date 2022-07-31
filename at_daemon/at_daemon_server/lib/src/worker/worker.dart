import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:at_client/at_client.dart';
import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

import 'dart:convert';

part 'isolate_channel.dart';
part 'worker_message.dart';
part 'worker_manager.dart';

void workerEntry(SendPort port) {
  AtClientWorker(port).listen();
}

abstract class Worker {
  final IsolateChannel channel;
  Worker(SendPort port) : channel = IsolateChannel(port) {
    port.send(channel.receivePort.sendPort);
  }

  FutureOr<void> listen();
}

class AtClientWorker extends Worker {
  AtClientWorker(super.port);

  @override
  Future<void> listen() async {
    channel.receivePort.listen((event) async {
      atDaemonLogger.info('AtClientWorker received event $event');
      if (event is OnboardAction) {
        try {
          AtSignLogger.root_level = event.logLevel;

          Directory configDir = Directory(
            getDaemonDirectory() ?? (throw PathException('Could not get .atsign directory path')),
          );

          String storage = '${configDir.path}/.${event.atSign}';

          AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
            ..isLocalStoreRequired = true
            ..hiveStoragePath = '$storage/hive'
            ..downloadPath = '$storage/files'
            ..commitLogPath = '$storage/commitLog'
            ..rootDomain = 'root.atsign.org'
            ..atKeysFilePath = event.keyFilePath;

          AtOnboardingService onboardingService = AtOnboardingServiceImpl(event.atSign, atOnboardingPreference);
          bool result = await onboardingService.authenticate();
          channel.sendPort!.send(Onboarded(result));
        } on OnboardException catch (_) {
          Isolate.exit(channel.sendPort, Onboarded(false));
        }
      } else if (event is EchoAction) {
        channel.sendPort!.send(event);
      } else if (event is CreateSessionAction) {
        var sessionWorker = SessionWorker(event.sendPort, event.atSign);
        await sessionWorker.init();
        sessionWorker.listen();
        channel.sendPort!.send(sessionWorker.channel.receivePort.sendPort);
      } else if (event is KillAction) {
        Isolate.exit(channel.sendPort, Killed());
      }
    });
  }
}

class SessionWorker extends Worker {
  final String atSign;
  late AtClient atClient;

  SessionWorker(super.port, this.atSign);

  @override
  Future<void> listen() async {
    await init();
    channel.receivePort.listen((event) async {
      atDaemonLogger.info('SessionWorker received event $event');

      if (event is KillAction) {
        channel.receivePort.close();
        channel.sendPort!.send(Killed());
      } else if (event is GetVerb) {
        GetResult getResult;
        try {
          AtValue value = await atClient.get(event.key, isDedicated: event.isDedicated);
          getResult = GetResult(value: value.value);
        } on Exception catch (e) {
          getResult = GetResult(exception: e);
        }
        channel.sendPort!.send(jsonEncode(getResult));
      } else if (event is PutVerb) {
        PutResult putResult;
        try {
          bool result = await atClient.put(event.key, event.value, isDedicated: event.isDedicated);
          putResult = PutResult(result:result);
        } on Exception catch (e) {
          putResult = PutResult(exception: e);
        }
        channel.sendPort!.send(jsonEncode(putResult));
      } else if (event is GetKeysVerb) {
        GetKeysResult getKeysResult;
        try {
          List<String> keys = await atClient.getKeys(
            regex: event.regex,
            sharedBy: event.sharedBy,
            sharedWith: event.sharedWith,
            showHiddenKeys: event.showHiddenKeys,
            //isDedicated: event.isDedicated,
          );
          getKeysResult = GetKeysResult(keys: keys);
        } on Exception catch (e) {
          getKeysResult = GetKeysResult(exception: e);
        }
        channel.sendPort!.send(jsonEncode(getKeysResult));
      }
    });
  }

  bool _initialized = false;
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    Directory configDir = Directory(
      getDaemonDirectory() ?? (throw PathException('Could not get .atsign directory path')),
    );

    String storage = '${configDir.path}/.$atSign';
    await OnboardingManager().configService.load();
    var keysFilePath = OnboardingManager().configService.getOnboarded(atSign);
    atDaemonLogger.info('SessionWorker._init() : keys file is at $keysFilePath');
    AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
      ..isLocalStoreRequired = true
      ..hiveStoragePath = '$storage/hive'
      ..downloadPath = '$storage/files'
      ..commitLogPath = '$storage/commitLog'
      ..rootDomain = 'root.atsign.org'
      ..atKeysFilePath = keysFilePath;

    AtOnboardingService onboardingService = AtOnboardingServiceImpl(atSign, atOnboardingPreference);
    bool authenticated = await onboardingService.authenticate();
    if (! authenticated) {
      atDaemonLogger.severe('SessionWorker($atSign) failed to authenticate');
    }

    atClient = (await onboardingService.getAtClient())!;

    _initialized = true;
  }

}
