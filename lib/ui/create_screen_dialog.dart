import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../common/common_methods.dart';
import '../common/extension_util.dart';
import '../common/validations.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/screen_config/screen_config_cubit.dart';
import '../cubit/user_details/user_details_cubit.dart';
import '../injector.dart';
import '../models/component_selection.dart';
import '../models/fvb_ui_core/component/custom_component.dart';
import '../models/project_model.dart';
import '../models/template_model.dart';
import '../runtime_provider.dart';
import '../user_session.dart';
import '../widgets/button/app_close_button.dart';
import '../widgets/button/filled_button.dart';
import '../widgets/button/outlined_button.dart';
import '../widgets/loading/button_loading.dart';
import '../widgets/message/empty_text.dart';
import '../widgets/textfield/app_textfield.dart';
import 'emulation_view.dart';
import 'home/landing_page.dart';
import 'navigation/animated_dialog.dart';
import 'project/project_selection_page.dart';
import 'settings/general_setting_page.dart';

class ScreenCreationDialog extends StatefulWidget {
  final ValueChanged<Screen>? onCreated;

  const ScreenCreationDialog({
    Key? key,
    this.onCreated,
  }) : super(key: key);

  @override
  State<ScreenCreationDialog> createState() => _ScreenCreationDialogState();
}

class _ScreenCreationDialogState extends State<ScreenCreationDialog> {
  String type = 'screen';
  String name = '';
  final TextEditingController _controller = TextEditingController();
  final _operationCubit = sl<OperationCubit>();
  final _componentSelectionCubit = sl<SelectionCubit>();
  TemplateModel? selectedTemplate;
  final _componentCreationCubit = sl<CreationCubit>();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  late UserDetailsCubit _userDetailsCubit;
  final UserSession _userSession = sl();

  final TextEditingController _figmaLink = TextEditingController();

  @override
  void initState() {
    _userDetailsCubit = context.read<UserDetailsCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: _operationCubit,
      listener: (context, state) {
        if (state is ComponentOperationErrorState) {
          showConfirmDialog(
            title: 'Error',
            subtitle: state.msg,
            context: context,
            positive: 'Ok',
          );
        }
      },
      child: Form(
        key: _formkey,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: theme.background1,
              borderRadius: BorderRadius.circular(10)),
          width: MediaQuery.of(context).size.width * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Screen',
                    style: AppFontStyle.headerStyle(),
                  ),
                  AppCloseButton(
                    onTap: () {
                      AnimatedDialog.hide(context);
                    },
                  )
                ],
              ),
              20.hBox,
              // Row(
              //   crossAxisAlignment: CrossAxisAlignment.center,
              //   children: [
              //     Text(
              //       'Type',
              //       style: AppFontStyle.lato(14, fontWeight: FontWeight.bold, color: theme.text1Color),
              //     ),
              //     const SizedBox(
              //       width: 10,
              //     ),
              //     SizedBox(
              //       height: 50,
              //       width: 100,
              //       child: CustomDropdownButton<String>(
              //         style: AppFontStyle.lato(14),
              //         value: type,
              //         hint: null,
              //         items: ['screen', 'dialog']
              //             .map<CustomDropdownMenuItem<String>>(
              //               (e) => CustomDropdownMenuItem<String>(
              //                 value: e,
              //                 child: Align(
              //                   alignment: Alignment.centerLeft,
              //                   child: Text(
              //                     e,
              //                     style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
              //                   ),
              //                 ),
              //               ),
              //             )
              //             .toList(),
              //         onChanged: (value) {
              //           setState(() {
              //             type = value;
              //           });
              //         },
              //         selectedItemBuilder: (context, e) {
              //           return Align(
              //             alignment: Alignment.centerLeft,
              //             child: Text(
              //               e,
              //               style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
              //             ),
              //           );
              //         },
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(
              //   height: 15,
              // ),
              SizedBox(
                width: 300,
                child: AppTextField(
                  fontSize: 16,
                  maxLines: 1,
                  height: 45,
                  controller: _controller,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == _operationCubit.project?.name) {
                      return 'Screen name can not be same as project name!';
                    }

                    if (_operationCubit.project?.screens.firstWhereOrNull(
                            (element) => element.name == value) !=
                        null) {
                      return 'Screen with name "$value" already exist!';
                    }
                    return Validations.commonNameValidator().call(value);
                  },
                  hintText: 'MyScreenXYZ',
                  onChanged: (String value) {
                    name = value;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: TemplateSelectionWidget(
                  onChange: (template) {
                    selectedTemplate = template;
                  },
                ),
              ),
              const SizedBox(
                height: 15,
              ),

              Text(
                'Or Convert from Figma',
                style: AppFontStyle.titleStyle(),
              ),
              10.hBox,
              if (_userSession.settingModel?.figmaAccessToken != null) ...[
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          border: true,
                          controller: _figmaLink,
                          fontSize: 14,
                          hintText: 'URL',
                        ),
                      ),
                      10.wBox,
                      BlocBuilder(
                        bloc: _operationCubit,
                        buildWhen: (_, state) =>
                            state
                                is ComponentOperationLoadingFigmaScreensState ||
                            state is ComponentOperationErrorState ||
                            state is ComponentOperationInitial,
                        builder: (context, state) {
                          if (state
                              is ComponentOperationLoadingFigmaScreensState) {
                            return const Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(ColorAssets.theme),
                                ),
                              ),
                            );
                          }
                          return IconButton(
                            onPressed: () {
                              if (_figmaLink.text.isNotEmpty) {
                                _operationCubit.addScreensFromFigma(
                                    _userSession
                                        .settingModel!.figmaAccessToken!,
                                    _figmaLink.text);
                              }
                            },
                            icon: const Icon(Icons.arrow_forward),
                          );
                        },
                      )
                    ],
                  ),
                )
              ] else
                InkWell(
                  onTap: () {
                    AnimatedDialog.show(
                      context,
                      const GeneralSettingsPage(),
                      key: 'settings',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Go to Settings and connect with your figma account',
                          style: AppFontStyle.lato(14,
                              color: theme.text3Color,
                              fontWeight: FontWeight.normal),
                        ),
                        10.wBox,
                        Icon(
                          Icons.arrow_right_alt,
                          color: theme.text3Color,
                        )
                      ],
                    ),
                  ),
                ),

              30.hBox,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BlocBuilder(
                    bloc: _operationCubit,
                    buildWhen: (_, state) =>
                        state is ComponentOperationScreenAddingState ||
                        state is ComponentOperationErrorState ||
                        state is ComponentOperationScreensUpdatedState,
                    builder: (context, state) {
                      if (state is ComponentOperationScreenAddingState) {
                        return const SizedBox(
                          width: 120,
                          height: 45,
                          child: ButtonLoadingWidget(),
                        );
                      }
                      return FilledButtonWidget(
                        width: 120,
                        height: 45,
                        text: 'Create',
                        onTap: _onCreate,
                      );
                    },
                  ),
                  20.wBox,
                  OutlinedButtonWidget(
                    width: 120,
                    height: 45,
                    text: 'Cancel',
                    onTap:()=> AnimatedDialog.hide(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCreate() async {
    if (_formkey.currentState!.validate()) {
      final Screen screen;
      if (selectedTemplate == null || _figmaLink.text.isNotEmpty) {
        screen = Screen.otherScreen(name, _operationCubit.project!, type: type);
      } else {
        screen = selectedTemplate!.screen.clone(
          name: name,
          project: collection.project,
        );
        screen.processor.parentProcessor = _operationCubit.project!.processor;
        for (final custom in selectedTemplate!.customComponents) {
          final comp = custom.clone(null, deepClone: true) as CustomComponent;
          comp.processor.parentProcessor = _operationCubit.project!.processor;
          comp.objects.forEach((element) {
            element.processor.parentProcessor =
                _operationCubit.project!.processor;
          });
          _operationCubit.project!.customComponents.add(comp);
          await _operationCubit.saveCustomComponent(comp);
        }
        for (final image in selectedTemplate!.images) {
          _operationCubit.project!.imageList.add(image.name!);
        }
        await Future.wait(selectedTemplate!.images
            .map((e) => _operationCubit.uploadImage(e))
            .toList());
        await _operationCubit.addVariables(selectedTemplate!.variables
            .map((e) => e.clone())
            .toList(growable: false));
      }
      _operationCubit
          .addScreen(
        screen,
      )
          .then((value) async {
        _userDetailsCubit.updateScreen();
        _componentSelectionCubit.init(ComponentSelectionModel.unique(
            screen.rootComponent!, screen.rootComponent!,
            screen: screen));
        _componentCreationCubit.changedComponent();
        AnimatedDialog.hide(context);
        widget.onCreated?.call(screen);
      });
    }
  }
}

class TemplateSelectionWidget extends StatefulWidget {
  final ValueChanged<TemplateModel?>? onChange;
  final bool selection;

  const TemplateSelectionWidget(
      {Key? key, this.selection = true, this.onChange})
      : super(key: key);

  @override
  State<TemplateSelectionWidget> createState() =>
      _TemplateSelectionWidgetState();
}

class _TemplateSelectionWidgetState extends State<TemplateSelectionWidget> {
  late final ScreenConfigCubit screenConfigCubit;
  TemplateModel? selected;
  final componentOperationCubit = sl<OperationCubit>();
  final _userDetails = sl<UserDetailsCubit>();

  @override
  void initState() {
    componentOperationCubit
        .loadTemplates(widget.selection ? null : _userDetails.userId);
    screenConfigCubit = context.read<ScreenConfigCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RuntimeProvider(
      runtimeMode: RuntimeMode.viewOnly,
      child: Container(
        child: BlocConsumer<OperationCubit, OperationState>(
          listener: (context, state) {
            if (state is ComponentOperationTemplateLoadedState &&
                (componentOperationCubit.templateList?.isNotEmpty ?? false)) {
              setState(() {
                selected = componentOperationCubit.templateList!.first;
                widget.onChange?.call(selected);
              });
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.selection) ...[
                  Text(
                    'Choose from Templates',
                    style: AppFontStyle.titleStyle(),
                  ),
                  const SizedBox(
                    height: 20,
                  )
                ],
                if (componentOperationCubit.templateList == null)
                  Expanded(
                    flex: widget.selection ? 1 : 0,
                    child: const Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else
                  Expanded(
                    flex: widget.selection ? 1 : 0,
                    child: (componentOperationCubit.templateList?.isEmpty ??
                            true)
                        ? const Center(
                            child: EmptyTextIconWidget(
                              text: 'No templates',
                              icon: Icons.file_copy_rounded,
                            ),
                          )
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (widget.selection)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      selected = null;
                                      widget.onChange?.call(selected);
                                    });
                                  },
                                  child: DottedBorder(
                                    borderType: BorderType.RRect,
                                    radius: const Radius.circular(6),
                                    dashPattern: [4, 4],
                                    strokeCap: StrokeCap.round,
                                    strokeWidth: 2,
                                    color: selected == null
                                        ? ColorAssets.theme
                                        : ColorAssets.grey,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Blank',
                                        style: AppFontStyle.lato(
                                          16,
                                          color: selected == null
                                              ? ColorAssets.theme
                                              : ColorAssets.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ...componentOperationCubit.templateList!
                                  .asMap()
                                  .entries
                                  .map((e) {
                                final index = e.key;
                                final template = componentOperationCubit
                                    .templateList![index];
                                final screenConfig =
                                    defaultScreenConfigs.firstWhereOrNull(
                                            (e) => e.name == template.device) ??
                                        screenConfigCubit.screenConfigs.first;
                                final double width = 140;
                                return Container(
                                  width: width,
                                  height: width *
                                      screenConfig.height /
                                      screenConfig.width,
                                  child: InkWell(
                                    onTap: () {
                                      selected = template;
                                      widget.onChange?.call(selected);
                                      setState(() {});
                                    },
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: 2.borderRadius,
                                              border: Border.all(
                                                  width: 2,
                                                  color: selected == template
                                                      ? ColorAssets.theme
                                                      : ColorAssets.grey,
                                                  strokeAlign: BorderSide
                                                      .strokeAlignOutside),
                                            ),
                                            child: EmulationView(
                                              widget: template.screen
                                                      .build(context) ??
                                                  const Offstage(),
                                              screenConfig: screenConfig,
                                            ),
                                          ),
                                        ),
                                        if (!widget.selection)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: DeleteIconButton(
                                              onPressed: () {
                                                componentOperationCubit
                                                    .deleteTemplate(template);
                                              },
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                );
                              })
                            ],
                          ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }
}
