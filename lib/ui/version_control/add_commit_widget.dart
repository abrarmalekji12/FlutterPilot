import 'package:flutter/material.dart';

import '../../common/app_button.dart';
import '../../common/extension_util.dart';
import '../../common/responsive/responsive_dimens.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../injector.dart';
import '../../models/version_control/version_control_model.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/loading/button_loading.dart';
import '../../widgets/textfield/app_textfield.dart';
import '../navigation/animated_dialog.dart';

class AddCommitWidget extends StatefulWidget {
  const AddCommitWidget({super.key});

  @override
  State<AddCommitWidget> createState() => _AddCommitWidgetState();
}

class _AddCommitWidgetState extends State<AddCommitWidget> {
  final _message = TextEditingController();
  final Set<String> screens = {};
  final Set<String> components = {};
  final project = collection.project!;

  @override
  void initState() {
    screens.addAll(project.screens.map((e) => e.id));
    components.addAll(project.customComponents.map((e) => e.id));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool loading = false;
    return Container(
      width: 300,
      constraints: BoxConstraints(maxHeight: dh(context, 0.8)),
      decoration: BoxDecoration(
        color: theme.background1,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
          .copyWith(bottom: 20),
      child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Commit',
                  style: AppFontStyle.headerStyle(),
                ),
                const AppCloseButton()
              ],
            ),
            15.hBox,
            AppTextField(
              hintText: 'Commit Message',
              controller: _message,
              fontSize: 14,
              maxLines: 3,
              validator: (value) =>
                  value.isEmpty ? 'Please enter message' : null,
            ),
            15.hBox,
            Flexible(
              child: FormField(
                  validator: (value) => screens.isEmpty && components.isEmpty
                      ? 'Please select at-least one screen or custom-component'
                      : null,
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Screens',
                                  style: AppFontStyle.lato(16,
                                      fontWeight: FontWeight.w600),
                                ),
                                10.hBox,
                                StatefulBuilder(builder: (context, setState2) {
                                  return ListView.builder(
                                      itemCount: project.screens.length,
                                      shrinkWrap: true,
                                      itemBuilder: (context, i) =>
                                          CheckboxListTile(
                                              dense: true,
                                              value: screens.contains(
                                                  project.screens[i].id),
                                              title: Text(
                                                project.screens[i].name,
                                                style: AppFontStyle.lato(14),
                                              ),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  if (value) {
                                                    screens.add(
                                                        project.screens[i].id);
                                                  } else {
                                                    screens.remove(
                                                        project.screens[i].id);
                                                  }
                                                  setState2(() {});
                                                }
                                              }));
                                }),
                                15.hBox,
                                Text(
                                  'Custom Widgets',
                                  style: AppFontStyle.lato(16,
                                      fontWeight: FontWeight.w600),
                                ),
                                10.hBox,
                                StatefulBuilder(builder: (context, setState2) {
                                  return ListView.builder(
                                      itemCount:
                                          project.customComponents.length,
                                      shrinkWrap: true,
                                      itemBuilder: (context, i) =>
                                          CheckboxListTile(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              dense: true,
                                              value: components.contains(project
                                                  .customComponents[i].id),
                                              title: Text(
                                                project
                                                    .customComponents[i].name,
                                                style: AppFontStyle.lato(14),
                                              ),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  if (value) {
                                                    components.add(project
                                                        .customComponents[i]
                                                        .id);
                                                  } else {
                                                    components.remove(project
                                                        .customComponents[i]
                                                        .id);
                                                  }
                                                  setState2(() {});
                                                }
                                              }));
                                }),
                                10.hBox,
                              ],
                            ),
                          ),
                        ),
                        if (state.hasError) ...[
                          Text(
                            state.errorText ?? '',
                            style: AppFontStyle.lato(
                              13,
                              color: ColorAssets.red,
                            ),
                          ),
                          10.hBox,
                        ]
                      ],
                    );
                  }),
            ),
            StatefulBuilder(builder: (context, setState) {
              if (loading) {
                return const ButtonLoadingWidget();
              }
              return AppButton(
                title: 'Commit',
                onPressed: () {
                  if (Form.of(context).validate()) {
                    setState(() {
                      loading = true;
                    });
                    dataBridge
                        .addCommit(
                            FVBCommit(
                                dateTime: DateTime.now(),
                                message: _message.text,
                                id: randomId,
                                screens: project.screens
                                    .where((element) =>
                                        screens.contains(element.id))
                                    .map((e) => FVBEntity(e.id, e.name))
                                    .toList(),
                                customComponents: project.customComponents
                                    .where((element) =>
                                        components.contains(element.id))
                                    .map((e) => FVBEntity(e.id, e.name))
                                    .toList()),
                            project)
                        .then((value) {
                      AnimatedDialog.hide(context);
                    });
                  }
                },
              );
            })
          ],
        ),
      ),
    );
  }
}
