import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/common_methods.dart';
import '../../common/custom_drop_down.dart';
import '../../common/extension_util.dart';
import '../../common/responsive/responsive_dimens.dart';
import '../../common/web/io_lib.dart';
import '../../constant/font_style.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../injector.dart';
import '../../user_session.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/button/filled_button.dart';
import '../../widgets/loading/button_loading.dart';
import '../../widgets/textfield/app_textfield.dart';
import '../navigation/animated_dialog.dart';
import 'bloc/feedback_bloc.dart';
import 'model/feedback.dart';

class FeedbackDialog extends StatefulWidget {
  final String? error;
  const FeedbackDialog({super.key, this.error});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  FeedbackType? type;
  final _feedbackBloc = sl<FeedbackBloc>();
  final TextEditingController _description = TextEditingController();

  @override
  void initState() {
    if (widget.error != null) {
      type = FeedbackType.bug;
      _description.text = 'Reported Error \n"${widget.error}"';
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: _feedbackBloc,
      listener: (context, state) {
        if (state is FeedbackSubmitSuccessState) {
          showConfirmDialog(
            title: 'Feedback Submitted!',
            subtitle:
                'Thank you for the feedback, please provide continuous feedback to help us grow :)',
            context: context,
            positive: 'ok',
          ).then((value) {
            AnimatedDialog.hide(context);
          });
        } else if (state is FeedbackErrorState) {
          showConfirmDialog(
            title: 'Error',
            subtitle: state.message,
            context: context,
            positive: 'ok',
          );
        }
      },
      child: Container(
        width: 500,
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
                    'Provide Feedback',
                    style: AppFontStyle.headerStyle(),
                  ),
                  const AppCloseButton()
                ],
              ),
              20.hBox,
              Text(
                'Choose type',
                style: AppFontStyle.lato(16),
              ),
              10.hBox,
              FormField<FeedbackType>(
                  validator: (_) =>
                      type == null ? 'Please select feedback type' : null,
                  builder: (state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IgnorePointer(
                          ignoring: widget.error != null,
                          child: CustomDropdownButton<FeedbackType>(
                            style: AppFontStyle.lato(16),
                            value: type,
                            hint: Text(
                              'Bug / Feature',
                              style: AppFontStyle.lato(
                                16,
                                fontWeight: FontWeight.normal,
                                color: theme.text2Color,
                              ),
                            ),
                            items: FeedbackType.values
                                .map((e) => CustomDropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e.name,
                                      style: AppFontStyle.lato(
                                        16,
                                        fontWeight: FontWeight.normal,
                                        color: theme.text2Color,
                                      ),
                                    )))
                                .toList(),
                            onChanged: (value) {
                              type = value;
                              setState(() {});
                            },
                            selectedItemBuilder: (context, value) => Text(
                              value.name,
                              style: AppFontStyle.lato(16,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        if (state.hasError) ...[
                          10.hBox,
                          Text(state.errorText!,
                              style: AppFontStyle.lato(
                                  res(context, 15.sp, 13.sp, 14.sp),
                                  color: Colors.red))
                        ]
                      ],
                    );
                  }),
              20.hBox,
              Text(
                'Please provide description',
                style: AppFontStyle.lato(16),
              ),
              10.hBox,
              SizedBox(
                height: 120,
                child: AppTextField(
                  textInputType: TextInputType.multiline,
                  controller: _description,
                  readOnly: widget.error != null,
                  hintText: 'Description...',
                  expands: true,
                  validator: (value) =>
                      value.isEmpty ? 'Please provide description' : null,
                ),
              ),
              20.hBox,
              Align(
                alignment: Alignment.centerRight,
                child: BlocBuilder(
                  bloc: _feedbackBloc,
                  builder: (context, state) {
                    if (state is FeedbackSubmitLoadingState) {
                      return const SizedBox(
                        width: 120,
                        height: 45,
                        child: ButtonLoadingWidget(),
                      );
                    }
                    return FilledButtonWidget(
                      width: 120,
                      text: 'Submit',
                      onTap: () {
                        if (Form.of(context).validate()) {
                          final session = sl<UserSession>();
                          _feedbackBloc.add(SubmitFeedbackEvent(FVBFeedback(
                            id: randomId,
                            userId: session.user.userId ?? '',
                            email: session.user.email,
                            type: type!,
                            projectId: collection.project?.id,
                            description: _description.text,
                            isWeb: kIsWeb ? 'web' : Platform.operatingSystem,
                          )));
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum FeedbackType {
  bug('Bug Report'),
  featureRequest('Feature Request');

  const FeedbackType(this.name);

  final String name;
}
