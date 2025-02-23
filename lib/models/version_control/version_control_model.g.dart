// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_control_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FVBVersionControl _$FVBVersionControlFromJson(Map<String, dynamic> json) =>
    FVBVersionControl(
      commits:
          (json['commits'] as List<dynamic>).map(FVBCommit.fromJson).toList(),
    );

Map<String, dynamic> _$FVBVersionControlToJson(FVBVersionControl instance) =>
    <String, dynamic>{
      'commits': instance.commits.map((e) => e.toJson()).toList(),
    };

FVBEntity _$FVBEntityFromJson(Map<String, dynamic> json) => FVBEntity(
      json['id'] as String,
      json['name'] as String,
    );

Map<String, dynamic> _$FVBEntityToJson(FVBEntity instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

FVBCommit _$FVBCommitFromJson(Map<String, dynamic> json) => FVBCommit(
      message: json['message'] as String,
      id: json['id'] as String,
      dateTime: const TimestampConverter().fromJson(json['dateTime']),
      screens:
          (json['screens'] as List<dynamic>).map(FVBEntity.fromJson).toList(),
      customComponents: (json['customComponents'] as List<dynamic>)
          .map(FVBEntity.fromJson)
          .toList(),
    );

Map<String, dynamic> _$FVBCommitToJson(FVBCommit instance) => <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'dateTime': const TimestampConverter().toJson(instance.dateTime),
      'screens': instance.screens.map((e) => e.toJson()).toList(),
      'customComponents':
          instance.customComponents.map((e) => e.toJson()).toList(),
    };
