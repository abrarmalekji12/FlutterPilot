import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../common/common_methods.dart';
import '../common/undo/revert_work.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../constant/string_constant.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../models/project_model.dart';
import 'project_selection_page.dart';

class ProjectSettingsPage extends StatefulWidget {
  final ComponentOperationCubit componentOperationCubit;

  const ProjectSettingsPage({Key? key, required this.componentOperationCubit})
      : super(key: key);

  @override
  State<ProjectSettingsPage> createState() => _ProjectSettingsPageState();
}

class _ProjectSettingsPageState extends State<ProjectSettingsPage> {
  late final ProjectSettingsModel projectSettingsModel;
  late final FlutterProject project;
  CollaboratorModel model = CollaboratorModel(-1, '', ProjectPermission.editor);
  final TextEditingController _collaboratorController = TextEditingController();
  late RevertWork undoWork;
  late String path;

  @override
  void initState() {
    super.initState();
    project = widget.componentOperationCubit.flutterProject!;
    projectSettingsModel =
        widget.componentOperationCubit.flutterProject!.settings;
    path = project.getPath;
    undoWork = RevertWork.init();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      child: GestureDetector(
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
                Expanded(
                  child: ListView(
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
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                    value: true,
                                    groupValue: projectSettingsModel.isPublic,
                                    onChanged: (value) {
                                      undoWork.add(false, () {
                                        projectSettingsModel.isPublic = true;
                                        setState(() {});
                                      }, (p0) {
                                        projectSettingsModel.isPublic = false;
                                        setState(() {});
                                      });
                                    }),
                                Text(
                                  'Public',
                                  style: AppFontStyle.roboto(14,
                                      color: Colors.black),
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
                                      undoWork.add(true, () {
                                        projectSettingsModel.isPublic = false;
                                        setState(() {});
                                      }, (p0) {
                                        projectSettingsModel.isPublic = true;
                                        setState(() {});
                                      });
                                    }),
                                Text(
                                  'Private',
                                  style: AppFontStyle.roboto(14,
                                      color: Colors.black),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paste this link',
                              style: AppFontStyle.roboto(15,
                                  color: AppColors.darkGrey,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: '${appLink}run-$path'));
                                showToast('Copied to clipboard');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 18,
                                      color:
                                          AppColors.darkGrey.withOpacity(0.6),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child: Text(
                                        //html.window.location.href
                                        '${appLink}run-$path',
                                        style: AppFontStyle.roboto(15,
                                            color: AppColors.darkGrey
                                                .withOpacity(0.6),
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Or enter this path on the landing page',
                              style: AppFontStyle.roboto(15,
                                  color: AppColors.darkGrey,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: path));
                                showToast('Copied to clipboard');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 18,
                                      color:
                                          AppColors.darkGrey.withOpacity(0.6),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child: Text(
                                        path,
                                        style: AppFontStyle.roboto(15,
                                            color: AppColors.darkGrey
                                                .withOpacity(0.6),
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Text(
                            'Collaborators',
                            style: AppFontStyle.roboto(14,
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 150,
                                child: TextField(
                                    controller: _collaboratorController,
                                    onChanged: (String data) {
                                      model.email = data;
                                      setState(() {});
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'email',
                                      labelStyle: AppFontStyle.roboto(14,
                                          color: AppColors.darkGrey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    )),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              SizedBox(
                                width: 100,
                                child: PermissionTypeDropDown(
                                  model: model,
                                  onChanged: (value) {
                                    model.permission = value;
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              InkWell(
                                onTap: () {
                                  undoWork.add(model, () {
                                    projectSettingsModel.collaborators
                                        .add(model);
                                    model = CollaboratorModel(
                                        -1, '', ProjectPermission.editor);
                                    setState(() {});
                                  }, (p0) {
                                    projectSettingsModel.collaborators
                                        .remove(p0);
                                    model = p0;
                                    setState(() {});
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: const CircleAvatar(
                                  backgroundColor: AppColors.theme,
                                  radius: 10,
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          ListView.builder(
                              shrinkWrap: true,
                              itemBuilder: (_, index) => CollaboratorTile(
                                  model:
                                      projectSettingsModel.collaborators[index],
                                  onDelete: () {
                                    undoWork.add( projectSettingsModel.collaborators[index], () {
                                      projectSettingsModel.collaborators
                                          .remove( projectSettingsModel.collaborators[index]);
                                      setState(() {});
                                    }, (p0) {
                                      projectSettingsModel.collaborators
                                          .add(p0);
                                      setState(() {});
                                    });
                                  }),
                              itemCount:
                                  projectSettingsModel.collaborators.length ),
                        ],
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          undoWork.revert();
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            'Cancel',
                            style: AppFontStyle.roboto(15,
                                color: Colors.black,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                      if (!undoWork.isEmpty) ...[
                        const SizedBox(
                          width: 20,
                        ),
                        InkWell(
                          onTap: () {
                            undoWork.clear();
                            context
                                .read<ComponentOperationCubit>()
                                .updateProjectSettings();
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.theme,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Apply',
                                  style: AppFontStyle.roboto(15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CollaboratorTile extends StatelessWidget {
  final CollaboratorModel model;
  final VoidCallback onDelete;

  const CollaboratorTile(
      {Key? key, required this.model, required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                model.email,
                style: AppFontStyle.roboto(14, color: AppColors.darkGrey),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                model.permission.toString(),
                style: AppFontStyle.roboto(14, color: AppColors.darkGrey),
              ),
            ],
          ),
          AppIconButton(
              icon: Icons.delete, onPressed: onDelete, color: AppColors.red)
        ],
      ),
    );
  }
}

class PermissionTypeDropDown extends StatelessWidget {
  final CollaboratorModel model;
  final void Function(ProjectPermission) onChanged;

  const PermissionTypeDropDown(
      {Key? key, required this.model, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<ProjectPermission>(
        items: const [
          DropdownMenuItem(
            child: Text('Owner'),
            value: ProjectPermission.owner,
          ),
          DropdownMenuItem(
              child: Text('Editor'), value: ProjectPermission.editor),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged.call(value);
          }
        },
        value: model.permission,
      ),
    );
  }
}

class CollaboratorModel {
  int userId;
  String email;
  ProjectPermission permission;

  CollaboratorModel(this.userId, this.email, this.permission);

  CollaboratorModel.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        email = json['email'],
        permission = ProjectPermission.values[json['permission']];

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'permission': permission.index,
      };
}

enum ProjectPermission {
  owner,
  editor,
}

class ProjectSettingsModel {
  bool isPublic;
  List<CollaboratorModel> collaborators;

  ProjectSettingsModel({required this.isPublic, required this.collaborators});

  factory ProjectSettingsModel.fromJson(Map<String, dynamic> json) {
    return ProjectSettingsModel(
      isPublic: json['is_public'],
      collaborators: json['collaborators']
              ?.map<CollaboratorModel>((e) => CollaboratorModel.fromJson(e))
              ?.toList() ??
          <CollaboratorModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_public': isPublic,
      'collaborators': collaborators.map((e) => e.toJson()).toList(),
    };
  }
}
