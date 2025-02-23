// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collaborator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FVBCollaborator _$FVBCollaboratorFromJson(Map<String, dynamic> json) =>
    FVBCollaborator(
      userId: json['userId'] as String?,
      email: json['email'] as String,
      permission: $enumDecode(_$ProjectPermissionEnumMap, json['permission']),
    );

Map<String, dynamic> _$FVBCollaboratorToJson(FVBCollaborator instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'permission': _$ProjectPermissionEnumMap[instance.permission]!,
    };

const _$ProjectPermissionEnumMap = {
  ProjectPermission.owner: 'owner',
  ProjectPermission.editor: 'editor',
  ProjectPermission.none: 'none',
};
