// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'figma_nodes_images_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FigmaNodesImagesResponse _$FigmaNodesImagesResponseFromJson(
        Map<String, dynamic> json) =>
    FigmaNodesImagesResponse(
      err: json['err'] as String?,
      images: (json['images'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String?),
      ),
    );

Map<String, dynamic> _$FigmaNodesImagesResponseToJson(
        FigmaNodesImagesResponse instance) =>
    <String, dynamic>{
      'err': instance.err,
      'images': instance.images,
    };
