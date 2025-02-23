import 'package:json_annotation/json_annotation.dart';

import '../../../models/version_control/version_control_model.dart';
import '../../../screen_model.dart';
import '../../firebase_connect/model.dart';
import 'collaborator.dart';

part 'project_setting_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProjectSettingsModel {
  @JsonKey(name: 'is_public', defaultValue: false)
  bool isPublic;
  List<FVBCollaborator>? collaborators;
  @JsonKey(defaultValue: {})
  Map<TargetPlatformType, bool> target = {};
  FVBFirebaseConnect? firebaseConnect;
  FVBVersionControl? versionControl;

  ProjectSettingsModel({
    this.isPublic = false,
    this.versionControl,
    required this.collaborators,
    required this.target,
    this.firebaseConnect,
  });

  factory ProjectSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectSettingsModelToJson(this);
}
