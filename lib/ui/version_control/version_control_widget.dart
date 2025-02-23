import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/app_button.dart';
import '../../common/common_methods.dart';
import '../../common/extension_util.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../injector.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/empty_text.dart';
import '../navigation/animated_dialog.dart';
import 'add_commit_widget.dart';
import 'restore_commit_widget.dart';

/// TODO(AddUserConnectionWithCommit):

class VersionControlWidget extends StatefulWidget {
  const VersionControlWidget({super.key});

  @override
  State<VersionControlWidget> createState() => _VersionControlWidgetState();
}

class _VersionControlWidgetState extends State<VersionControlWidget> {
  @override
  Widget build(BuildContext context) {
    final project = collection.project!;
    final commits =
        project.settings.versionControl?.commits.reversed.toList() ?? [];
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: theme.background1,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
          .copyWith(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version Control',
                style: AppFontStyle.headerStyle(),
              ),
              const AppCloseButton()
            ],
          ),
          10.hBox,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commits',
                style: AppFontStyle.titleStyle(),
              ),
              AppIconButton(
                onPressed: () {
                  AnimatedDialog.show(context, const AddCommitWidget());
                },
                icon: Icons.add,
                iconColor: ColorAssets.theme,
              )
            ],
          ),
          15.hBox,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, minHeight: 70),
            child: (project.settings.versionControl?.commits.isEmpty ?? true)
                ? const SizedBox(
                    height: 70,
                    child: EmptyTextWidget(text: 'No commits'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, i) => Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${commits[i].message}',
                                style: AppFontStyle.lato(16,
                                    fontWeight: FontWeight.w700),
                              ),
                              5.hBox,
                              Text(
                                DateFormat('dd-MM-yyyy hh:mm a')
                                    .format(commits[i].dateTime!),
                                style: AppFontStyle.lato(
                                  13,
                                  color: theme.text2Color.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                        ),
                        AppIconButton(
                          onPressed: () {
                            AnimatedDialog.show(
                                context,
                                RestoreCommitWidget(
                                  commit: commits[i],
                                ));
                          },
                          icon: Icons.restore,
                          iconColor: theme.iconColor1,
                        ),
                        5.wBox,
                        AppIconButton(
                          onPressed: () {
                            showConfirmDialog(
                                title: 'Alert!',
                                subtitle:
                                    'Are you sure you want to remove this commit, you will not get it back?',
                                context: context,
                                positive: 'Yes',
                                negative: 'No',
                                onPositiveTap: () {
                                  dataBridge.removeCommit(commits[i], project);
                                  setState(() {});
                                });
                          },
                          icon: Icons.delete,
                          iconColor: theme.iconColor1,
                        )
                      ],
                    ),
                    separatorBuilder: (context, i) => const Divider(),
                    itemCount: commits.length,
                  ),
          )
        ],
      ),
    );
  }
}
