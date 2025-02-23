import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class FVBFirebaseConnect {
  final Map<String, dynamic> json;
  String? cloudFireStoreName;

  FVBFirebaseConnect(this.json);

  toJson() => _$FVBFirebaseConnectToJson(this);
  factory FVBFirebaseConnect.fromJson(json) =>
      _$FVBFirebaseConnectFromJson(json);
}
