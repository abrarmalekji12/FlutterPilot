import 'dart:async';
import 'dart:ui';
import '../../common/web/html_lib.dart' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;

// import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get.dart';
import 'package:resizable_widget/resizable_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bloc/error/error_bloc.dart';
import '../../bloc/paint_obj/paint_obj_bloc.dart';
import '../../bloc/right_side/right_side_bloc.dart';
import '../../bloc/state_management/state_management_bloc.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../collections/project_info_collection.dart';
import '../../common/analyzer/analyzer.dart';
import '../../common/app_button.dart';
import '../../common/app_loader.dart';
import '../../common/common_methods.dart';
import '../../common/converter/string_operation.dart';
import '../../common/custom_drop_down.dart';
import '../../common/custom_menu_bar.dart';
import '../../common/custom_popup_menu_button.dart';
import '../../common/extension_util.dart';
import '../../common/menu_style.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../components/component_impl.dart';
import '../../constant/app_dim.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../constant/image_asset.dart';
import '../../constant/preference_key.dart';
import '../../cubit/action_edit/action_edit_cubit.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../cubit/parameter_build_cubit/parameter_build_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../cubit/user_details/user_details_cubit.dart';
import '../../cubit/visual_box_drawer/visual_box_cubit.dart';
import '../../data/remote/common_data_models.dart';
import '../../injector.dart';
import '../../main.dart';
import '../../models/builder_component.dart';
import '../../models/component_selection.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/parameter_model.dart';
import '../../models/project_model.dart';
import '../../models/variable_model.dart';
import '../../riverpod/clipboard.dart';
import '../../runtime_provider.dart';
import '../../screen_model.dart';
import '../../user_session.dart';
import '../../widgets/evaluate_expression.dart';
import '../../widgets/image/app_image.dart';
import '../../widgets/message/empty_text.dart';
import '../../widgets/overlay/overlay_manager.dart';
import '../../widgets/textfield/appt_search_field.dart';
import '../action_widgets.dart';
import '../api_view.dart';
import '../boundary_widget.dart';
import '../build_view/build_view.dart';
import '../code_view_widget.dart';
import '../common/variable_dialog.dart';
import '../component_selection_dialog.dart';
import '../component_tree/component_tree.dart';
import '../controls_widget.dart';
import '../custom_component_property.dart';
import '../error_widget.dart';
import '../feedback/feedback_dialog.dart';
import '../files_view.dart';
import '../firebase_connect/firebase_connect.dart';
import '../navigation/animated_dialog.dart';
import '../navigation/animated_slider.dart';
import '../navigation_setting_view.dart';
import '../paint_tools/paint_tools.dart';
import '../parameter_ui.dart';
import '../preview_page.dart';
import '../settings/general_setting_page.dart';
import '../tools/firestore_assistant_tool.dart';
import '../tools/json_to_dart.dart';
import '../variable_ui.dart';
import '../version_control/version_control_widget.dart';
import 'center_main_side.dart';
import 'run_mode.dart';

const double kSelectionDialogWidth = 200;

class HomePage extends StatefulWidget {
  final String projectId;
  final String? userId;
  final bool runMode;

  const HomePage({Key? key, required this.projectId, required this.userId, this.runMode = false}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static StreamSubscription? _streamSubscription;
  final ScrollController propertyScrollController = ScrollController();
  late CreationCubit creationCubit;
  late OperationCubit operationCubit;
  late final UserDetailsCubit flutterProjectCubit;
  final ParameterBuildCubit _parameterCubit = sl();
  final visualBoxCubit = sl<VisualBoxCubit>();
  late ScreenConfigCubit screenConfigCubit;
  late SelectionCubit selectionCubit;

  @override
  void initState() {
    super.initState();
    selectionCubit = sl<SelectionCubit>();
    operationCubit = sl<OperationCubit>();
    creationCubit = sl<CreationCubit>();
    flutterProjectCubit = context.read<UserDetailsCubit>();
    screenConfigCubit = context.read<ScreenConfigCubit>();
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
    }
    HardwareKeyboard.instance.addHandler(_hardwareKeyboardHandler);
    if (_collection.project?.id != widget.projectId) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        AppLoader.show(context, loadingMode: LoadingMode.projectLoadingMode);
        flutterProjectCubit.loadProject(
          widget.projectId,
          userId: widget.userId,
        );
        AppLoader.update(0.2);
      });
    }
    else{
      if (kIsWeb) {
       _updateWebTitle();
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_hardwareKeyboardHandler);
    super.dispose();
  }

  void showSelectionDialog(BuildContext context, void Function(Component) onSelection, {List<String>? possibleItems}) {
    showModelDialog(
      context,
      ComponentSelectionDialog(
        possibleItems: possibleItems,
        onSelection: onSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: sl<EventLogBloc>(),
      listener: (context, state) {
        if (state is BugReportState) {
          AnimatedDialog.show(
            context,
            FeedbackDialog(
              error: state.error,
            ),
          );
        }
      },
      child: SafeArea(
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Material(
                color: theme.background1,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider<VisualBoxCubit>.value(value: visualBoxCubit),
                    BlocProvider<ParameterBuildCubit>.value(value: _parameterCubit),
                  ],
                  child: BlocBuilder<ThemeBloc, ThemeState>(
                    bloc: theme,
                    builder: (context, state) {
                      return BlocListener<UserDetailsCubit, UserDetailsState>(
                        key: GlobalObjectKey(theme.themeType),
                        listener: (context, state) {
                          switch (state) {
                            case (ProjectLoadingState _):
                              // AppLoader.show(context,
                              //     loadingMode: LoadingMode.projectLoadingMode);
                              break;
                            case FlutterProjectLoadingErrorState(model: var model):
                              AppLoader.hide(context);
                              showFlutterErrorDialog(model);
                              break;
                            case (ProjectUpdateSuccessState state):
                              if (state.deleted) {
                                Navigator.pop(context);
                              }
                              break;
                            case UserDetailsErrorState(message: var message):
                              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                AppLoader.hide(context);
                              });
                              showToast(message);
                              break;
                            case (FlutterProjectLoadedState loaded):
                              collection.project = loaded.project;
                              if (operationCubit.project!.device != null) {
                                final config = screenConfigCubit.screenConfigs
                                    .firstWhereOrNull((element) => element.name == operationCubit.project!.device);
                                if (config != null) {
                                  screenConfigCubit.changeScreenConfig(config);
                                }
                              }
                              AppLoader.hide(context);

                              _updateWebTitle();
                              Future.delayed(const Duration(milliseconds: 600), () {
                                takeScreenShot();
                              });

                              break;
                          }
                        },
                        child: widget.runMode
                            ? const RunModeWidget()
                            : const Responsive(
                                desktop: DesktopVisualEditor(),
                                tablet: DesktopVisualEditor(),
                                // mobile: MobileVisualEditor(),
                              ),
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> takeScreenShot() async {
    final boundary =
        const GlobalObjectKey('repaint_inside').currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      Future.delayed(const Duration(milliseconds: 600), () => takeScreenShot());
      return;
    }
    final image = await boundary.toImage(pixelRatio: 0.5);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    final temp = img.decodeImage(bytes!.buffer.asUint8List());
    final jpeg = img.encodeJpg(temp!, quality: 70);
    operationCubit.updateProjectThumbnail(collection.project!, jpeg);
  }

  void showFlutterErrorDialog(ProjectLoadErrorModel error) {
    final String title;
    final String message;
    switch (error.projectLoadError) {
      case ProjectLoadError.notPermission:
        title = 'Not enough permissions';
        message = 'you do not have permission to access this project';
        break;
      case ProjectLoadError.networkError:
        title = 'Network error';
        message = 'there was a network error while loading the project';
        break;
      case ProjectLoadError.otherError:
        title = 'Error';
        message = 'there was an error while loading the project';
        break;
      case ProjectLoadError.notFound:
        title = 'Not Found';
        message = error.error!;
        break;
    }
    showConfirmDialog(
      context: context,
      title: title,
      subtitle: message,
      positive: 'OK',
    );
  }

// void onErrorIgnoreOverflowErrors(FlutterErrorDetails details, {
//   bool forceReport = false,
// }) {
//   bool ifIsOverflowError = false;
//
//   // Detect overflow error.
//   var exception = details.exception;
//   if (exception is FlutterError) {
//     ifIsOverflowError = !exception.diagnostics.any(
//             (e) =>
//             e.value.toString().startsWith('A RenderFlex overflowed by'));
//   }
//
//   // Ignore if is overflow error.
//   if (ifIsOverflowError) {
//     logger('Overflow error.');
//     visualBoxCubit.enableError('Error happened');
//   } else {
//     FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
//   }
// }

  bool _hardwareKeyboardHandler(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.physicalKey == PhysicalKeyboardKey.keyZ &&
        HardwareKeyboard.instance.isControlPressed) {
      if (!FocusScope.of(context).hasFocus) {
        operationCubit.revertWork.undo();
        return true;
      }
    }
    return false;
  }

  void _updateWebTitle() {
    if(kIsWeb)
    Future.delayed(const Duration(milliseconds: 500),(){
      WidgetsBinding.instance.addPostFrameCallback((_){
        html.window.history.pushState(null, '${collection.project?.name??'FlutterPilot'}', 'projects/${widget.projectId}');

      });
    });
  }
}

class ScreenConfigSelection extends StatefulWidget {
  const ScreenConfigSelection({Key? key}) : super(key: key);

  @override
  State<ScreenConfigSelection> createState() => _ScreenConfigSelectionState();
}

class _ScreenConfigSelectionState extends State<ScreenConfigSelection> {
  late ScreenConfigCubit _screenConfigCubit;
  late OperationCubit _operationCubit;
  late VisualBoxCubit _visualBoxCubit;
  late SelectionCubit _selectionCubit;
  final Map<ScreenConfig, String> map = {};

  @override
  void initState() {
    _operationCubit = context.read<OperationCubit>();
    _screenConfigCubit = context.read<ScreenConfigCubit>();
    _visualBoxCubit = context.read<VisualBoxCubit>();
    _selectionCubit = context.read<SelectionCubit>();
    super.initState();
  }

  Future<Iterable<MapEntry<ScreenConfig, String>>> getAnalysisError() async {
    map.clear();
    final screen = _selectionCubit.selected.viewable;
    if (screen == null) {
      return [];
    }
    for (final config in _screenConfigCubit.screenConfigs) {
      final analysisReport =
          await FVBAnalyzer.analyze(screen.rootComponent!, Size(config.width, config.height), screen);
      final error = (analysisReport?.isNotEmpty ?? false) ? analysisReport!.first.message : null;
      if (error != null) {
        map[config] = error;
      }
      _visualBoxCubit.addAnalyzerError(
        config,
        screen,
        analysisReport ?? [],
      );
      if (config == selectedConfig) {
        _visualBoxCubit.updateError();
      }
    }
    print('Analysis map $map');

    systemProcessor.variables['dw']!.value = selectedConfig!.width;
    systemProcessor.variables['dh']!.value = selectedConfig!.height;
    return map.entries;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OperationCubit, OperationState>(
      buildWhen: (state1, state2) => state2 is OperationProjectSettingUpdatedState,
      builder: (context, state) {
        return BlocBuilder<StateManagementBloc, StateManagementState>(
          builder: (context, state) => BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
            bloc: _screenConfigCubit,
            builder: (context, state) {
              final list = _screenConfigCubit.screenConfigs;
              if (selectedConfig == null || !list.contains(selectedConfig)) {
                _screenConfigCubit.changeScreenConfig(list.first);
              }

              return FutureBuilder<Iterable<MapEntry<ScreenConfig, String?>>>(
                  future: getAnalysisError(),
                  builder: (context, data) {
                    final selectionMsg = data.hasData && (data.data?.isNotEmpty ?? false)
                        ? ' ${data.data!.length}/${list.length}'
                        : null;
                    return SizedBox(
                      width: 250,
                      child: CustomDropdownButton<ScreenConfig>(
                          style: AppFontStyle.lato(13),
                          value: selectedConfig,
                          hint: null,
                          items: list
                              .map<CustomDropdownMenuItem<ScreenConfig>>(
                                (config) => CustomDropdownMenuItem<ScreenConfig>(
                                  value: config,
                                  child: Row(
                                    children: [
                                      Icon(
                                        config.type.icon,
                                        size: 18,
                                        color: theme.iconColor1,
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(children: [
                                            TextSpan(
                                              text: config.name,
                                              style: AppFontStyle.lato(13,
                                                  fontWeight: FontWeight.w500, color: theme.text1Color),
                                            ),
                                            TextSpan(
                                              text: '\n${config.width} x ${config.height}',
                                              style: AppFontStyle.lato(12,
                                                  fontWeight: FontWeight.w500, color: theme.text3Color),
                                            )
                                          ]),
                                        ),
                                      ),
                                      _buildAnalysisTick(config),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != selectedConfig) {
                              selectedConfig = value;
                              _screenConfigCubit.changeScreenConfig(value);
                              _operationCubit.updateDeviceSelection(value.name);
                            }
                          },
                          selectedItemBuilder: (context, config) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    config.type.icon,
                                    size: 18,
                                    color: theme.iconColor1,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text: config.name,
                                          style: AppFontStyle.lato(13,
                                              fontWeight: FontWeight.w500, color: theme.text1Color),
                                        ),
                                      ]),
                                    ),
                                  ),
                                  // if(data.connectionState==ConnectionState.waiting)

                                  if (selectionMsg != null)
                                    Text(
                                      selectionMsg,
                                      style: AppFontStyle.lato(
                                        15,
                                        color: ColorAssets.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                    );
                  });
            },
          ),
        );
      },
    );
  }

  Widget _buildAnalysisTick(ScreenConfig config) {
    final error = map[config];
    final color = error != null ? ColorAssets.red : ColorAssets.green;
    return Tooltip(
      message: error ?? 'No errors',
      child: Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(border: Border.all(width: 1.5, color: color), shape: BoxShape.circle),
        child: Icon(
          error != null ? Icons.close : Icons.done,
          color: color,
          size: 13,
        ),
      ),
    );
  }
}

final UserProjectCollection _collection = sl<UserProjectCollection>();

class AppElevationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Widget child;

  const AppElevationButton({Key? key, this.onPressed, this.backgroundColor, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: FilledButton(
        onPressed: onPressed,
        style: ButtonStyle(
            padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
            elevation: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? 3 : 2),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered) ? backgroundColor?.withOpacity(0.7) : backgroundColor,
            ),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
        child: child,
      ),
    );
  }
}

class ToolbarButtons extends StatefulWidget {
  const ToolbarButtons({Key? key}) : super(key: key);

  @override
  State<ToolbarButtons> createState() => _ToolbarButtonsState();
}

class _ToolbarButtonsState extends State<ToolbarButtons> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            width: 250,
            child: ScreenConfigSelection(),
          ),
          10.wBox,
          AppIconButton(
            background: theme.background1,
            iconColor: theme.iconColor1,
            icon: Icons.refresh,
            onPressed: () {
              context.read<CreationCubit>().changedComponent();
              showPopupText(context, 'Refreshed!', long: false);
            },
          ),
          const VerticalDivider(
            width: 30,
          ),
          AppIconButton(
            background: theme.background1,
            iconColor: Colors.green.shade500,
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              final creationCubit = context.read<CreationCubit>();
              final screenConfigCubit = context.read<ScreenConfigCubit>();
              AnimatedDialog.show(
                context,
                BuildView(
                  operationCubit: context.read<OperationCubit>(),
                  screenConfigCubit: screenConfigCubit,
                  creationCubit: creationCubit,
                ),
              ).then((value) {
                fvbNavigationBloc.reset();
                Future.microtask(() {
                  screenConfigCubit.applyCurrentSizeToVariables();
                  creationCubit.changedComponent();
                });
              });
            },
          ),
          10.wBox,
          AppIconButton(
            background: theme.background1,
            iconColor: Colors.green.shade700,
            icon: Icons.play_arrow_outlined,
            onPressed: () {
              final creationCubit = context.read<CreationCubit>();
              final screenConfigCubit = context.read<ScreenConfigCubit>();
              AnimatedDialog.show(
                context,
                RunModeWidget(
                  onBack: () {
                    AnimatedDialog.hide(context);
                  },
                ),
              ).then((value) {
                Future.microtask(() {
                  fvbNavigationBloc.reset();
                  screenConfigCubit.applyCurrentSizeToVariables();
                  creationCubit.changedComponent();
                });
              });
            },
          ),
          10.wBox,
          AppIconButton(
            icon: Icons.code,
            iconColor: Colors.blue,
            background: theme.background1,
            onPressed: () {
              AnimatedDialog.show(
                context,
                const CodeViewerWidget(),
              );
            },
          ),
          const VerticalDivider(
            width: 30,
          ),
          AppIconButton(
            asset: Images.merge,
            iconColor: Colors.blue,
            background: theme.background1,
            onPressed: () {
              AnimatedDialog.show(context, const VersionControlWidget());
            },
          ),

          // const VariableShowHideMenu(),
        ],
      ),
    );
  }
}

class VariableShowHideMenu extends StatefulWidget {
  const VariableShowHideMenu({Key? key}) : super(key: key);

  @override
  State<VariableShowHideMenu> createState() => _VariableShowHideMenuState();
}

class _VariableShowHideMenuState extends State<VariableShowHideMenu> with OverlayManager {
  late VariableDialog _variableDialog;
  final key = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final componentOperationCubit = context.read<OperationCubit>();
        final componentCreationCubit = context.read<CreationCubit>();
        final componentSelectionCubit = context.read<SelectionCubit>();
        _variableDialog = VariableDialog(
            options: [
              for (final screen in componentOperationCubit.project!.screens)
                VariableDialogOption('copy to screen ${screen.name} variables', (p0) {
                  screen.variables[p0.name] = p0.clone();
                  // componentOperationCubit.project!.variables.remove(p0.name);
                  componentCreationCubit.changedComponent();
                }),
              for (final customComponent in componentOperationCubit.project!.customComponents)
                VariableDialogOption('copy to custom widget ${customComponent.name} variables', (p0) {
                  customComponent.variables[p0.name] = p0.clone();
                  componentCreationCubit.changedComponent(ancestor: customComponent);
                })
            ],
            variables: _collection.project!.variables,
            componentOperationCubit: componentOperationCubit,
            componentCreationCubit: componentCreationCubit,
            title: _collection.project!.name,
            onAdded: (model) {
              componentOperationCubit.project!.variables[model.name] = model;
              componentOperationCubit.addVariable(model as VariableModel);
              componentCreationCubit.changedComponent();
              componentSelectionCubit.refresh();
            },
            onEdited: (model) {
              _collection.project!.variables[model.name]!.setValue(_collection.project!.processor, model.value);
              Future.delayed(const Duration(milliseconds: 500), () {
                componentOperationCubit.updateVariable();
                componentCreationCubit.changedComponent();
                componentSelectionCubit.refresh();
              });
            },
            componentSelectionCubit: componentSelectionCubit,
            onDeleted: (FVBVariable model) {
              componentOperationCubit.project!.variables.remove(model.name);
              componentOperationCubit.updateVariable();
              componentCreationCubit.changedComponent();
              componentSelectionCubit.refresh();
            });
        _variableDialog.show(context, this, key);
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
            color: theme.background1, borderRadius: BorderRadius.circular(10), boxShadow: kElevationToShadow[1]),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Icon(
              Icons.data_array,
              color: theme.iconColor1,
              size: 18,
            ),
            const Spacer(),
            Text(
              'Variables',
              style: AppFontStyle.lato(13, color: theme.text1Color, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class DesktopVisualEditor extends StatefulWidget {
  const DesktopVisualEditor({Key? key}) : super(key: key);

  @override
  State<DesktopVisualEditor> createState() => _DesktopVisualEditorState();
}

const double componentTreeWidth = 240.0;

class _DesktopVisualEditorState extends State<DesktopVisualEditor> with OverlayManager {
  final CustomMenuController _menuController = CustomMenuController();
  final GlobalKey _pasteButton = GlobalKey(), _selectionButton = GlobalKey(), _navigationButton = GlobalKey();
  final UserSession _userSession = sl();
  final _pref = sl<SharedPreferences>();
  final AnimatedSlider _animatedSlider = AnimatedSlider();

  late final AppMenu menu;

  @override
  void initState() {
    clipboardProvider.addListener(() {
      if (!_animatedSlider.visible) {
        _showClipboard();
      }
    });
    menu = AppMenu([
      SubMenu(
          'Project',
          [
            AppMenuItem('Back to Home', (context) {
              _pref.remove(PrefKey.projectId);
              Navigator.of(context, rootNavigator: true)
                  .pushReplacementNamed('/projects', arguments: _userSession.user.userId);
            }),
            if (_userSession.settingModel?.projects.isNotEmpty ?? false)
              SubMenu('Open', [
                for (final project in _userSession.settingModel!.projects)
                  if (project.id != collection.project?.id)
                    AppMenuItem(project.name, (context) {
                      context.read<UserDetailsCubit>().loadProject(
                            project.id,
                            userId: project.userId,
                            name: project.name,
                          );
                    })
              ]),
            AppMenuItem('Preview', (context) {
              if (_collection.project!.screens.isEmpty) {
                showConfirmDialog(
                  title: 'Alert!',
                  subtitle: 'Nothing to preview',
                  context: context,
                  positive: 'ok',
                );
              } else {
                Navigator.of(context).push(getRoute(
                    (p0) => PreviewPage(
                          BlocProvider.of<OperationCubit>(context, listen: false),
                        ),
                    '/projects/${_collection.project!.name}/preview'));
              }
            }),
            AppMenuItem('Create Screen', (context) {
              showScreenCreationDialog(context);
            }),
            AppMenuItem('Settings', (context) {
              AnimatedDialog.show(context, const GeneralSettingsPage());
            }),
            AppMenuItem('Files', (context) {
              AnimatedDialog.show(
                context,
                const FilesView(),
              );
            }),
            AppMenuItem('Apis', (context) {
              AnimatedDialog.show(context, const Dialog(child: ApiView()));
            }),
            AppMenuItem('Firebase', (context) {
              AnimatedDialog.show(context, const Dialog(child: FirebaseConnectDialog()));
            }),
          ],
          root: true),
      SubMenu(
          'Edit',
          [
            AppMenuItem('Undo', (context) {
              if (context.read<OperationCubit>().revertWork.totalOperations > 0) {
                context.read<OperationCubit>().revertWork.undo();
              }
            }, icon: Icons.undo),
          ],
          root: true),
      SubMenu(
          'Other',
          [
            AppMenuItem('Json to Dart (Serializable)', (context) {
              AnimatedDialog.show(
                  context,
                  const Dialog(
                    child: JsonToDartConversionWidget(),
                  ));
            }),
            AppMenuItem('Firestore DB assistant', (context) {
              AnimatedDialog.show(
                  context,
                  const Dialog(
                    child: FirestoreAssistantTool(),
                  ));
            })
          ],
          root: true),
      AppMenuItem(
        'Feedback',
        (context) => _openFeedbackForm(),
      )
    ]);
    super.initState();
  }

  @override
  void dispose() {
    destroyOverlays();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final treeWidthPercent = (componentTreeWidth + 40) / MediaQuery.of(context).size.width;

    return BlocBuilder<UserDetailsCubit, UserDetailsState>(
      buildWhen: (_, current) =>
          current is ProjectLoadingState ||
          current is FlutterProjectLoadedState ||
          current is ProjectUpdateSuccessState,
      builder: (context, state) {
        if (_collection.project == null) {
          return const Offstage();
        }
        const tree = const ComponentTree();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.background1,
              ),
              child: Row(
                children: [
                  5.wBox,
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: ColorAssets.theme,
                      child: Center(
                        child: AppImage(
                          Images.logo,
                          width: 28,
                          fit: BoxFit.contain,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  10.wBox,
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 100,
                    ),
                    height: 30,
                    decoration: BoxDecoration(
                      color: ColorAssets.theme,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            _collection.project!.name,
                            style: AppFontStyle.lato(
                              13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        BlocBuilder<OperationCubit, OperationState>(
                          builder: (context, state) {
                            if (state is ComponentOperationLoadingState) {
                              return const Icon(
                                Icons.cloud_upload,
                                color: Colors.white,
                                size: 18,
                              );
                            } else if (state is ComponentOperationErrorState) {
                              if (state.type != ErrorType.network) {
                                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                  showConfirmDialog(
                                    context: context,
                                    title: 'Error',
                                    subtitle: state.msg,
                                    positive: 'ok',
                                  );
                                });
                                return const Icon(
                                  Icons.error,
                                  color: Colors.white,
                                  size: 18,
                                );
                              }
                              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                showNoNetworkDialog(context);
                              });
                              return InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(10),
                                child: const Icon(
                                  Icons.cloud_off_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              );
                            }
                            return const Icon(
                              Icons.cloud_done,
                              color: Colors.white,
                              size: 18,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  20.wBox,
                  CustomMenuBar(
                      style: CustomMenuStyle(
                          elevation: WidgetStateProperty.all(0),
                          alignment: Alignment.center,
                          backgroundColor: WidgetStatePropertyAll(theme.background1)),
                      controller: _menuController,
                      children: menu.list.map((e) => e.build(context)).toList()),
                ],
              ),
            ),
            const Divider(
              height: 0,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    color: ColorAssets.colorE5E5E5,
                    padding: const EdgeInsets.only(left: componentTreeWidth),
                    child: const Row(
                      children: [
                        Expanded(
                          child: CenterMainSide(),
                        ),
                        SizedBox(
                          width: 320,
                          child: ComponentPropertySection(),
                        ),
                      ],
                    ),
                  ),
                  ResizableWidget(
                    percentages: [treeWidthPercent, 1 - treeWidthPercent],
                    separatorSize: Dimen.separator,
                    separatorColor: ColorAssets.separator,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: tree,
                          ),
                          SizedBox(
                            width: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // const ControlsWidget(),
                                10.hBox,
                                AppIconButton(
                                  key: _selectionButton,
                                  icon: Icons.widgets_rounded,
                                  onPressed: () {
                                    if (_animatedSlider.visible) {
                                      _animatedSlider.hide();
                                    } else {
                                      _showSelectionDialog();
                                    }
                                  },
                                ),
                                10.hBox,
                                AppIconButton(
                                  key: _pasteButton,
                                  icon: Icons.paste_rounded,
                                  onPressed: () {
                                    if (_animatedSlider.visible) {
                                      _animatedSlider.hide();
                                    } else {
                                      _showClipboard();
                                    }
                                  },
                                ),
                                10.hBox,

                                AppIconButton(
                                  key: _navigationButton,
                                  icon: Icons.app_settings_alt,
                                  onPressed: () {
                                    if (_animatedSlider.visible) {
                                      _animatedSlider.hide();
                                    } else {
                                      _showNavigation();
                                    }
                                  },
                                ),
                                // const Align(
                                //   alignment: Alignment.topLeft,
                                //   child: ComponentSelectionSlider(),
                                // ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const Offstage()
                    ],
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClipboard() {
    _animatedSlider.show(
      context,
      this,
      const ClipboardComponentWidget(),
      _pasteButton,
    );
  }

  void _showSelectionDialog() {
    _animatedSlider.show(
        context,
        this,
        SizedBox(
          width: kSelectionDialogWidth,
          height: dh(context, 100) - 80,
          child: ComponentSelectionDialog(
            onBack: () => _animatedSlider.hide(),
            sideView: true,
          ),
        ),
        _selectionButton,
        width: kSelectionDialogWidth);
  }

  void _showNavigation() {
    _animatedSlider.show(
      context,
      this,
      Container(
        decoration: BoxDecoration(
          color: theme.background1,
          borderRadius: BorderRadius.circular(4),
          boxShadow: kElevationToShadow[1],
        ),
        padding: const EdgeInsets.all(12),
        width: 150,
        height: dh(context, 100) - 50,
        child: const Column(
          children: [
            NavigationSettingsView(),
            Expanded(
              child: ControlsView(),
            ),
          ],
        ),
      ),
      _pasteButton,
    );
  }

  void _openFeedbackForm() {
    AnimatedDialog.show(
      context,
      const FeedbackDialog(),
    );
  }
}

class ComponentPropertySection extends StatefulWidget {
  const ComponentPropertySection({Key? key}) : super(key: key);

  @override
  State<ComponentPropertySection> createState() => _ComponentPropertySectionState();
}

class _ComponentPropertySectionState extends State<ComponentPropertySection> {
  late final OperationCubit _componentOperationCubit;

  late final SelectionCubit _componentSelectionCubit;

  @override
  void initState() {
    super.initState();
    _componentSelectionCubit = context.read<SelectionCubit>();
    _componentOperationCubit = context.read<OperationCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: theme.background1,
          border: Border(
              left: BorderSide(
            color: theme.border1,
          ))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<SelectionCubit, SelectionState>(
            buildWhen: (state1, state2) {
              if (state2 is SelectionChangeState &&
                  (state1 is! SelectionChangeState || (state1).model != (state2).model)) {
                return true;
              }
              return false;
            },
            builder: (_, state) {
              final component = _componentSelectionCubit.selected.propertySelection;
              if (component is CNotRecognizedWidget) {
                return const Offstage();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: Responsive.isDesktop(context) ? const EdgeInsets.all(10) : const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          StringOperation.toNormalCase(component.name).truncateAfter(),
                          style: AppFontStyle.lato(16, fontWeight: FontWeight.bold),
                        ),
                        if (component is CustomComponent) ...[
                          CustomWidgetTypeIndicator(component: component),
                        ],
                        const SizedBox(
                          width: 6,
                        ),
                        Expanded(
                          child: Tooltip(
                            message: component.id,
                            child: InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: component.id));
                                showPopupText(context, 'Copied!');
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      component.id,
                                      style:
                                          AppFontStyle.lato(13, color: theme.text3Color, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Icon(
                                    Icons.copy,
                                    color: theme.text3Color,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Divider(
                    thickness: 0.3,
                    color: Colors.grey.shade400,
                    height: 0,
                  ),
                  // if (component is BuilderComponent)
                  //   BuilderComponentSettings(
                  //     component: component as BuilderComponent,
                  //   ),
                ],
              );
            },
          ),
          Expanded(
            child: BlocListener<CreationCubit, CreationState>(
              listener: (context, state) {
                if (state is ComponentCreationChangeState) {
                  if (state.ancestor != null) {
                    print('Updating custom ${state.ancestor?.name}');
                    _componentOperationCubit.updateGlobalCustomComponent(state.ancestor!);
                  } else if (_componentSelectionCubit.currentSelectedRoot is CustomComponent) {
                    print('Updating custom ${_componentSelectionCubit.currentSelectedRoot}');
                    _componentOperationCubit
                        .updateGlobalCustomComponent(_componentSelectionCubit.currentSelectedRoot as CustomComponent);
                  } else if (_componentSelectionCubit.selected.viewable != null) {
                    if (_componentSelectionCubit.selected.viewable is Screen) {
                      print('Updating screen ${_componentSelectionCubit.selected.viewable?.name}');
                      _componentOperationCubit.updateRootComponent(_componentSelectionCubit.selected.viewable!);
                    } else {
                      _componentOperationCubit.updateProjectRootComponent(_collection.project!);
                    }
                  }
                }
              },
              child: Responsive(
                tablet: const PropertyPortion(),
                mobile: const PropertyPortion(),
                desktop: LayoutBuilder(builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: (constraints.maxHeight * 0.2) + 10),
                          child: const PropertyPortion(),
                        ),
                      ),
                      Positioned.fill(
                        child: ResizableWidget(
                          percentages: const [0.8, 0.2],
                          isHorizontalSeparator: true,
                          separatorSize: 2,
                          separatorColor: ColorAssets.separator,
                          children: const [
                            Offstage(),
                            ConsoleWidget(
                              mode: RuntimeMode.edit,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom,
          ),
        ],
      ),
    );
  }
}

class RightSidePortion extends StatefulWidget {
  const RightSidePortion({Key? key}) : super(key: key);

  @override
  State<RightSidePortion> createState() => _RightSidePortionState();
}

class _RightSidePortionState extends State<RightSidePortion> {
  final RightSideBloc _rightSideBloc = RightSideBloc();
  final rightSideList = RightSide.values;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SelectionCubit, SelectionState>(
      listenWhen: (state1, state2) {
        if (state1 is! SelectionChangeState || state2 is! SelectionChangeState) {
          return true;
        }
        return state1.model != state2.model;
      },
      listener: (context, state) {
        if (state is SelectionChangeState) {
          _rightSideBloc.add(RightSideUpdateEvent(RightSide.property));
        }
      },
      child: BlocBuilder<RightSideBloc, RightSideState>(
        bloc: _rightSideBloc,
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.border1,
                  ),
                ),
                color: theme.background1),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.all(6),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runAlignment: WrapAlignment.start,
                    runSpacing: 6,
                    spacing: 6,
                    children: rightSideList.asMap().entries.map((side) {
                      final index = side.key;
                      final selected = rightSideList[index] == _rightSideBloc.rightSide;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          _rightSideBloc.add(RightSideUpdateEvent(side.value));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: selected ? ColorAssets.theme : theme.background1,
                              border: Border.all(color: !selected ? theme.border1 : Colors.transparent)),
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                rightSideList[index].icon,
                                size: 18,
                                color: selected ? ColorAssets.white : ColorAssets.color72788AGrey,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                rightSideList[index].name,
                                style: AppFontStyle.lato(
                                  14,
                                  fontWeight: FontWeight.w500,
                                  color: selected ? ColorAssets.white : ColorAssets.color72788AGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Expanded(
                  child: IndexedStack(
                    clipBehavior: Clip.none,
                    index: _rightSideBloc.rightSide.index,
                    children: const [
                      ComponentPropertySection(),

                      // ApiView(),
                      // FilesView()
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProjectVariableBox extends StatelessWidget {
  const ProjectVariableBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final operationCubit = sl<OperationCubit>();
    final creationCubit = sl<CreationCubit>();
    final selectionCubit = sl<SelectionCubit>();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          blurRadius: 8,
        )
      ]),
      width: 360,
      child: BlocBuilder<UserDetailsCubit, UserDetailsState>(
        buildWhen: (state1, state2) => state2 is FlutterProjectLoadedState,
        builder: (context, state) {
          return VariableBox(
            options: [
              for (final screen in operationCubit.project!.screens)
                VariableDialogOption('copy to screen ${screen.name} variables', (p0) {
                  screen.variables[p0.name] = p0.clone();
                  // componentOperationCubit.project!.variables.remove(p0.name);
                  creationCubit.changedComponent();
                }),
              for (final customComponent in operationCubit.project!.customComponents)
                VariableDialogOption('copy to custom widget ${customComponent.name} variables', (p0) {
                  customComponent.variables[p0.name] = p0.clone();
                  creationCubit.changedComponent(ancestor: customComponent);
                })
            ],
            variables: _collection.project!.variables,
            componentOperationCubit: operationCubit,
            componentCreationCubit: creationCubit,
            title: 'main.dart',
            onAdded: (model) {
              operationCubit.project!.variables[model.name] = model;
              operationCubit.addVariable(model as VariableModel);
              creationCubit.changedComponent();
              selectionCubit.refresh();
            },
            onChanged: (model) {
              _collection.project!.variables[model.name]!.setValue(_collection.project!.processor, model.value);
              Future.delayed(const Duration(milliseconds: 500), () {
                operationCubit.updateVariable();
                creationCubit.changedComponent();
                selectionCubit.refresh();
              });
            },
            componentSelectionCubit: selectionCubit,
            onDeleted: (FVBVariable model) {
              operationCubit.project!.variables.remove(model.name);
              operationCubit.updateVariable();
              creationCubit.changedComponent();
              selectionCubit.refresh();
            },
          );
        },
      ),
    );
  }
}

class PropertyPortion extends StatefulWidget {
  const PropertyPortion({Key? key}) : super(key: key);

  @override
  State<PropertyPortion> createState() => _PropertyPortionState();
}

final ActionEditCubit _actionEdit = ActionEditCubit();

class _PropertyPortionState extends State<PropertyPortion> with GetProcessor {
  final ScrollController _propertyScrollController = ScrollController();
  late final OperationCubit _operationCubit;

  late final SelectionCubit _selectionCubit;
  late final StateManagementBloc _stateBloc;
  final TextEditingController _searchController = TextEditingController();
  final _searchDebounce = Debounce(const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    _selectionCubit = BlocProvider.of<SelectionCubit>(context);
    _operationCubit = BlocProvider.of<OperationCubit>(context);
    _stateBloc = context.read<StateManagementBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: BlocListener<ParameterBuildCubit, ParameterBuildState>(
        listener: (context, state) {
          if (state is ParameterChangeState) {
            if (state.refresh) {
              for (final selected
                  in (state.component != null ? [state.component!] : _selectionCubit.selected.visualSelection)) {
                _stateBloc.add(StateManagementUpdateEvent(
                  selected,
                  RuntimeMode.edit,
                ));
                if (state.parameter is UsableParam && (state.parameter as UsableParam).usableName != null) {
                  _operationCubit.project!.commonParams
                      .firstWhereOrNull((element) => element.name == (state.parameter as UsableParam).usableName)
                      ?.connected
                      .forEach((element) {
                    if (element != selected.id) {
                      _stateBloc.add(StateManagementUpdateEvent(element, RuntimeMode.edit));
                    }
                  });
                }
              }
            }
          }

          if (state is ParameterChangeState || state is ParameterAlteredState) {
            _operationCubit.updateRootOnFirestore();
          }
        },
        child: BlocConsumer<SelectionCubit, SelectionState>(
          listener: (context, state) {
            if (state is SelectionChangeState && state.parameter != null) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                if (GlobalObjectKey(state.parameter!).currentContext != null) {
                  Scrollable.ensureVisible(GlobalObjectKey(state.parameter!).currentContext!);
                }
              });
            }
          },
          buildWhen: (state1, state2) {
            if (state2 is SelectionChangeState && (state1 is! SelectionChangeState || state1.model != state2.model)) {
              return true;
            }
            return false;
          },
          builder: (context, state) {
            final processor = needfulProcessor(_selectionCubit);
            final parameters = [
              ..._selectionCubit.selected.propertySelection.defaultParam.whereType<Parameter>(),
              ..._selectionCubit.selected.propertySelection.parameters
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              key: ObjectKey(_selectionCubit.selected),
              children: [
                if (_selectionCubit.selected.propertySelection == kNullWidget)
                  const Expanded(
                      child: EmptyTextIconWidget(
                    text: 'No component selected',
                    icon: Icons.widgets_rounded,
                  ))
                else
                  Expanded(
                    child: ListView(
                      padding: isDesktop ? const EdgeInsets.all(10) : const EdgeInsets.all(8),
                      controller: _propertyScrollController,
                      children: [
                        SizedBox(
                          height: 35,
                          child: AppSearchField(
                            hint: 'Search parameter..',
                            onChanged: (value) {
                              _searchDebounce.run(() {
                                _searchController.text = value;
                              });
                            },
                          ),
                        ),
                        8.hBox,
                        if (_selectionCubit.selected.intendedSelection is FVBPainter)
                          BlocBuilder<PaintObjBloc, PaintObjState>(
                            buildWhen: (state1, state2) => state2 is PaintObjSelectionUpdatedState,
                            builder: (context, state) {
                              if (context.read<PaintObjBloc>().paintObj != null) {
                                return PaintParameterSection(
                                  processor: processor,
                                  obj: context.read<PaintObjBloc>().paintObj!,
                                );
                              }
                              return const Offstage();
                            },
                          ),

                        ProcessorProvider(
                          processor: processor,
                          child: ListenableBuilder(
                              listenable: _searchController,
                              builder: (context, _) {
                                final List<Parameter> params;
                                if (_searchController.text.isEmpty) {
                                  params = parameters;
                                } else {
                                  params = _filterParameters((_searchController.text, parameters));
                                }
                                return Column(
                                  children: [
                                    Visibility(
                                        visible: _searchController.text.isEmpty,
                                        child: Column(
                                          children: [
                                            if (_selectionCubit.selected.propertySelection is Clickable)
                                              BlocProvider<ActionEditCubit>.value(
                                                value: _actionEdit,
                                                child: BlocListener<ActionEditCubit, ActionEditState>(
                                                  listener: (context, state) {
                                                    if (state is ActionChangeState) {
                                                      if (_selectionCubit.currentSelectedRoot is CustomComponent) {
                                                        _operationCubit.updateGlobalCustomComponent(
                                                            _selectionCubit.currentSelectedRoot as CustomComponent);
                                                      } else if (_selectionCubit.selected.viewable != null) {
                                                        _operationCubit
                                                            .updateRootComponent(_selectionCubit.selected.viewable!);
                                                      }
                                                    }
                                                  },
                                                  child: ActionModelWidget(
                                                    clickable: _selectionCubit.selected.propertySelection as Clickable,
                                                  ),
                                                ),
                                              ),
                                            if (_selectionCubit.selected.intendedSelection is Controller)
                                              ControllerListingWidget(
                                                controller: _selectionCubit.selected.intendedSelection as Controller,
                                              ),
                                            if (_selectionCubit.selected.intendedSelection is CustomComponent)
                                              CustomComponentProperty(
                                                component:
                                                    _selectionCubit.selected.intendedSelection as CustomComponent,
                                              ),
                                          ],
                                        )),
                                    Wrap(
                                      runSpacing: 5,
                                      children: [
                                        for (final param in parameters)
                                          Visibility(
                                            visible: _searchController.text.isEmpty || params.contains(param),
                                            child: ParameterWidget(
                                              parameter: param,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                        )
                        // if (!Responsive.isLargeScreen(context) &&
                        //     MediaQuery.of(context).viewInsets.bottom > 0)
                        //   SizedBox(
                        //     height: MediaQuery.of(context).viewInsets.bottom,
                        //   )
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: EvaluateExpression(
                    processor: processor,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<Parameter> _filterParameters((String, List<Parameter>) message) {
  final List<Parameter> filtered = [];
  final search = message.$1.toLowerCase();
  message.$2.forEach((p0) {
    if ((p0.displayName?.toLowerCase().startsWith(search) ?? false) ||
        (p0.info.getName()?.toLowerCase().startsWith(search) ?? false)) {
      filtered.add(p0);
    }
  });
  return filtered;
}

class ComponentSelectionSlider extends StatefulWidget {
  const ComponentSelectionSlider({Key? key}) : super(key: key);

  @override
  State<ComponentSelectionSlider> createState() => _ComponentSelectionSliderState();
}

class _ComponentSelectionSliderState extends State<ComponentSelectionSlider> {
  final ValueNotifier<bool> expand = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: expand,
        builder: (context, value, _) {
          return Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: () {
                    expand.value = !expand.value;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: theme.background1, shape: BoxShape.circle, boxShadow: kElevationToShadow[1]),
                    child: Icon(
                      expand.value ? Icons.arrow_back_ios : Icons.widgets_outlined,
                      size: 20,
                      color: theme.iconColor1,
                    ),
                  ),
                ),
              )
            ],
          );
        });
  }
}

Component? getSearchRoot(OperationCubit _componentOperationCubit, Viewable screen) {
  if (fvbNavigationBloc.model.dialog) {
    return fvbNavigationBloc.model.dialogComp?.rootComponent;
  }
  if (fvbNavigationBloc.model.bottomSheet) {
    return fvbNavigationBloc.model.bottomComp?.rootComponent;
  }
  if (fvbNavigationBloc.model.drawer) {
    return fvbNavigationBloc.getDrawerComponent(screen) ?? screen.rootComponent;
  }
  if (fvbNavigationBloc.model.endDrawer) {
    return fvbNavigationBloc.getEndDrawerComponent(screen) ?? screen.rootComponent;
  } else {
    return screen.rootComponent;
  }
}

Component? setSearchRoot(OperationCubit _componentOperationCubit, Viewable screen, Component? root) {
  if (fvbNavigationBloc.model.dialog) {
    return fvbNavigationBloc.model.dialogComp!.rootComponent = root;
  }
  if (fvbNavigationBloc.model.bottomSheet) {
    return fvbNavigationBloc.model.bottomComp!.rootComponent = root;
  }
  if (fvbNavigationBloc.model.drawer) {
    fvbNavigationBloc.setDrawerComponent(root, screen);
    return root;
  } else if (fvbNavigationBloc.model.endDrawer) {
    fvbNavigationBloc.setEndDrawerComponent(root, screen);
    return root;
  } else {
    return screen.rootComponent = root;
  }
}

class MouseKeyActivator extends ShortcutActivator {
  final bool down;

  const MouseKeyActivator(this.down);

  @override
  String debugDescribeKeys() {
    return 'Control pressed';
  }

  @override
  Iterable<LogicalKeyboardKey>? get triggers => [LogicalKeyboardKey.control];

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    if (state.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft)) {
      return true;
    }
    return false;
  }
}

class AppMenu {
  final List<AppMenuItem> list;

  AppMenu(this.list);
}

class SubMenu extends AppMenuItem {
  final List<AppMenuItem> list;
  final bool root;

  SubMenu(String title, this.list, {this.root = false}) : super(title, null);

  @override
  Widget build(BuildContext context) {
    return CustomSubmenuButton(
      closeOnOutsideClick: root,
      style: ButtonStyle(alignment: Alignment.center, backgroundColor: WidgetStatePropertyAll(theme.background1)),
      menuChildren: list.map((e) => e.build(context)).toList(),
      child: Text(
        '$title',
        style: AppFontStyle.lato(14, fontWeight: FontWeight.w500, color: theme.text1Color),
      ),
    );
  }
}

class AppMenuItem {
  final IconData? icon;
  final String title;
  final Function(BuildContext context)? onTap;

  AppMenuItem(this.title, this.onTap, {this.icon});

  Widget build(BuildContext context) {
    return CustomMenuItemButton(
      style: ButtonStyle(alignment: Alignment.center, backgroundColor: WidgetStatePropertyAll(theme.background1)),
      // shortcut: const SingleActivator(LogicalKeyboardKey.keyF,control: true),
      child: Text(
        title,
        style: AppFontStyle.lato(
          14,
          fontWeight: FontWeight.w500,
          color: theme.text1Color,
        ),
      ),
      focusNode: FocusNode()..requestFocus(),
      onPressed: () => onTap?.call(context),
    );
  }
}

class PosOffset extends Positioned {
  final Offset offset;

  PosOffset({Key? key, required Widget child, required this.offset})
      : super(key: key, left: offset.dx, top: offset.dy, child: child);
}

class CustomWidgetTypeIndicator extends StatelessWidget {
  final Component component;

  const CustomWidgetTypeIndicator({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        color: ColorAssets.theme,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        component is StatefulComponent ? 'Stateful' : 'Stateless',
        style: AppFontStyle.lato(12, color: Colors.white),
      ),
    );
  }
}
