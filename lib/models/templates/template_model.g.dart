// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FVBTemplate _$FVBTemplateFromJson(Map<String, dynamic> json) => FVBTemplate(
      userId: json['userId'] as String,
      name: json['name'] as String,
      projectId: json['projectId'] as String,
      imageURLs:
          (json['imageURLs'] as List<dynamic>).map((e) => e as String).toList(),
      description: json['description'] as String,
      device: json['device'] as String,
      id: json['id'] as String,
      public: json['public'] as bool,
      likes: json['likes'] as int,
    );

Map<String, dynamic> _$FVBTemplateToJson(FVBTemplate instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'projectId': instance.projectId,
      'imageURLs': instance.imageURLs,
      'description': instance.description,
      'name': instance.name,
      'device': instance.device,
      'id': instance.id,
      'public': instance.public,
      'likes': instance.likes,
    };
