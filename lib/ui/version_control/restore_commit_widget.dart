import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../common/app_button.dart';
import '../../common/extension_util.dart';
import '../../common/responsive/responsive_dimens.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/user_details/user_details_cubit.dart';
import '../../injector.dart';
import '../../models/version_control/version_control_model.dart';
import '../../widgets/button/app_close_button.dart';
import '../navigation/animated_dialog.dart';

class RestoreCommitWidget extends StatefulWidget {
  final FVBCommit commit;

  const RestoreCommitWidget({super.key, required this.commit});

  @override
  State<RestoreCommitWidget> createState() => _RestoreCommitWidgetState();
}

class _RestoreCommitWidgetState extends State<RestoreCommitWidget> {
  final Set<String> screens = {};
  final Set<String> components = {};
  final project = collection.project!;

  @override
  void initState() {
    screens.addAll(widget.commit.screens.map((e) => e.id));
    components.addAll(widget.commit.customComponents.map((e) => e.id));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Restore Commit',
                  style: AppFontStyle.headerStyle(),
                ),
                const AppCloseButton()
              ],
            ),
            20.hBox,
            Text(
              widget.commit.message,
              style: AppFontStyle.titleStyle(),
            ),
            10.hBox,
            Text(
              DateFormat('dd-MM-yyyy hh:mm a').format(widget.commit.dateTime!),
              style: AppFontStyle.lato(14,
                  fontWeight: FontWeight.normal,
                  color: theme.text1Color.withOpacity(0.6)),
            ),
            20.hBox,
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
                                15.hBox,
                                StatefulBuilder(builder: (context, setState2) {
                                  return ListView.builder(
                                      itemCount: widget.commit.screens.length,
                                      shrinkWrap: true,
                                      itemBuilder: (context, i) =>
                                          CheckboxListTile(
                                              dense: true,
                                              value: screens.contains(
                                                  widget.commit.screens[i].id),
                                              title: Text(
                                                widget.commit.screens[i].name,
                                                style: AppFontStyle.lato(14),
                                              ),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  if (value) {
                                                    screens.add(widget
                                                        .commit.screens[i].id);
                                                  } else {
                                                    screens.remove(widget
                                                        .commit.screens[i].id);
                                                  }
                                                  setState2(() {});
                                                }
                                              }));
                                }),
                                20.hBox,
                                Text(
                                  'Custom Widgets',
                                  style: AppFontStyle.lato(16,
                                      fontWeight: FontWeight.w600),
                                ),
                                15.hBox,
                                StatefulBuilder(builder: (context, setState2) {
                                  return ListView.builder(
                                      itemCount:
                                          widget.commit.customComponents.length,
                                      shrinkWrap: true,
                                      itemBuilder: (context, i) =>
                                          CheckboxListTile(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              dense: true,
                                              value: components.contains(widget
                                                  .commit
                                                  .customComponents[i]
                                                  .id),
                                              title: Text(
                                                widget.commit
                                                    .customComponents[i].name,
                                                style: AppFontStyle.lato(14),
                                              ),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  if (value) {
                                                    components.add(widget
                                                        .commit
                                                        .customComponents[i]
                                                        .id);
                                                  } else {
                                                    components.remove(widget
                                                        .commit
                                                        .customComponents[i]
                                                        .id);
                                                  }
                                                  setState2(() {});
                                                }
                                              }));
                                }),
                                20.hBox,
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
            Builder(builder: (context) {
              return AppButton(
                title: 'Rollback',
                onPressed: () {
                  if (Form.of(context).validate()) {
                    context.read<UserDetailsCubit>().restoreProject(
                        widget.commit, screens, components, project);
                    AnimatedDialog.hide(context);
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
