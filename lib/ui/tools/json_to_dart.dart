import 'dart:convert';

import 'package:code_text_field/code_text_field.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/code_processor.dart';

import '../../common/app_button.dart';
import '../../common/converter/string_operation.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../injector.dart';
import '../../user_session.dart';
import '../../widgets/button/app_close_button.dart';
import '../fvb_code_editor.dart';
import '../home/landing_page.dart';
import '../navigation/animated_dialog.dart';
import '../project/project_selection_page.dart';

class JsonToDartConversionWidget extends StatefulWidget {
  const JsonToDartConversionWidget({Key? key}) : super(key: key);

  @override
  State<JsonToDartConversionWidget> createState() =>
      _JsonToDartConversionWidgetState();
}

class _JsonToDartConversionWidgetState
    extends State<JsonToDartConversionWidget> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  String? output;
  final formatter = DartFormatter();
  late CodeController upCodeController;

  @override
  void initState() {
    final theme = editorThemes[sl<UserSession>().settingModel!.iDETheme]!.map(
      (key, value) => MapEntry(
        key,
        value.copyWith(fontSize: 14),
      ),
    );
    upCodeController = CodeController(patternMap: theme);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Json To Dart with Serialization',
                style: AppFontStyle.headerStyle(),
              ),
              AppCloseButton(
                onTap:()=> AnimatedDialog.hide(context),

              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          SelectableText(
            'Dependencies: \njson_serializable: ^6.5.4\njson_annotation: ^4.7.0\nbuild_runner: ^2.3.3',
            style: AppFontStyle.lato(14,
                color: ColorAssets.black, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            height: 20,
          ),
          CommonTextField(
            border: true,
            maxLines: 5,
            hintText: 'Json',
            controller: _controller,
          ),
          const SizedBox(
            height: 20,
          ),
          CommonTextField(
            border: true,
            hintText: 'Class Name',
            controller: _nameController,
          ),
          const SizedBox(
            height: 20,
          ),
          CommonTextField(
            border: true,
            hintText: 'File Name',
            controller: _fileNameController,
          ),
          const SizedBox(
            height: 20,
          ),
          AppButton(
            height: 40,
            title: 'Convert',
            onPressed: () {
              final json = jsonDecode(_controller.text);
              output = formatter.format(
                  convertJsonToDartFinalCode(json, _nameController.text));
              setState(() {});
            },
          ),
          if (output != null) ...[
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: CodeField(
                      wrap: true,
                      controller: upCodeController..text = output!,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Opacity(
                      opacity: 0.7,
                      child: CopyIconButton(
                        text: output!,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }

  String convertJsonToDartFinalCode(Map<String, dynamic> map, String name) {
    return 'import \'package:json_annotation/json_annotation.dart\'; part \'${_fileNameController.text}.g.dart\';${convertJsonToDartCode(map, name)}';
  }

  String convertJsonToDartCode(Map<String, dynamic> map, String name) {
    final List<Var> list = [];
    String otherClasses = '';
    for (final entry in map.entries) {
      final type = DataType.fromValue(entry.value);
      String varName;
      if (type.isMap) {
        varName = StringOperation.toCamelCase(entry.key);
        if (varName == entry.key) {
          varName = '${entry.key}Model';
        }
        otherClasses += '\n' + (convertJsonToDartCode(entry.value, varName));
      } else if (type.isList && type.generics!.first.isMap) {
        String argName = StringOperation.toCamelCase(entry.key);
        if (argName == entry.key) {
          argName = '${entry.key}Model';
        }
        varName = 'List<$argName>';
        otherClasses += '\n' +
            (convertJsonToDartCode((entry.value as List).first, argName));
      } else {
        varName = DataType.dataTypeToCode(type);
      }
      list.add(Var(entry.key, varName, true));
    }
    return '@JsonSerializable(explicitToJson: true) class $name { ${list.map((e) => '${e.type}? ${e.name};').join('\n')} $name(${list.isNotEmpty ? '{' : ''}${list.map((e) => 'this.${e.name}').join(',')}${list.isNotEmpty ? '}' : ''});  factory $name.fromJson(json)=>_\$${name}FromJson(json); Map<String,dynamic> toJson()=>_\$${name}ToJson(this);} $otherClasses';
  }
}

class Var {
  final String name;
  final String type;
  final bool nullable;

  Var(this.name, this.type, this.nullable);
}
