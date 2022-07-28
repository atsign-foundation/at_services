import 'package:args/command_runner.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_daemon_cli/src/services/cli_onboarding_handler.dart';
import 'package:at_daemon_server/at_daemon_server.dart';
import 'package:at_utils/at_utils.dart';

const _name = 'onboard';
const _description = 'Onboard an atSign to the system';

class OnboardCommand extends Command<bool> {
  @override
  String get name => _name;

  @override
  String get description => _description;

  OnboardCommand() {
    //TODO add commandline options to skip interactive
  }

  @override
  Future<bool> run() async {
    String? atSign;
    try {
      atSign = validateAtSignArg();
      WorkerIsolateChannel channel = await AtSignWorkerManager().getChannel(atSign);
      channel.sendPort!.send(OnboardAction(atSign));
      Onboarded result = await channel.streamQueue.next;
      return result.isOnboarded;
    } on InvalidAtSignException catch (e) {
      throw FormatException(e.message);
    }
  }

  String validateAtSignArg() {
    if (argResults!.rest.isEmpty) {
      throw UsageException('No atSign specified for onboarding.', usage);
    }

    if (argResults!.rest.length > 1) {
      throw UsageException('Too many arguments specified.', usage);
    }

    return AtUtils.fixAtSign(AtUtils.formatAtSign(argResults!.rest.single)!);
  }
}
