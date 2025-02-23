import 'package:json_annotation/json_annotation.dart';

part 'figma_nodes_images_response.g.dart';

@JsonSerializable()
class FigmaNodesImagesResponse {
  final String? err;
  final Map<String, String?>? images;

  FigmaNodesImagesResponse({
    this.err,
    this.images,
  });

  factory FigmaNodesImagesResponse.fromJson(json) =>
      _$FigmaNodesImagesResponseFromJson(json);

  toJson() => _$FigmaNodesImagesResponseToJson(this);
}
