import 'package:json_annotation/json_annotation.dart';

part 'list_tuple.g.dart';

@JsonSerializable()
class ListTuple {
  final String atSign;
  final String clientId;
  final DateTime? until;

  const ListTuple(this.atSign, this.clientId, {this.until});

  factory ListTuple.fromJson(Map<String, dynamic> json) => _$ListTupleFromJson(json);
  Map<String, dynamic> toJson() => _$ListTupleToJson(this);

  ListTuple expires(DateTime? until) => ListTuple(atSign, clientId, until: until);

  @override
  // Matches any ListTuple with a matching atSign & clientId
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (other is! ListTuple || atSign != other.atSign || clientId != other.clientId) {
      return false;
    }
    return true;
  }

  bool get isExpired => until?.isBefore(DateTime.now()) ?? false;
}
