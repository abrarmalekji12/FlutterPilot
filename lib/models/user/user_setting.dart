import 'package:json_annotation/json_annotation.dart';

import '../../bloc/theme/theme_bloc.dart';
import '../../injector.dart';
import '../../ui/fvb_code_editor.dart';
import '../project_model.dart';

part 'user_setting.g.dart';

class UserSettingModel {
  List<FVBProject> projects = [];
  String iDETheme = 'idea';
  String? figmaCode;
  String? figmaAccessToken;
  String? openAISecretToken;
  String? geminiSecretToken;
  ThemeType generalTheme = ThemeType.light;
  FVBOtherSettings? otherSettings;

  UserSettingModel();

  Map<String, dynamic> toJson() {
    return {
      'projects': projects.map((e) => e.name).toList(growable: false),
      'theme': iDETheme,
      'figmaCode': figmaCode,
      'figmaAccessToken': figmaAccessToken,
      'openAISecretToken': openAISecretToken,
      'geminiSecretToken': geminiSecretToken,
      'generalTheme': generalTheme.index,
      'otherSettings': otherSettings?.toJson()
    };
  }

  factory UserSettingModel.fromJson(Map<String, dynamic> json) {
    final model = UserSettingModel()
      ..iDETheme = json['theme'] ?? defaultThemeKey
      ..figmaCode = json['figmaCode']
      ..openAISecretToken=json['openAISecretToken']
      ..geminiSecretToken=json['geminiSecretToken']
      ..figmaAccessToken = json['figmaAccessToken']
      ..generalTheme = ThemeType.values[json['generalTheme'] ?? 0]
      ..otherSettings = json['otherSettings'] != null
          ? FVBOtherSettings.fromJson(json['otherSettings'])
          : FVBOtherSettings();
    ;
    theme.add(UpdateThemeEvent(model.generalTheme));
    return model;
  }
}

@JsonSerializable()
class FVBOtherSettings {
  String? flutterPath;
  String? projectPath;

  FVBOtherSettings({
    this.flutterPath,
    this.projectPath,
  });

  toJson() => _$FVBOtherSettingsToJson(this);

  factory FVBOtherSettings.fromJson(json) => _$FVBOtherSettingsFromJson(json);
}
