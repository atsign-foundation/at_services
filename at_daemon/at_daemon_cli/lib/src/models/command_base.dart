import 'package:args/command_runner.dart';
import 'package:at_utils/at_utils.dart';

abstract class CommandBase<T> extends Command<T> {
  @override
  String get usage => super.usage.splitMapJoin(
        '"${runner!.executableName} help',
        onMatch: (_) => '"help',
        onNonMatch: (m) => m,
      );
}

abstract class AtSignCommandBase<T> extends CommandBase<T> {
  String validateAtSignArg() {
    if (argResults!.rest.isEmpty) {
      throw UsageException('Missing atSign in command invocation.', usage);
    }

    return AtUtils.fixAtSign(AtUtils.formatAtSign(argResults!.rest.first)!);
  }
}
