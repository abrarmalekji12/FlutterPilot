// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_setting_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectSettingsModel _$ProjectSettingsModelFromJson(
        Map<String, dynamic> json) =>
    ProjectSettingsModel(
      isPublic: json['is_public'] as bool? ?? false,
      versionControl: json['versionControl'] == null
          ? null
          : FVBVersionControl.fromJson(json['versionControl']),
      collaborators: (json['collaborators'] as List<dynamic>?)
          ?.map((e) => FVBCollaborator.fromJson(e as Map<String, dynamic>))
          .toList(),
      target: (json['target'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                $enumDecode(_$TargetPlatformTypeEnumMap, k), e as bool),
          ) ??
          {},
      firebaseConnect: json['firebaseConnect'] == null
          ? null
          : FVBFirebaseConnect.fromJson(json['firebaseConnect']),
    );

Map<String, dynamic> _$ProjectSettingsModelToJson(
        ProjectSettingsModel instance) =>
    <String, dynamic>{
      'is_public': instance.isPublic,
      'collaborators': instance.collaborators?.map((e) => e.toJson()).toList(),
      'target': instance.target
          .map((k, e) => MapEntry(_$TargetPlatformTypeEnumMap[k]!, e)),
      'firebaseConnect': instance.firebaseConnect?.toJson(),
      'versionControl': instance.versionControl?.toJson(),
    };

const _$TargetPlatformTypeEnumMap = {
  TargetPlatformType.mobile: 'mobile',
  TargetPlatformType.tablet: 'tablet',
  TargetPlatformType.desktop: 'desktop',
};
