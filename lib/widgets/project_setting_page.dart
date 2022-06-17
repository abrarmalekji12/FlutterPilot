import 'dart:math';
import 'dart:html' as html;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../common/common_methods.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';

class ProjectSettingsPage extends StatefulWidget {
  final ComponentOperationCubit componentOperationCubit;

  const ProjectSettingsPage({Key? key, required this.componentOperationCubit})
      : super(key: key);

  @override
  State<ProjectSettingsPage> createState() => _ProjectSettingsPageState();
}

class _ProjectSettingsPageState extends State<ProjectSettingsPage> {
  late final ProjectSettingsModel projectSettingsModel;

  @override
  initState() {
    super.initState();
    projectSettingsModel =
        widget.componentOperationCubit.flutterProject!.projectSettingsModel;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                'Settings',
                style: AppFontStyle.roboto(18,
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  // public or private radio button
                  Expanded(
                    child: Text(
                      'Visibility',
                      style: AppFontStyle.roboto(14,
                          color: Colors.black, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Radio(
                            value: true,
                            groupValue: projectSettingsModel.isPublic,
                            onChanged: (value) {
                              projectSettingsModel.isPublic = true;
                              if (projectSettingsModel.linkIfPublic == null) {
                                final project = widget
                                    .componentOperationCubit.flutterProject!;
                                final key =
                                    encrypt.Key.fromUtf8('fvb_project_link');
                                final iv = encrypt.IV.fromLength(10);
                                final encrypt.Encrypter encryptor =
                                    encrypt.Encrypter(encrypt.AES(key, ),);
                                projectSettingsModel.linkIfPublic = encryptor
                                    .encrypt(
                                        '${project.userId}_${project.name}',iv:iv)
                                    .base16;
                              }
                              setState(() {});
                            }),
                        Text(
                          'Public',
                          style: AppFontStyle.roboto(14, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Radio(
                            value: false,
                            groupValue: projectSettingsModel.isPublic,
                            onChanged: (value) {
                              projectSettingsModel.isPublic = false;
                              setState(() {});
                            }),
                        Text(
                          'Private',
                          style: AppFontStyle.roboto(14, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              if (projectSettingsModel.isPublic)
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            '${html.window.location.href}test-${projectSettingsModel.linkIfPublic!}'));
                    showToast('Copied to clipboard');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.copy),
                        const SizedBox(
                          width: 20,
                        ),
                        Text(
                          '${html.window.location.href}test-${projectSettingsModel.linkIfPublic!}',
                          style: AppFontStyle.roboto(15,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectSettingsModel {
  bool isPublic;
  String? linkIfPublic;

  ProjectSettingsModel({required this.isPublic, required this.linkIfPublic});

  factory ProjectSettingsModel.fromJson(Map<String, dynamic> json) {
    return ProjectSettingsModel(
      isPublic: json['is_public'],
      linkIfPublic: json['link_if_public'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_public': isPublic,
      'link_if_public': linkIfPublic,
    };
  }
}
