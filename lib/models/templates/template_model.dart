import 'package:json_annotation/json_annotation.dart';

part 'template_model.g.dart';

@JsonSerializable()
class FVBTemplate {
  final String userId;
  final String projectId;
  final List<String> imageURLs;
  final String description;
  final String name;
  final String device;
  final String id;
  final bool public;
  final int likes;

  FVBTemplate({
    required this.userId,
    required this.name,
    required this.projectId,
    required this.imageURLs,
    required this.description,
    required this.device,
    required this.id,
    required this.public,
    required this.likes,
  });

  factory FVBTemplate.fromJson(json) => _$FVBTemplateFromJson(json);

  toJson() => _$FVBTemplateToJson(this);
}
