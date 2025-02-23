import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../collections/project_info_collection.dart';
import '../../common/app_button.dart';
import '../../common/common_methods.dart';
import '../../common/extension_util.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../injector.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/button/outlined_button.dart';
import '../../widgets/loading/button_loading.dart';
import '../fvb_code_editor.dart';
import '../navigation/animated_dialog.dart';
import 'cubit/firebase_connect_cubit.dart';

class FirebaseConnectDialog extends StatefulWidget {
  const FirebaseConnectDialog({super.key});

  @override
  State<FirebaseConnectDialog> createState() => _FirebaseConnectDialogState();
}

class _FirebaseConnectDialogState extends State<FirebaseConnectDialog> {
  final FirebaseConnectCubit _firebaseConnectCubit = sl();
  final TextEditingController initializeController = TextEditingController();
  String firebaseJson = '';
  final UserProjectCollection _collection = sl();

  bool connected = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: _firebaseConnectCubit,
      listener: (context, state) {
        if (state is FirebaseConnectErrorState) {
          showConfirmDialog(
            title: 'Error',
            subtitle: state.message,
            context: context,
            positive: i10n.ok,
          );
        } else if (state is FirebaseConnectedSuccessState) {
          showConfirmDialog(
            title: 'Connected',
            subtitle: 'Firebase account is connected!',
            context: context,
            positive: i10n.ok,
          );
        }
      },
      child: SelectionArea(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Firebase Connect',
                    style: AppFontStyle.headerStyle(),
                  ),
                   AppCloseButton(
                    onTap:()=> AnimatedDialog.hide(context),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              BlocBuilder(
                  bloc: _firebaseConnectCubit,
                  buildWhen: (_, state) =>
                      state is FirebaseConnectedSuccessState ||
                      state is FirebaseConnectInitial,
                  builder: (_, state) {
                    if (_collection.project?.settings.firebaseConnect != null) {
                      final keyStyle = AppFontStyle.lato(16,
                          color: theme.text3Color.withOpacity(0.6),
                          fontWeight: FontWeight.w700);
                      final valueStyle = AppFontStyle.lato(16,
                          color: theme.text1Color, fontWeight: FontWeight.w700);
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.border1),
                            ),
                            child: RichText(
                              text: TextSpan(
                                  children: [
                                    TextSpan(children: [
                                      TextSpan(
                                          text: 'Status: ', style: keyStyle),
                                      TextSpan(
                                          text: 'Connected',
                                          style: valueStyle.copyWith(
                                              color: ColorAssets.green)),
                                    ]),
                                    TextSpan(children: [
                                      TextSpan(
                                          text: '\napiKey: ', style: keyStyle),
                                      TextSpan(
                                          text: _collection.project!.settings
                                              .firebaseConnect!.json['apiKey'],
                                          style: valueStyle)
                                    ]),
                                    TextSpan(children: [
                                      TextSpan(
                                          text: '\nappId: ', style: keyStyle),
                                      TextSpan(
                                          text: _collection.project!.settings
                                              .firebaseConnect!.json['appId'],
                                          style: valueStyle)
                                    ]),
                                    TextSpan(children: [
                                      TextSpan(
                                          text: '\nmessagingSenderId: ',
                                          style: keyStyle),
                                      TextSpan(
                                          text: _collection
                                              .project!
                                              .settings
                                              .firebaseConnect!
                                              .json['messagingSenderId'],
                                          style: valueStyle)
                                    ]),
                                    TextSpan(children: [
                                      TextSpan(
                                          text: '\nprojectId: ',
                                          style: keyStyle),
                                      TextSpan(
                                          text: _collection
                                              .project!
                                              .settings
                                              .firebaseConnect!
                                              .json['projectId'],
                                          style: valueStyle)
                                    ]),
                                    TextSpan(children: [
                                      TextSpan(
                                          text: '\nauthDomain: ',
                                          style: keyStyle),
                                      TextSpan(
                                          text: _collection
                                              .project!
                                              .settings
                                              .firebaseConnect!
                                              .json['authDomain'],
                                          style: valueStyle)
                                    ]),
                                  ],
                                  style: const TextStyle(
                                    height: 2,
                                  )),
                            ),
                          ),
                          15.hBox,
                          Row(
                            children: [
                              Text(
                                'Cloud Firestore',
                                style: AppFontStyle.titleStyle(),
                              ),
                              20.wBox,
                              Text(
                                'App.firestore',
                                style: keyStyle,
                              )
                            ],
                          ),
                          20.hBox,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppButton(
                                width: 120,
                                height: 40,
                                title: 'Disconnect',
                                enabledColor: ColorAssets.red,
                                onPressed: () {
                                  _firebaseConnectCubit.disconnect();
                                },
                              )
                            ],
                          ),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Provide JSON',
                          style: AppFontStyle.titleStyle(),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Container(
                          height: 250,
                          child: FVBCodeEditor(
                            controller: initializeController,
                            onCodeChange: (code, refresh) {
                              firebaseJson = code;
                            },
                            onErrorUpdate: (_, bool error) {},
                            config: FVBEditorConfig(
                                shrink: true,
                                smallBottomBar: true,
                                multiline: true,
                                isJson: true),
                            processor: systemProcessor,
                            code: '',
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButtonWidget(
                                text: 'Cancel',
                                height: 40,
                                width: 120,
                                onTap:()=> AnimatedDialog.hide(context),
                              ),
                              20.wBox,
                              BlocBuilder(
                                bloc: _firebaseConnectCubit,
                                buildWhen: (_, state) =>
                                    state is FirebaseConnectingState ||
                                    state is FirebaseConnectErrorState ||
                                    state is FirebaseConnectedSuccessState,
                                builder: (context, state) {
                                  if (state is FirebaseConnectingState) {
                                    return const SizedBox(
                                      width: 120,
                                      height: 40,
                                      child: ButtonLoadingWidget(),
                                    );
                                  }
                                  return AppButton(
                                    width: 120,
                                    height: 40,
                                    title: 'Connect',
                                    onPressed: () {
                                      _firebaseConnectCubit
                                          .connect(firebaseJson);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  })
            ],
          ),
        ),
      ),
    );
  }
}

/*

{
  "apiKey": "AIzaSyC7bVPmV5mTHxHbi1JxmDbECNIUvbSQ5SQ",
  "authDomain": "after4exam.firebaseapp.com",
  "databaseURL": "https://after4exam.firebaseio.com",
  "projectId": "after4exam",
  "storageBucket": "after4exam.appspot.com",
  "messagingSenderId": "694852617433",
  "appId": "1:694852617433:web:8f89afc0a808284d41eac8"
}
*/
