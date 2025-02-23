
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/extension_util.dart';
import '../common/validations.dart';
import '../constant/font_style.dart';
import '../cubit/user_details/user_details_cubit.dart';
import '../injector.dart';
import '../models/project_model.dart';
import '../widgets/button/app_close_button.dart';
import '../widgets/button/filled_button.dart';
import '../widgets/button/outlined_button.dart';
import '../widgets/loading/button_loading.dart';
import '../widgets/textfield/app_textfield.dart';
import 'navigation/animated_dialog.dart';

class TemplateUploadWidget extends StatefulWidget {
  final FVBProject project;

  const TemplateUploadWidget({super.key, required this.project});

  @override
  State<TemplateUploadWidget> createState() => _TemplateUploadWidgetState();
}

class _TemplateUploadWidgetState extends State<TemplateUploadWidget> {
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserDetailsCubit, UserDetailsState>(
      listener: (context, state) {
        if (state is ProjectUploadAsTemplateSuccessState) {
          AnimatedDialog.hide(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.background1,
          borderRadius: BorderRadius.circular(8),
        ),
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Template',
                  style: AppFontStyle.headerStyle(),
                ),
                const AppCloseButton()
              ],
            ),
            30.hBox,
            Text(
              'Project: ${widget.project.name}',
              style: AppFontStyle.titleStyle(),
            ),
            20.hBox,
            AppTextField(
              hintText: 'Description (optional)',
              required: false,
              controller: _descriptionController,
              validator: Validations.nonEmpty('Description'),
            ),
            30.hBox,
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButtonWidget(
                    width: 120,
                    onTap: () {
                      AnimatedDialog.hide(context);
                    },
                    text: 'Cancel',
                  ),
                  20.wBox,
                  BlocBuilder<UserDetailsCubit, UserDetailsState>(
                    builder: (context, state) {
                      return Visibility(
                        replacement: const SizedBox(
                          width: 120,
                          child: ButtonLoadingWidget(),
                        ),
                        visible: state is! ProjectUploadAsTemplateLoadingState,
                        child: FilledButtonWidget(
                          width: 120,
                          text: 'Submit',
                          onTap: () {
                            context.read<UserDetailsCubit>().addToTemplates(
                                  widget.project,
                                  _descriptionController.text,
                                );
                          },
                        ),
                      );
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
