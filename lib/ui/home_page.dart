import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_builder/common/html_lib.dart' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:resizable_widget/resizable_widget.dart';

import '../common/app_loader.dart';
import '../common/common_methods.dart';
import '../common/context_popup.dart';
import '../common/custom_animated_dialog.dart';
import '../common/custom_drop_down.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/dialog_selection.dart';
import '../common/logger.dart';
import '../common/material_alert.dart';
import '../common/responsive/responsive_widget.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/action_edit/action_edit_cubit.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/flutter_project/flutter_project_cubit.dart';
import '../cubit/parameter_build_cubit/parameter_build_cubit.dart';
import '../cubit/screen_config/screen_config_cubit.dart';
import '../cubit/stack_action/stack_action_cubit.dart';
import '../cubit/visual_box_drawer/visual_box_cubit.dart';
import '../firestore/firestore_bridge.dart';
import '../injector.dart';
import '../main.dart';
import '../models/builder_component.dart';
import '../models/component_model.dart';
import '../models/component_selection.dart';
import '../models/variable_model.dart';
import '../runtime_provider.dart';
import '../screen_model.dart';
import 'action_code_editor.dart';
import 'action_widgets.dart';
import 'boundary_widget.dart';
import 'build_view/build_view.dart';
import 'code_view_widget.dart';
import 'common/action_code_dialog.dart';
import 'common/variable_dialog.dart';
import 'component_selection_dialog.dart';
import 'component_tree.dart';
import 'emulation_view.dart';
import 'models_view.dart';
import 'parameter_ui.dart';
import 'preview_ui.dart';
import 'variable_ui.dart';

class HomePage extends StatefulWidget {
  final String projectName;
  final int userId;
  final bool runMode;

  const HomePage(
      {Key? key,
      required this.projectName,
      required this.userId,
      this.runMode = false})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static StreamSubscription? _streamSubscription;
  final ScrollController propertyScrollController = ScrollController();
  late ComponentCreationCubit componentCreationCubit;
  late ComponentOperationCubit componentOperationCubit;
  late final FlutterProjectCubit flutterProjectCubit;
  final ParameterBuildCubit _parameterBuildCubit = ParameterBuildCubit();
  final visualBoxCubit = VisualBoxCubit();
  final screenConfigCubit = ScreenConfigCubit();
  final ComponentSelectionCubit componentSelectionCubit =
      ComponentSelectionCubit();

  @override
  void initState() {
    super.initState();
    componentOperationCubit = get<ComponentOperationCubit>();
    componentCreationCubit = get<ComponentCreationCubit>();
    flutterProjectCubit = context.read<FlutterProjectCubit>();
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
    }
    if (kIsWeb) {
      _streamSubscription = html.window.onKeyDown.listen((event) {
        if (event.altKey &&
            componentOperationCubit.flutterProject?.rootComponent != null) {
          event.preventDefault();
          if (event.key == 'f') {
            componentOperationCubit.toggleFavourites(
                componentSelectionCubit.currentSelected.propertySelection);
          } else if (event.key == 'v') {
            if (componentOperationCubit.runtimeMode == RuntimeMode.edit) {
              // showModelDialog(
              //     context,
              //     BuildView(
              //       onDismiss: () {
              //         componentCreationCubit.changedComponent();
              //       },
              //       componentOperationCubit: componentOperationCubit,
              //       screenConfigCubit: screenConfigCubit,
              //     )).then((value) {
              //   screenConfigCubit.applyCurrentSizeToVariables();
              // });
            } else if (componentOperationCubit.runtimeMode == RuntimeMode.run) {
              // Navigator.pop(context);
              // componentOperationCubit.runtimeMode = RuntimeMode.edit;
              // componentCreationCubit.changedComponent();
            }
          }
        }
      });
      if (kIsWeb) {
        html.window.onResize.listen((event) {
          if (mounted) {
            componentCreationCubit.changedComponent();
          }
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      AppLoader.show(context);
    });
    FireBridge.init().then((value) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        flutterProjectCubit.loadFlutterProject(componentSelectionCubit,
            componentOperationCubit, widget.projectName, widget.runMode,
            userId: widget.userId);
      });
    });
  }

  void showSelectionDialog(
      BuildContext context, void Function(Component) onSelection,
      {List<String>? possibleItems}) {
    showModelDialog(
      context,
      ComponentSelectionDialog(
        possibleItems: possibleItems,
        onSelection: onSelection,
        componentOperationCubit: componentOperationCubit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ComponentSelectionCubit>(
                create: (context) => componentSelectionCubit),
            BlocProvider<ScreenConfigCubit>(
                create: (context) => screenConfigCubit),
            BlocProvider<VisualBoxCubit>(create: (_) => visualBoxCubit),
            BlocProvider<ParameterBuildCubit>(
                create: (context) => _parameterBuildCubit),
          ],
          child: BlocConsumer<FlutterProjectCubit, FlutterProjectState>(
            buildWhen: (state1, state2) {
              if (state2 is FlutterProjectLoadingState) {
                return false;
              }
              return true;
            },
            listener: (context, state) {
              switch (state.runtimeType) {
                case FlutterProjectLoadingState:
                  AppLoader.show(context,
                      loadingMode: LoadingMode.projectLoadingMode);
                  break;
                case FlutterProjectLoadingErrorState:
                  AppLoader.hide();
                  showFlutterErrorDialog(
                      (state as FlutterProjectLoadingErrorState).model);
                  break;
                case FlutterProjectErrorState:
                  AppLoader.hide();
                  Fluttertoast.showToast(
                      msg: (state as FlutterProjectErrorState).message ??
                          'Something went wrong',
                      timeInSecForIosWeb: 3);
                  break;
                case FlutterProjectLoadedState:
                  AppLoader.hide();
                  componentSelectionCubit.init(
                      ComponentSelectionModel.unique(
                          (state as FlutterProjectLoadedState)
                              .flutterProject
                              .rootComponent!),
                      state.flutterProject.rootComponent!);
                  if (componentOperationCubit.flutterProject!.device != null) {
                    final config = screenConfigCubit.screenConfigs
                        .firstWhereOrNull((element) =>
                            element.name ==
                            componentOperationCubit.flutterProject!.device);
                    if (config != null) {
                      screenConfigCubit.changeScreenConfig(config);
                    }
                  }
                  break;
              }
            },
            builder: (context, state) {
              if (componentOperationCubit.flutterProject == null) {
                return Container();
              }
              if (widget.runMode) {
                return const PrototypeShowcase();
              }
              return const Responsive(
                largeScreen: DesktopVisualEditor(),
                mediumScreen: DesktopVisualEditor(),
                smallScreen: PrototypeShowcase(),
              );
            },
          ),
        ),
      ),
    );
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
    showModelDialog(
      context,
      MaterialAlertDialog(
        title: title,
        subtitle: message,
        positiveButtonText: 'OK',
        onPositiveTap: () {
          Navigator.pop(context);
        },
      ),
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
}

class ScreenConfigSelection extends StatelessWidget {
  final ScreenConfigCubit? screenConfigCubit;
  final ComponentOperationCubit? componentOperationCubit;

  const ScreenConfigSelection(
      {Key? key, this.screenConfigCubit, this.componentOperationCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = screenConfigCubit ??
        BlocProvider.of<ScreenConfigCubit>(context, listen: false);

    return BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
      bloc: cubit,
      builder: (context, state) {
        return SizedBox(
          width: 250,
          height: 45,
          child: CustomDropdownButton<ScreenConfig>(
              style: AppFontStyle.roboto(13),
              value: cubit.screenConfig,
              hint: null,
              items: cubit.screenConfigs
                  .map<CustomDropdownMenuItem<ScreenConfig>>(
                    (e) => CustomDropdownMenuItem<ScreenConfig>(
                      value: e,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${e.name} (${e.width}x${e.height})',
                          style: AppFontStyle.roboto(13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != cubit.screenConfig) {
                  cubit.changeScreenConfig(value);
                  (componentOperationCubit ??
                          BlocProvider.of<ComponentOperationCubit>(context,
                              listen: false))
                      .updateDeviceSelection(value.name);
                }
              },
              selectedItemBuilder: (context, config) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${config.name} (${config.width}x${config.height})',
                    style: AppFontStyle.roboto(13, fontWeight: FontWeight.w500),
                  ),
                );
              }),
        );
      },
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          highlightColor: Colors.blueAccent.shade200,
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            CustomDialog.show(
              context,
              CodeViewerWidget(
                componentOperationCubit:
                    BlocProvider.of<ComponentOperationCubit>(context,
                        listen: false),
              ),
            );
          },
          child: Container(
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: kElevationToShadow[1],
              color: Colors.blueAccent,
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.code,
                  color: Colors.white,
                  size: 16,
                ),
                const Spacer(),
                Text(
                  'Code',
                  style: AppFontStyle.roboto(13, color: Colors.white),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        InkWell(
          highlightColor: Colors.blueAccent.shade200,
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            showModelDialog(
              context,
              BuildView(
                onDismiss: () {
                  BlocProvider.of<ComponentCreationCubit>(context,
                          listen: false)
                      .changedComponent();
                },
                componentOperationCubit:
                    BlocProvider.of<ComponentOperationCubit>(context,
                        listen: false),
                screenConfigCubit:
                    BlocProvider.of<ScreenConfigCubit>(context, listen: false),
              ),
            ).then((value) {
              BlocProvider.of<ScreenConfigCubit>(context, listen: false)
                  .applyCurrentSizeToVariables();
            });
          },
          child: Container(
            width: 80,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.shade500,
              borderRadius: BorderRadius.circular(10),
              boxShadow: kElevationToShadow[1],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
                const Spacer(),
                Text(
                  'Run',
                  style: AppFontStyle.roboto(13, color: Colors.white),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        InkWell(
          highlightColor: Colors.blue.shade200,
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(context).push(getRoute(
                (p0) => PreviewPage(
                    BlocProvider.of<ComponentOperationCubit>(context,
                        listen: false),
                    BlocProvider.of<ScreenConfigCubit>(context, listen: false)),
                '/projects/${ComponentOperationCubit.currentFlutterProject!.name}/preview'));
          },
          child: Container(
            width: 80,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: kElevationToShadow[1],
                color: Colors.deepPurpleAccent.shade400),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.preview,
                  color: Colors.white,
                  size: 16,
                ),
                const Spacer(),
                Text(
                  'Preview',
                  style: AppFontStyle.roboto(13, color: Colors.white),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        const VariableShowHideMenu(),
        const ModelShowHideMenu(),
        const ActionCodeShowHideMenu()
      ],
    );
  }
}

class VariableShowHideMenu extends StatefulWidget {
  const VariableShowHideMenu({Key? key}) : super(key: key);

  @override
  State<VariableShowHideMenu> createState() => _VariableShowHideMenuState();
}

class _VariableShowHideMenuState extends State<VariableShowHideMenu> {
  late VariableDialog _variableDialog;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final componentOperationCubit = context.read<ComponentOperationCubit>();
        final componentCreationCubit = context.read<ComponentCreationCubit>();
        final componentSelectionCubit = context.read<ComponentSelectionCubit>();
        _variableDialog = VariableDialog(
            variables:  ComponentOperationCubit
                .currentFlutterProject!.variables,
            componentOperationCubit: componentOperationCubit,
            componentCreationCubit: componentCreationCubit,
            title: ComponentOperationCubit
                .currentFlutterProject!.currentScreen.name,
            onAdded: (model) {
              ComponentOperationCubit.currentFlutterProject!.variables[model.name] =
                  model;
              componentOperationCubit.addVariable(
                  ComponentOperationCubit.currentFlutterProject!.variables[model.name]!);
              componentCreationCubit.changedComponent();
              componentSelectionCubit.emit(ComponentSelectionChange());
            },
            onEdited: (model) {
              ComponentOperationCubit
                  .currentFlutterProject!.variables[model.name]!.value = model.value;
              Future.delayed(const Duration(milliseconds: 500), () {
                componentOperationCubit.updateVariable( ComponentOperationCubit
                    .currentFlutterProject!.variables[model.name]!);
                componentCreationCubit.changedComponent();
                componentSelectionCubit.emit(ComponentSelectionChange());
              });
            },
            componentSelectionCubit: componentSelectionCubit,
            onDeleted: (VariableModel model) {
              ComponentOperationCubit.currentFlutterProject!.variables.remove(model);
              componentCreationCubit.changedComponent();
              componentSelectionCubit.emit(ComponentSelectionChange());
            });
        _variableDialog.show(context);
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: kElevationToShadow[1]),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            const Icon(
              Icons.data_array,
              color: Colors.black,
              size: 18,
            ),
            const Spacer(),
            Text(
              'Variables',
              style: AppFontStyle.roboto(13,
                  color: Colors.black, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class ModelShowHideMenu extends StatefulWidget {
  const ModelShowHideMenu({Key? key}) : super(key: key);

  @override
  State<ModelShowHideMenu> createState() => _ModelShowHideMenuState();
}

class _ModelShowHideMenuState extends State<ModelShowHideMenu> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _overlayEntry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.transparent,
        child: Center(
          child: SizedBox(
            width: 500,
            child: ModelBox(
              overlayEntry: _overlayEntry!,
              componentOperationCubit: BlocProvider.of<ComponentOperationCubit>(
                  context,
                  listen: false),
              componentCreationCubit: BlocProvider.of<ComponentCreationCubit>(
                  context,
                  listen: false),
              componentSelectionCubit: BlocProvider.of<ComponentSelectionCubit>(
                  context,
                  listen: false),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Overlay.of(context)!.insert(_overlayEntry!);
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: kElevationToShadow[1]),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            const Icon(
              Icons.storage,
              size: 18,
              color: Colors.black,
            ),
            const Spacer(),
            Text(
              'Models',
              style: AppFontStyle.roboto(13,
                  color: Colors.black, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class ActionCodeShowHideMenu extends StatefulWidget {
  const ActionCodeShowHideMenu({Key? key}) : super(key: key);

  @override
  State<ActionCodeShowHideMenu> createState() => _ActionCodeShowHideMenuState();
}

class _ActionCodeShowHideMenuState extends State<ActionCodeShowHideMenu> {
  late ActionCodeDialog dialog;
  late ComponentOperationCubit componentOperationCubit;

  @override
  void initState() {
    super.initState();
    componentOperationCubit = context.read<ComponentOperationCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        dialog = ActionCodeDialog(
            code: componentOperationCubit.flutterProject!.actionCode,
            title: componentOperationCubit.flutterProject!.name,
            onChanged: (String value) {
              componentOperationCubit.updateActionCode(value);
            });
        dialog.show(context);
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: kElevationToShadow[1]),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            const Icon(
              Icons.code,
              size: 18,
              color: Colors.black,
            ),
            const Spacer(),
            Text(
              'Action Code',
              style: AppFontStyle.roboto(13,
                  color: Colors.black, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class PrototypeShowcase extends StatefulWidget {
  const PrototypeShowcase({Key? key}) : super(key: key);

  @override
  State<PrototypeShowcase> createState() => _PrototypeShowcaseState();
}

class _PrototypeShowcaseState extends State<PrototypeShowcase> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Padding(
    //   padding: const EdgeInsets.all(8.0),
    //   child: InkWell(
    //       onTap: () {
    //         BlocProvider.of<FlutterProjectCubit>(context, listen: false)
    //             .reloadProject(
    //             BlocProvider.of<ComponentSelectionCubit>(context,
    //                 listen: false),
    //             BlocProvider.of<ComponentOperationCubit>(context,
    //                 listen: false));
    //       },
    //       borderRadius: BorderRadius.circular(10),
    //       child: const Icon(
    //         Icons.refresh,
    //         color: Colors.black,
    //       )),
    // ),
    // const Divider(
    // height: 5,
    // thickness: 0.4,
    // ),

    return Stack(
      children: [
        RuntimeProvider(
          runtimeMode: RuntimeMode.run,
          child: BlocBuilder<FlutterProjectCubit, FlutterProjectState>(
            buildWhen: (state1, state2) {
              if (state2 is FlutterProjectLoadingState) {
                return false;
              }
              return true;
            },
            builder: (context, state) {
              print('STATE IS ${state.runtimeType}');
              if (ComponentOperationCubit.currentFlutterProject != null) {
                ComponentOperationCubit.codeProcessor.variables['dw']!.value =
                    MediaQuery.of(context).size.width;
                ComponentOperationCubit.codeProcessor.variables['dh']!.value =
                    MediaQuery.of(context).size.height;
                get<StackActionCubit>().stackOperation(StackOperation.push,
                    uiScreen: ComponentOperationCubit
                        .currentFlutterProject!.mainScreen);
                ComponentOperationCubit.codeProcessor.execute(
                    ComponentOperationCubit.currentFlutterProject!.actionCode);
                return ComponentOperationCubit.currentFlutterProject!
                    .run(context, navigator: true);
              }
              return Container();
            },
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: PrototypeBackButton(
              iconSize: Responsive.isLargeScreen(context) ? 24 : 14,
              buttonSize: Responsive.isLargeScreen(context) ? 40 : 24,
            ),
          ),
        )
      ],
    );
  }
}

class PrototypeBackButton extends StatelessWidget {
  final double iconSize;
  final double buttonSize;

  const PrototypeBackButton(
      {Key? key, required this.iconSize, required this.buttonSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.grey.shade400.withOpacity(0.4),
          size: iconSize,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}

class DesktopVisualEditor extends StatefulWidget {
  const DesktopVisualEditor({Key? key}) : super(key: key);

  @override
  State<DesktopVisualEditor> createState() => _DesktopVisualEditorState();
}

class _DesktopVisualEditorState extends State<DesktopVisualEditor> {
  final ScrollController _propertyScrollController = ScrollController();
  late final ComponentCreationCubit _componentCreationCubit;

  late final ComponentOperationCubit _componentOperationCubit;

  late final ScreenConfigCubit _screenConfigCubit;

  late final ComponentSelectionCubit _componentSelectionCubit;

  @override
  void initState() {
    super.initState();
    _componentSelectionCubit =
        BlocProvider.of<ComponentSelectionCubit>(context, listen: false);
    _componentOperationCubit =
        BlocProvider.of<ComponentOperationCubit>(context, listen: false);
    _screenConfigCubit =
        BlocProvider.of<ScreenConfigCubit>(context, listen: false);
    _componentCreationCubit =
        BlocProvider.of<ComponentCreationCubit>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return ResizableWidget(
      percentages: const [0.2, 0.5, 0.3],
      children: [
        Container(
          child: const ComponentTree(),
        ),
        Container(
          child: CenterMainSide(
              _componentSelectionCubit,
              _componentCreationCubit,
              _componentOperationCubit,
              _screenConfigCubit),
        ),
        Container(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child:
                BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      _componentSelectionCubit
                          .currentSelected.propertySelection.name,
                      style:
                          AppFontStyle.roboto(18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                            text: _componentSelectionCubit
                                .currentSelected.propertySelection.id));
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _componentSelectionCubit
                                .currentSelected.propertySelection.id,
                            style: AppFontStyle.roboto(13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          const Icon(
                            Icons.copy,
                            color: Colors.grey,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (_componentSelectionCubit
                        .currentSelected.propertySelection is BuilderComponent)
                      BuilderComponentSettings(
                        component: _componentSelectionCubit.currentSelected
                            .propertySelection as BuilderComponent,
                      ),
                    Expanded(
                      child: BlocListener<ComponentCreationCubit,
                          ComponentCreationState>(
                        listener: (context, state) {
                          if (state is ComponentCreationChangeState) {
                            if (_componentSelectionCubit.currentSelectedRoot
                                is CustomComponent) {
                              _componentOperationCubit
                                  .updateGlobalCustomComponent(
                                      _componentSelectionCubit
                                              .currentSelectedRoot
                                          as CustomComponent);
                            } else {
                              _componentOperationCubit.updateRootComponent();
                            }
                          }
                        },
                        child: ListView(
                          controller: _propertyScrollController,
                          children: [
                            if (_componentSelectionCubit
                                .currentSelected.propertySelection is Clickable)
                              BlocProvider<ActionEditCubit>(
                                create: (_) => ActionEditCubit(),
                                child: BlocListener<ActionEditCubit,
                                    ActionEditState>(
                                  listener: (context, state) {
                                    if (state is ActionChangeState) {
                                      if (_componentSelectionCubit
                                              .currentSelectedRoot
                                          is CustomComponent) {
                                        _componentOperationCubit
                                            .updateGlobalCustomComponent(
                                                _componentSelectionCubit
                                                        .currentSelectedRoot
                                                    as CustomComponent);
                                      } else {
                                        _componentOperationCubit
                                            .updateRootComponent();
                                      }
                                    }
                                  },
                                  child: ActionModelWidget(
                                    clickable: _componentSelectionCubit
                                        .currentSelected
                                        .propertySelection as Clickable,
                                  ),
                                ),
                              ),
                            for (final param in _componentSelectionCubit
                                .currentSelected.propertySelection.parameters)
                              ParameterWidget(
                                parameter: param,
                              ),
                            const SizedBox(
                              height: 100,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class BuilderComponentSettings extends StatefulWidget {
  final BuilderComponent component;

  const BuilderComponentSettings({Key? key, required this.component})
      : super(key: key);

  @override
  State<BuilderComponentSettings> createState() =>
      _BuilderComponentSettingsState();
}

class _BuilderComponentSettingsState extends State<BuilderComponentSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach Model',
          style: AppFontStyle.roboto(14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 10,
        ),
        InkWell(
          onTap: () {
            Get.generalDialog(
              barrierDismissible: false,
              barrierLabel: 'barrierLabel',
              barrierColor: Colors.black45,
              transitionDuration: const Duration(milliseconds: 200),
              pageBuilder: (context3, animation, secondary) {
                return Material(
                  color: Colors.transparent,
                  child: DialogSelection(
                    title: 'Choose Model',
                    data: BlocProvider.of<ComponentOperationCubit>(context,
                            listen: false)
                        .models
                        .map((e) => e.name)
                        .toList(),
                    onSelection: (data) {
                      widget.component.model =
                          BlocProvider.of<ComponentOperationCubit>(context,
                                  listen: false)
                              .models
                              .firstWhere((element) => element.name == data);
                      BlocProvider.of<ComponentOperationCubit>(context,
                              listen: false)
                          .emit(ComponentUpdatedState());
                      BlocProvider.of<ComponentCreationCubit>(context,
                              listen: false)
                          .changedComponent();
                      setState(() {});
                    },
                  ),
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Text(
              widget.component.model?.name ?? 'Choose Model',
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        SimpleParameterWidget(parameter: widget.component.itemLengthParameter)
      ],
    );
  }
}

class CenterMainSide extends StatelessWidget {
  final ComponentSelectionCubit _componentSelectionCubit;
  final ComponentOperationCubit _componentOperationCubit;
  final ComponentCreationCubit _componentCreationCubit;
  final ScreenConfigCubit _screenConfigCubit;

  const CenterMainSide(
    this._componentSelectionCubit,
    this._componentCreationCubit,
    this._componentOperationCubit,
    this._screenConfigCubit, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RuntimeProvider(
      runtimeMode: RuntimeMode.edit,
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: RadialGradient(colors: [
            Color(0xffd3d3d3),
            Color(0xffffffff),
          ], tileMode: TileMode.clamp, radius: 0.9, focalRadius: 0.6),
        ),
        child: BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
          builder: (_, state) {
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ToolbarButtons(),
                  const SizedBox(
                    height: 5,
                  ),
                  const SizedBox(
                    width: 200,
                    child: Center(
                      child: ScreenConfigSelection(),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Expanded(
                    child: BlocBuilder<ComponentCreationCubit,
                        ComponentCreationState>(
                      builder: (context, state) {
                        logger('======== COMPONENT CREATION ');
                        return EmulationView(
                          widget: GestureDetector(
                            onSecondaryTapDown: (event) {
                              onSecondaryTapDown(context, event);
                            },
                            onTapDown: onTapDown,
                            child: ColoredBox(
                              key: const GlobalObjectKey('device window'),
                              color: Colors.white,
                              child: Stack(
                                children: [
                                  _componentOperationCubit.flutterProject!
                                      .run(context),
                                  const BoundaryWidget(),
                                ],
                              ),
                            ),
                          ),
                          screenConfig: _screenConfigCubit.screenConfig,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void onTapDown(TapDownDetails event) {
    final List<Component> components = [];
    _componentOperationCubit.flutterProject!.rootComponent!
        .searchTappedComponent(event.localPosition, components);
    logger(
        '==== onTap --- ${event.localPosition.dx} ${event.localPosition.dy} ${components.length}');
    late final Component? tappedComp;
    if (components.isNotEmpty) {
      double? area;
      int? depth;
      Component? finalComponent = components.first;
      for (final component in components) {
        logger('DEPTH ${component.name} ${component.depth}');
        final componentArea =
            component.boundary!.width * component.boundary!.height;
        if (depth == null ||
            component.depth! > depth ||
            (_componentSelectionCubit.lastTapped == finalComponent) ||
            (depth == component.depth && area! > componentArea)) {
          depth = component.depth!;
          area = componentArea;
          finalComponent = component;
        }
      }
      tappedComp = finalComponent!;
    } else {
      tappedComp = null;
    }
    if (tappedComp != null) {
      _componentSelectionCubit.lastTapped = tappedComp;
      // final lastRoot = tappedComp.getCustomComponentRoot();
      // logger('==== CUSTOM ROOT FOUND == ${lastRoot?.name}');
      // if (lastRoot != null) {
      //   if (lastRoot is CustomComponent) {
      //     final rootClone = lastRoot.getRootClone;
      //     _componentSelectionCubit.changeComponentSelection(
      //       ComponentSelectionModel.unique(
      //           CustomComponent.findSameLevelComponent(
      //               rootClone, lastRoot, tappedComp)),
      //       root: rootClone,
      //     );
      //   } else {
      //tappedComp,
      final original = tappedComp.getOriginal() ?? tappedComp;
      _componentSelectionCubit.changeComponentSelection(
        ComponentSelectionModel([original], [tappedComp], original),
        root: original != tappedComp
            ? original.getRootCustomComponent(
                ComponentOperationCubit.currentFlutterProject!)!
            : _componentSelectionCubit.currentSelectedRoot,
      );
      // }
      // }
    }
  }

  void onSecondaryTapDown(BuildContext context, TapDownDetails event) {
    for (final component
        in _componentSelectionCubit.currentSelected.visualSelection) {
      if (component.boundary?.contains(event.localPosition) ?? false) {
        final ContextPopup contextPopup = ContextPopup();
        contextPopup.init(
            child: Material(
              child: ComponentModificationMenu(
                component: component.cloneOf ?? component,
                ancestor: _componentSelectionCubit.currentSelectedRoot,
                componentCreationCubit: _componentCreationCubit,
                componentOperationCubit: _componentOperationCubit,
                componentSelectionCubit: _componentSelectionCubit,
              ),
            ),
            offset: event.globalPosition,
            width: 200,
            height: 50);
        contextPopup.show(context, onHide: () {});
      }
    }
  }
}
