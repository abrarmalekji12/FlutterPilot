import 'package:json_annotation/json_annotation.dart';

part 'collaborator.g.dart';

enum ProjectPermission {
  owner,
  editor,
  none,
}

@JsonSerializable()
class FVBCollaborator {
  String? userId;
  String email;
  ProjectPermission permission;

  FVBCollaborator({this.userId, required this.email, required this.permission});

  factory FVBCollaborator.fromJson(Map<String, dynamic> json) =>
      _$FVBCollaboratorFromJson(json);

  Map<String, dynamic> toJson() => _$FVBCollaboratorToJson(this);
}
