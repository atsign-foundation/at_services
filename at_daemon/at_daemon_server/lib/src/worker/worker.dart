import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:at_client/at_client.dart';
import 'package:at_daemon_core/at_daemon_core.dart';
import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

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
        SessionWorker(event.sendPort);
      } else if (event is KillAction) {
        Isolate.exit(channel.sendPort, Killed());
      }
    });
  }
}

class SessionWorker extends Worker {
  SessionWorker(super.port);

  AtClient get atClient => AtClientManager.getInstance().atClient;

  @override
  Future<void> listen() async {
    channel.receivePort.listen((event) async {
      if (event is KillAction) {
        channel.receivePort.close();
        channel.sendPort!.send(Killed());
      } else if (event is GetVerb) {
        AtValue value = await atClient.get(event.key, isDedicated: event.isDedicated);
        channel.sendPort!.send(GetResult(value.value));
      } else if (event is PutVerb) {
        bool result = await atClient.put(event.key, event.value, isDedicated: event.isDedicated);
        channel.sendPort!.send(PutResult(result));
      } else if (event is GetKeysVerb) {
        List<String> keys = await atClient.getKeys(
          regex: event.regex,
          sharedBy: event.sharedBy,
          sharedWith: event.sharedWith,
          showHiddenKeys: event.showHiddenKeys,
          //isDedicated: event.isDedicated,
        );
        channel.sendPort!.send(GetKeysResult(keys));
      }
    });
  }
}
