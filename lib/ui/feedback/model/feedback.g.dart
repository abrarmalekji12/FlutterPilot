// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FVBFeedback _$FVBFeedbackFromJson(Map<String, dynamic> json) => FVBFeedback(
      id: json['id'] as String,
      type: $enumDecode(_$FeedbackTypeEnumMap, json['type']),
      description: json['description'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String,
      projectId: json['projectId'] as String?,
      isWeb: json['isWeb'] as String,
    );

Map<String, dynamic> _$FVBFeedbackToJson(FVBFeedback instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$FeedbackTypeEnumMap[instance.type]!,
      'description': instance.description,
      'userId': instance.userId,
      'email': instance.email,
      'projectId': instance.projectId,
      'isWeb': instance.isWeb,
    };

const _$FeedbackTypeEnumMap = {
  FeedbackType.bug: 'bug',
  FeedbackType.featureRequest: 'featureRequest',
};
