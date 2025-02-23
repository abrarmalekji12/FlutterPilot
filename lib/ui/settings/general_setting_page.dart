import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:process_run/process_run.dart';

import '../../app_config.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../common/app_button.dart';
import '../../common/button_loading_widget.dart';
import '../../common/common_methods.dart';
import '../../common/custom_drop_down.dart';
import '../../common/custom_popup_menu_button.dart';
import '../../common/extension_util.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../common/undo/revert_work.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../constant/string_constant.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../cubit/user_details/user_details_cubit.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../injector.dart';
import '../../models/common_mixins.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/project_model.dart';
import '../../models/template_model.dart';
import '../../models/variable_model.dart';
import '../../screen_model.dart';
import '../../user_session.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/button/filled_button.dart';
import '../../widgets/button/outlined_button.dart';
import '../../widgets/loading/overlay_loading_component.dart';
import '../../widgets/textfield/app_textfield.dart';
import '../boundary_widget.dart';
import '../fvb_code_editor.dart';
import '../navigation/animated_dialog.dart';
import '../project/project_selection_page.dart';
import '../create_screen_dialog.dart';
import 'bloc/settings_bloc.dart';
import 'models/collaborator.dart';
import 'models/project_setting_model.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  late final ProjectSettingsModel setting;
  late final FVBProject project;
  late final UserDetailsCubit _userDetailsCubit;
  late final OperationCubit _operationCubit;
  FVBCollaborator model =
      FVBCollaborator(email: '', permission: ProjectPermission.editor);
  final TextEditingController _collaboratorController = TextEditingController();
  late RevertWork undoWork;
  final UserSession _userSession = sl();
  final SettingsBloc _settingsBloc = sl();
  late OperationCubit operationCubit;
  late ProjectPermission _permission;

  @override
  void initState() {
    super.initState();

    operationCubit = context.read<OperationCubit>();
    project = operationCubit.project!;
    setting = operationCubit.project!.settings;
    _permission = project.userRole(_userSession);

    _userDetailsCubit = context.read<UserDetailsCubit>();
    _operationCubit = context.read<OperationCubit>();
    undoWork = RevertWork.init();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: _settingsBloc,
      listener: (context, state) {
        if (state is SettingsCollaboratorErrorState) {
          showConfirmDialog(
            title: 'Error',
            subtitle: state.message,
            context: context,
            positive: 'ok',
          );
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Align(
          child: Container(
            width: Responsive.isDesktop(context) ? dw(context, 40) : null,
            height: Responsive.isDesktop(context) ? dh(context, 80) : null,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.background1,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settings',
                      style: AppFontStyle.headerStyle(),
                    ),
                    AppCloseButton(
                      onTap:()=> AnimatedDialog.hide(context),
                    )
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Global Settings',
                        style: AppFontStyle.lato(16,
                            color: theme.titleColor,
                            fontWeight: FontWeight.w900),
                      ),

                      /// Dark Theme is not included in the first version
                      if (kDebugMode) ...[
                        const Divider(
                          height: 20,
                        ),
                        SelectionGroupWidget<ThemeType>(
                          selection: _userSession.settingModel!.generalTheme,
                          data: ThemeType.values,
                          title: 'Choose Theme',
                          onChange: (value) {
                            undoWork.add(
                                _userSession.settingModel!.generalTheme, () {
                              _userSession.settingModel!.generalTheme = value;
                              operationCubit.updateUserSetting(
                                  'general_theme', value.index);
                              theme.add(UpdateThemeEvent(value));
                              setState(() {});
                            }, (p0) {
                              _userSession.settingModel!.generalTheme = p0;
                              operationCubit.updateUserSetting(
                                  'general_theme', p0.index);
                              theme.add(UpdateThemeEvent(p0));
                            });
                          },
                        ),
                      ],
                      const SizedBox(
                        height: 30,
                      ),
                      SelectionGroupWidget<String>(
                        selection: _userSession.settingModel!.iDETheme,
                        data: editorThemes.keys.toList(growable: false),
                        title: 'Choose IDE Theme',
                        onChange: (value) {
                          undoWork.add(_userSession.settingModel!.iDETheme, () {
                            _userSession.settingModel!.iDETheme = value;
                            operationCubit.updateUserSetting('theme', value);
                            setState(() {});
                          }, (p0) {
                            _userSession.settingModel!.iDETheme = p0;
                            operationCubit.updateUserSetting('theme', p0);
                          });
                        },
                      ),
                      10.hBox,
                      BlocBuilder(
                        bloc: _userDetailsCubit,
                        buildWhen: (_, state) =>
                            state is UserDetailsFigmaTokenUpdatedState,
                        builder: (context, state) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Figma Connect',
                                style: AppFontStyle.lato(14,
                                    fontWeight: FontWeight.w700),
                              ),
                              if (_userSession.settingModel!.figmaAccessToken !=
                                      null &&
                                  _userSession.settingModel!.figmaCode != null)
                                Row(
                                  children: [
                                    Container(
                                      padding: 10.insetsAll,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.done,
                                            color: Colors.green,
                                          ),
                                          10.wBox,
                                          Text(
                                            'Connected',
                                            style: AppFontStyle.lato(
                                              14,
                                              color: Colors.green,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    15.wBox,
                                    OutlinedButtonWidget(
                                      width: 100,
                                      height: 35,
                                      text: 'Logout',
                                      onTap: () {
                                        showConfirmDialog(
                                            title: 'Alert',
                                            subtitle:
                                                'Do you want to logout from Figma?',
                                            context: context,
                                            positive: 'Yes',
                                            negative: 'Cancel',
                                            onPositiveTap: () {
                                              _userDetailsCubit
                                                  .disconnectFigmaAccount();
                                            });
                                      },
                                    )
                                  ],
                                )
                              else
                                FilledButtonWidget(
                                  width: 120,
                                  height: 35,
                                  onTap: () {
                                    _userDetailsCubit.connectFigmaAccount();
                                  },
                                  text: 'Connect',
                                )
                            ],
                          );
                        },
                      ),
                      if (!kIsWeb) ...[
                        15.hDivider,
                        _buildPathSelection(
                            'Flutter Path ',
                            _userSession.settingModel?.otherSettings
                                ?.flutterPath, (value) {
                          _userSession
                              .settingModel?.otherSettings?.flutterPath = value;
                          operationCubit.updateUserSetting(
                              'otherSettings',
                              _userSession.settingModel?.otherSettings
                                  ?.toJson());
                        }),
                        15.hDivider,
                        _buildPathSelection(
                            'Project Path ',
                            _userSession.settingModel?.otherSettings
                                ?.projectPath, (value) {
                          _userSession
                              .settingModel?.otherSettings?.projectPath = value;
                          operationCubit.updateUserSetting(
                              'otherSettings',
                              _userSession.settingModel?.otherSettings
                                  ?.toJson());
                        })
                      ],
                      30.hBox,
                      Text(
                        'Project Settings',
                        style: AppFontStyle.lato(16,
                            color: theme.titleColor,
                            fontWeight: FontWeight.w900),
                      ),
                      const Divider(
                        height: 20,
                      ),
                      10.hBox,
                      if (_operationCubit.project!.screens.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Main Screen',
                              style: AppFontStyle.lato(14,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            StatefulBuilder(builder: (context, setState2) {
                              return CustomDropdownButton<Screen>(
                                  style: AppFontStyle.lato(13),
                                  value: _operationCubit.project!.mainScreen,
                                  hint: null,
                                  items: _operationCubit.project!.screens
                                      .map<CustomDropdownMenuItem<Screen>>(
                                        (e) => CustomDropdownMenuItem<Screen>(
                                          value: e,
                                          child: Text(
                                            e.name,
                                            style: AppFontStyle.lato(
                                              13,
                                              fontWeight: FontWeight.w500,
                                              color: theme.text1Color,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value !=
                                        _operationCubit.project!.mainScreen) {
                                      _operationCubit.project!.mainScreen =
                                          value;
                                      _operationCubit.update();
                                      _operationCubit.updateMainScreen();
                                      setState2(() {});
                                    }
                                  },
                                  selectedItemBuilder: (context, config) {
                                    return Text(
                                      config.name,
                                      style: AppFontStyle.lato(
                                        13,
                                        fontWeight: FontWeight.w500,
                                        color: theme.text1Color,
                                      ),
                                    );
                                  });
                            })
                          ],
                        ),
                      const SizedBox(
                        height: 12,
                      ),
                      IgnorePointer(
                        ignoring: _permission != ProjectPermission.owner,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // public or private radio button
                            Text('Target Devices',
                                style: AppFontStyle.lato(14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                for (final TargetPlatformType key
                                    in TargetPlatformType.values)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: StatefulBuilder(builder:
                                        (context, setStateForTargetTile) {
                                      final value =
                                          project.settings.target[key] ?? true;
                                      return InkWell(
                                        onTap: () {
                                          undoWork.add(value, () {
                                            project.settings.target[key] =
                                                !value;
                                            setState(() {});
                                          }, (value) {
                                            project.settings.target[key] =
                                                value;
                                            setState(() {});
                                          });
                                        },
                                        child: AnimatedContainer(
                                          width: 120,
                                          duration:
                                              const Duration(milliseconds: 100),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: value
                                                      ? ColorAssets.theme
                                                      : ColorAssets.grey,
                                                  width: 1.4)),
                                          padding: const EdgeInsets.all(8.0),
                                          margin: const EdgeInsets.all(4.0),
                                          child: Row(
                                            children: [
                                              Icon(
                                                key.icon,
                                                size: 18,
                                                color: theme.iconColor1,
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                key.name,
                                                style: AppFontStyle.lato(
                                                  13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  )
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      IgnorePointer(
                        ignoring: _permission != ProjectPermission.owner,
                        child: Row(
                          children: [
                            // public or private radio button
                            Expanded(
                              child: Text(
                                'Visibility',
                                style: AppFontStyle.lato(14,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Radio(
                                      value: true,
                                      activeColor: ColorAssets.theme,
                                      fillColor: WidgetStateProperty.all(
                                          ColorAssets.theme),
                                      focusColor: theme.text1Color,
                                      groupValue: setting.isPublic,
                                      onChanged: (value) {
                                        undoWork.add(false, () {
                                          setting.isPublic = true;
                                          setState(() {});
                                        }, (p0) {
                                          setting.isPublic = false;
                                          setState(() {});
                                        });
                                      }),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'Public',
                                    style: AppFontStyle.lato(
                                      14,
                                      color: theme.text1Color,
                                    ),
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
                                      activeColor: ColorAssets.theme,
                                      focusColor: theme.text1Color,
                                      fillColor: WidgetStateProperty.all(
                                          ColorAssets.theme),
                                      groupValue: setting.isPublic,
                                      onChanged: (value) {
                                        undoWork.add(true, () {
                                          setting.isPublic = false;
                                          setState(() {});
                                        }, (p0) {
                                          setting.isPublic = true;
                                          setState(() {});
                                        });
                                      }),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'Private',
                                    style: AppFontStyle.lato(
                                      14,
                                      color: theme.text1Color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (setting.isPublic)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paste this link',
                              style: AppFontStyle.lato(15,
                                  color: theme.text2Color,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text: '${appLink}run/${project.id}'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Copied to clipboard')));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 18,
                                      color: theme.text2Color.withOpacity(0.6),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child: Text(
                                        //html.window.location.href
                                        '${appLink}run/${project.id}',
                                        style: AppFontStyle.lato(15,
                                            color: theme.text2Color
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
                        height: 12,
                      ),
                      if (_permission == ProjectPermission.owner)
                        BlocConsumer(
                          listener: (context, state) {
                            if (state is SettingsCollaboratorAddedState) {
                              _collaboratorController.clear();
                            }
                          },
                          bloc: _settingsBloc,
                          buildWhen: (prev, state) =>
                              state is SettingsCollaboratorAddingState ||
                              state is SettingsCollaboratorAddedState ||
                              state is SettingsCollaboratorErrorState,
                          builder: (context, state) {
                            return OverlayLoadingComponent(
                              loading: state is SettingsCollaboratorAddingState,
                              radius: 6,
                              size: 25,
                              child: StatefulBuilder(
                                  builder: (context, setStateForCollaborators) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Collaborators',
                                          style: AppFontStyle.titleStyle(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 250,
                                          child: AppTextField(
                                            height: 40,
                                            hintText: 'Email',
                                            controller: _collaboratorController,
                                            onChanged: (String data) {
                                              model.email = data;
                                            },
                                          ),
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
                                              setStateForCollaborators(() {});
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        ListenableBuilder(
                                            listenable: _collaboratorController,
                                            builder: (context, _) {
                                              final bool enable =
                                                  _collaboratorController
                                                          .text.length >=
                                                      5;
                                              return InkWell(
                                                onTap: enable
                                                    ? () {
                                                        if (setting
                                                                .collaborators
                                                                ?.firstWhereOrNull((element) =>
                                                                    element
                                                                        .email ==
                                                                    _collaboratorController
                                                                        .text) !=
                                                            null) {
                                                          showConfirmDialog(
                                                            title: 'Alert!',
                                                            subtitle:
                                                                'User is already a collaborator!',
                                                            context: context,
                                                            positive: 'Ok',
                                                          );
                                                        } else {
                                                          _settingsBloc.add(
                                                              SettingsAddCollaboratorEvent(
                                                                  model));
                                                          model = FVBCollaborator(
                                                              email: '',
                                                              permission:
                                                                  ProjectPermission
                                                                      .editor);
                                                        }
                                                      }
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: CircleAvatar(
                                                  backgroundColor: enable
                                                      ? ColorAssets.theme
                                                      : ColorAssets.grey,
                                                  radius: 10,
                                                  child: const Icon(
                                                    Icons.done,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              );
                                            })
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      itemBuilder: (_, index) =>
                                          CollaboratorTile(
                                              model:
                                                  setting.collaborators![index],
                                              onDelete: () {
                                                setting.collaborators?.remove(
                                                    setting
                                                        .collaborators![index]);
                                                _settingsBloc.add(
                                                    SettingsUpdateCollaboratorsEvent());
                                              }),
                                      itemCount:
                                          setting.collaborators?.length ?? 0,
                                    ),
                                  ],
                                );
                              }),
                            );
                          },
                        ),

                      if (AppConfig.isAdmin &&
                          collection.project!.screens.isNotEmpty) ...[
                        15.hBox,
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload Screen Template',
                                style: AppFontStyle.titleStyle(),
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              const UploadTemplateWidget()
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Templates',
                              style: AppFontStyle.titleStyle(),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            const TemplateSelectionWidget(
                              selection: false,
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                      ],
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!undoWork.isEmpty) ...[
                        FilledButtonWidget(
                          width: 120,
                          onTap: () {
                            undoWork.clear();
                            context
                                .read<OperationCubit>()
                                .updateProjectSettings();
                            AnimatedDialog.hide(context);
                          },
                          text: 'Apply',
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                      ],
                      OutlinedButtonWidget(
                        width: 120,
                        onTap: () {
                          undoWork.revert();
                          AnimatedDialog.hide(context);
                        },
                        text: 'Cancel',
                      ),
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

  _buildPathSelection(
      String title, String? path, ValueChanged<String> onChanged) {
    String? value = path;
    return StatefulBuilder(builder: (context, setStateForSelection) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppFontStyle.lato(14, fontWeight: FontWeight.w700),
              ),
              FilledButtonWidget(
                width: 120,
                height: 35,
                text: value != null ? 'Replace path' : 'Choose path',
                onTap: () {
                  FilePicker.platform
                      .getDirectoryPath(initialDirectory: value)
                      .then((_value) {
                    if (_value != null) {
                      setStateForSelection(() {
                        value = _value;
                      });
                    }
                  });
                },
              ),
            ],
          ),
          if (value != null)
            InkWell(
              onTap: () {
                final shell = Shell();
                shell.run('explorer $value');
              },
              child: Row(
                children: [
                  Text(
                    value ?? '',
                    style: AppFontStyle.lato(
                      13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ).copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  8.wBox,
                  Icon(
                    Icons.arrow_right_alt_rounded,
                    size: 18,
                    color: Colors.grey.shade600,
                  )
                ],
              ),
            ),
        ],
      );
    });
  }
}

class UploadTemplateWidget extends StatefulWidget {
  const UploadTemplateWidget({Key? key}) : super(key: key);

  @override
  State<UploadTemplateWidget> createState() => _UploadTemplateWidgetState();
}

class _UploadTemplateWidgetState extends State<UploadTemplateWidget>
    with CustomComponentExtractor {
  late final OperationCubit _operationCubit;
  late final SelectionCubit _selectionCubit;
  Viewable? screen;
  final TextEditingController _nameController = TextEditingController(),
      _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _operationCubit = context.read<OperationCubit>();
    _selectionCubit = context.read<SelectionCubit>();
    screen = _selectionCubit.selected.viewable;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 250,
            child: AppTextField(
              controller: _nameController,
              title: 'Name',
              required: true,
              height: 35,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 250,
            child: AppTextField(
              controller: _descriptionController,
              title: 'Description',
              height: 35,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 250,
            child: FormField(
                initialValue: screen,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (object) {
                  if (screen != null) {
                    final report = _operationCubit.validateComponent(
                        screen!.rootComponent!,
                        screen!.rootComponent!,
                        screen,
                        [_operationCubit.project!.scopeName]);
                    print(
                        'VALIDATE ${report?.error} ${report?.componentError}');
                    if (report != null) {
                      final keyList =
                          report.componentError.keys.toList(growable: false);
                      return '${report.componentError.entries.length} errors found!\n ${report.componentError.entries.map((e) => '(${keyList.indexOf(e.key) + 1}) ${e.key.id} => ${e.value}').join('\n')}';
                    }

                    final List<CustomComponent> list = [];
                    if (screen!.rootComponent != null)
                      extractCustomComponents(screen!.rootComponent!, list);
                    for (final custom in list) {
                      if (custom.rootComponent != null) {
                        final report = _operationCubit.validateComponent(
                          custom.rootComponent!,
                          custom.rootComponent!,
                          screen,
                          [collection.project!.scopeName],
                        );
                        if (report != null) {
                          return 'This screen depends on ${custom.name}, but in ${custom.name}, ${report.errorCount} errors found!\n ${report.componentError.entries.map((e) => '${e.key.name} => ${e.value}').join('\n')}';
                        }
                      }
                    }
                    return null;
                  }

                  return 'Please select screen';
                },
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Screen',
                        style: AppFontStyle.lato(
                          14,
                          fontWeight: FontWeight.w400,
                          color: ColorAssets.color333333,
                        ),
                      ),
                      10.hBox,
                      CustomDropdownButton<Viewable>(
                          style: AppFontStyle.lato(13),
                          value: screen,
                          hint: Text(
                            'Select Screen',
                            style: AppFontStyle.lato(14),
                          ),
                          items: _operationCubit.project!.screens
                              .map<CustomDropdownMenuItem<Screen>>(
                                (e) => CustomDropdownMenuItem<Screen>(
                                  value: e,
                                  child: Text(
                                    e.name,
                                    style: AppFontStyle.lato(
                                      13,
                                      fontWeight: FontWeight.w500,
                                      color: theme.text1Color,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != screen) {
                              screen = value;
                              setState(() {});
                            }
                          },
                          selectedItemBuilder: (context, config) {
                            return Text(
                              config.name,
                              style: AppFontStyle.lato(
                                13,
                                fontWeight: FontWeight.w500,
                                color: theme.text1Color,
                              ),
                            );
                          }),
                      if (state.hasError) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          state.errorText ?? 'ERROR',
                          style: AppFontStyle.lato(14, color: ColorAssets.red),
                        )
                      ]
                    ],
                  );
                }),
          ),
          const SizedBox(
            height: 15,
          ),
          BlocBuilder<OperationCubit, OperationState>(
            builder: (context, state) {
              if (state is ComponentOperationTemplateUploadingState) {
                return const ButtonLoadingWidget();
              }
              return Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  width: 120,
                  height: 45,
                  title: 'Submit',
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _nameController.text.isNotEmpty &&
                        screen != null) {
                      final model = TemplateModel(
                        screen! as Screen,
                        _operationCubit.project!.variables.values
                            .whereType<VariableModel>()
                            .where((element) =>
                                element.uiAttached && element.deletable)
                            .toList(growable: false),
                        _nameController.text,
                        _descriptionController.text.isNotEmpty
                            ? _descriptionController.text
                            : null,
                        _operationCubit.project!.userId,
                        DateTime.now(),
                        id: randomId,
                      );
                      model.images.addAll(model.extractedImages);
                      model.customComponents.addAll(model.extractedCustoms);
                      _operationCubit.uploadTemplate(model);
                    }
                  },
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

class CollaboratorTile extends StatelessWidget {
  final FVBCollaborator model;
  final VoidCallback onDelete;

  const CollaboratorTile(
      {Key? key, required this.model, required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 0.4, color: ColorAssets.colorD0D5EF),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              model.email,
              style: AppFontStyle.lato(14,
                  color: theme.text2Color, fontWeight: FontWeight.normal),
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              model.permission.name.capitalize ?? '',
              style: AppFontStyle.lato(14, color: theme.text2Color),
            ),
            20.wBox,
            RoundedAppIconButton(
                icon: Icons.delete, onPressed: onDelete, color: ColorAssets.red)
          ],
        ),
      ),
    );
  }
}

class PermissionTypeDropDown extends StatelessWidget {
  final FVBCollaborator model;
  final void Function(ProjectPermission) onChanged;

  const PermissionTypeDropDown(
      {Key? key, required this.model, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: AppFontStyle.lato(14, color: theme.text1Color),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProjectPermission>(
          iconEnabledColor: theme.text1Color,
          iconDisabledColor: theme.text2Color,
          items: const [
            DropdownMenuItem(
              child: Text('Owner'),
              value: ProjectPermission.owner,
            ),
            DropdownMenuItem(
                child: Text('Editor'), value: ProjectPermission.editor),
          ],
          style: AppFontStyle.lato(14, color: theme.text1Color),
          onChanged: (value) {
            if (value != null) {
              onChanged.call(value);
            }
          },
          value: model.permission,
        ),
      ),
    );
  }
}

class SelectionGroupWidget<T> extends StatelessWidget {
  final T selection;
  final List<T> data;
  final String title;
  final ValueChanged<T> onChange;

  const SelectionGroupWidget(
      {Key? key,
      required this.selection,
      required this.data,
      required this.onChange,
      required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppFontStyle.lato(14,
              color: theme.titleColor, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        SizedBox(
          width: 200,
          child: CustomDropdownButton<T>(
              style: AppFontStyle.lato(13),
              value: selection,
              hint: null,
              items: data
                  .map<CustomDropdownMenuItem<T>>(
                    (e) => CustomDropdownMenuItem<T>(
                      value: e,
                      child: Text(
                        e.toString(),
                        style: AppFontStyle.lato(
                          13,
                          fontWeight: FontWeight.w500,
                          color: theme.text1Color,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                onChange.call(value);
              },
              selectedItemBuilder: (context, data) {
                return Text(
                  data.toString(),
                  style: AppFontStyle.lato(
                    13,
                    fontWeight: FontWeight.w500,
                    color: theme.text1Color,
                  ),
                );
              }),
        )
      ],
    );
  }
}
