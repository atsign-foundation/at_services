import 'dart:convert';
import 'dart:io';

import 'package:at_daemon_server/src/util/exceptions.dart';
import 'package:at_daemon_server/src/util/path_provider.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:at_daemon_server/src/config/list_tuple.dart';
import 'package:meta/meta.dart';

part 'config_service.g.dart';

@JsonSerializable()
class ConfigService {
  @protected
  List<ListTuple> blacklist;

  @protected
  List<ListTuple> whitelist;

  @protected
  Map<String, String> onboarded;

  ConfigService({this.blacklist = const [], this.whitelist = const [], this.onboarded = const {}});

  factory ConfigService.fromJson(json) => _$ConfigServiceFromJson(json);
  Map<String, dynamic> toJson() => _$ConfigServiceToJson(this);

  Future<void> load() async {
    ConfigService loaded = ConfigService.fromJson(jsonDecode(await _configFile.readAsString()));
    blacklist = loaded.blacklist;
    whitelist = loaded.whitelist;
    onboarded = loaded.onboarded;
  }

  Future<void> save() async {
    await _configFile.writeAsString(jsonEncode(toJson()));
  }

  File get _configFile => File(getDaemonDirectory()?.concat('config.json') ??
      (throw PathException('Unable to resolve config directory on this platform.')));

  void whitelistAdd(ListTuple t) => _addToList(whitelist, t);
  void blacklistAdd(ListTuple t) => _addToList(blacklist, t);

  void whitelistRemove(ListTuple t) => _removeFromList(whitelist, t);
  void blacklistRemove(ListTuple t) => _removeFromList(blacklist, t);

  void onboardedAdd(String atSign, String keyFile) {
    onboarded[atSign] = keyFile;
  }

  void onboardedRemove(String atSign) {
    onboarded.remove(atSign);
  }
}

void _addToList(List<ListTuple> l, ListTuple t) {
  DateTime? until = _getLatestExpiry(l, t);
  _removeFromList(l, t);
  l.add(t.expires(until));
}

void _removeFromList(List<ListTuple> l, ListTuple t) {
  l.removeWhere((e) => t == e);
}

DateTime? _getLatestExpiry(List<ListTuple> l, ListTuple t) {
  DateTime? d;
  for (var e in l) {
    if (t != e) continue;
    if (e.until == null) return null;
    if (d?.isBefore(e.until!) ?? true) {
      d = e.until;
    }
  }
  return d;
}
