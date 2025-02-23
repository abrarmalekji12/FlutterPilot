import 'package:json_annotation/json_annotation.dart';

import '../../data/remote/firestore/firebase_bridge.dart';

part 'version_control_model.g.dart';

@JsonSerializable()
class FVBVersionControl {
  final List<FVBCommit> commits;

  FVBVersionControl({required this.commits});

  toJson() => _$FVBVersionControlToJson(this);

  factory FVBVersionControl.fromJson(data) => _$FVBVersionControlFromJson(data);
}

@JsonSerializable()
class FVBEntity {
  final String id;
  final String name;

  FVBEntity(this.id, this.name);

  toJson() => _$FVBEntityToJson(this);

  factory FVBEntity.fromJson(json) => _$FVBEntityFromJson(json);
}

@JsonSerializable()
class FVBCommit {
  final String id;
  final String message;
  @TimestampConverter()
  final DateTime? dateTime;

  final List<FVBEntity> screens;
  final List<FVBEntity> customComponents;

  const FVBCommit({
    required this.message,
    required this.id,
    this.dateTime,
    required this.screens,
    required this.customComponents,
  });

  toJson() => _$FVBCommitToJson(this);

  factory FVBCommit.fromJson(data) => _$FVBCommitFromJson(data);
}

// class FVBCommitVersion {
//   final String commitId;
//   final List<CustomComponent> customComponents;
//   final List<Screen> screens;
//
//   FVBCommitVersion({
//     required this.commitId,
//     required this.customComponents,
//     required this.screens,
//   });
//
//   Map<String, dynamic> toJson() => {
//         'commitId': commitId,
//         'customComponents': customComponents.map((e) => e.toJson()).toList(),
//         'screens': screens.map((e) => e.toJson()).toList()
//       };
// }

class TimestampConverter extends JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) => FirebaseDataBridge.timestampToDate(json);

  @override
  dynamic toJson(DateTime? object) => FirebaseDataBridge.timestamp(object);
}
