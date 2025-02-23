import 'package:json_annotation/json_annotation.dart';

part 'figma_files_image_response.g.dart';

@JsonSerializable()
class FigmaFilesImageResponse {
  bool? error;
  int? status;
  ImageMeta? meta;

  FigmaFilesImageResponse({this.error, this.status, this.meta});

  factory FigmaFilesImageResponse.fromJson(json) =>
      _$FigmaFilesImageResponseFromJson(json);
}

@JsonSerializable()
class ImageMeta {
  final Map<String, String> images;

  ImageMeta(this.images);

  factory ImageMeta.fromJson(json) => _$ImageMetaFromJson(json);
  toJson() => _$ImageMetaToJson(this);
}
