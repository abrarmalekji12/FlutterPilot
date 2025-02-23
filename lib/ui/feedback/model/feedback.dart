import 'package:json_annotation/json_annotation.dart';

import '../feedback_dialog.dart';

part 'feedback.g.dart';

@JsonSerializable()
class FVBFeedback {
  final String id;
  final FeedbackType type;
  final String description;
  final String userId;
  final String email;
  final String? projectId;
  final String isWeb;

  FVBFeedback({
    required this.id,
    required this.type,
    required this.description,
    required this.userId,
    required this.email,
    required this.projectId,
    required this.isWeb,
  });

  toJson() => _$FVBFeedbackToJson(this);

  factory FVBFeedback.fromJson(json) => _$FVBFeedbackFromJson(json);
}
