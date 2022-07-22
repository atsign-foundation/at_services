import 'dart:io';

import 'package:args/command_runner.dart';

const _name = 'exit';
const _description = 'Exit the daemon';
const _aliases = ['q', 'quit'];

class ExitCommand extends Command<bool> {
  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  List<String> get aliases => _aliases;

  @override
  Future<bool> run() async {
    exit(0);
  }
}