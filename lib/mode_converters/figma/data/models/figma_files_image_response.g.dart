// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'figma_files_image_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FigmaFilesImageResponse _$FigmaFilesImageResponseFromJson(
        Map<String, dynamic> json) =>
    FigmaFilesImageResponse(
      error: json['error'] as bool?,
      status: json['status'] as int?,
      meta: json['meta'] == null ? null : ImageMeta.fromJson(json['meta']),
    );

Map<String, dynamic> _$FigmaFilesImageResponseToJson(
        FigmaFilesImageResponse instance) =>
    <String, dynamic>{
      'error': instance.error,
      'status': instance.status,
      'meta': instance.meta?.toJson(),
    };

ImageMeta _$ImageMetaFromJson(Map<String, dynamic> json) => ImageMeta(
      Map<String, String>.from(json['images'] as Map),
    );

Map<String, dynamic> _$ImageMetaToJson(ImageMeta instance) => <String, dynamic>{
      'images': instance.images,
    };
