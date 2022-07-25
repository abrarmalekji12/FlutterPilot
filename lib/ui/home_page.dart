import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart' as slidingUp;
import '../bloc/error/error_bloc.dart';
import '../bloc/sliding_property/sliding_property_bloc.dart';
import '../common/html_lib.dart' as html;

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
import '../common/dialog_selection.dart';
import '../common/logger.dart';
import '../common/material_alert.dart';
import '../common/responsive/responsive_widget.dart';
import '../constant/app_colors.dart';
import '../constant/app_dim.dart';
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
import 'common/badge_widget.dart';
import 'common/variable_dialog.dart';
import 'component_selection_dialog.dart';
import 'component_tree.dart';
import 'custom_component_property.dart';
import 'emulation_view.dart';
import 'error_widget.dart';
import 'models_view.dart';
import 'parameter_ui.dart';
import 'preview_ui.dart';
import 'project_selection_page.dart';

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
  late ComponentSelectionCubit componentSelectionCubit;

  @override
  void initState() {
    super.initState();
    componentSelectionCubit = get<ComponentSelectionCubit>();
    componentOperationCubit = get<ComponentOperationCubit>();
    componentCreationCubit = get<ComponentCreationCubit>();
    flutterProjectCubit = context.read<FlutterProjectCubit>();
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
    }
    if (kIsWeb) {
      _streamSubscription = html.window.onKeyDown.listen((event) {
        if (event.altKey &&
            componentOperationCubit.project?.rootComponent != null) {
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
      if (ComponentOperationCubit.currentProject?.name != widget.projectName) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          flutterProjectCubit.loadFlutterProject(componentSelectionCubit,
              componentOperationCubit, widget.projectName, widget.runMode,
              userId: widget.userId);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          AppLoader.hide();
        });
      }
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
    return SafeArea(
      child: Material(
        child: MultiBlocProvider(
          providers: [
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
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    AppLoader.hide();
                  });
                  Fluttertoast.showToast(
                      msg: (state as FlutterProjectErrorState).message ??
                          'Something went wrong',
                      timeInSecForIosWeb: 3);
                  break;
                case FlutterProjectLoadedState:
                  componentSelectionCubit.init(
                      ComponentSelectionModel.unique(
                          (state as FlutterProjectLoadedState)
                              .flutterProject
                              .rootComponent!),
                      state.flutterProject.rootComponent!);
                  if (componentOperationCubit.project!.device != null) {
                    final config = screenConfigCubit.screenConfigs
                        .firstWhereOrNull((element) =>
                            element.name ==
                            componentOperationCubit.project!.device);
                    if (config != null) {
                      screenConfigCubit.changeScreenConfig(config);
                    }
                  }
                  AppLoader.hide();
                  break;
              }
            },
            builder: (context, state) {
              if (componentOperationCubit.project == null) {
                return Container();
              }
              if (widget.runMode) {
                return const PrototypeShowcase();
              }
              return const Responsive(
                largeScreen: DesktopVisualEditor(),
                mediumScreen: DesktopVisualEditor(),
                smallScreen: MobileVisualEditor(),
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
    final cubit =
        screenConfigCubit ?? BlocProvider.of<ScreenConfigCubit>(context);

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
    return Wrap(
      runAlignment: WrapAlignment.center,
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 10,
      children: [
        InkWell(
          highlightColor: Colors.blueAccent.shade200,
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            CustomDialog.show(
              context,
              CodeViewerWidget(
                componentOperationCubit:
                    BlocProvider.of<ComponentOperationCubit>(context),
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
                componentOperationCubit:
                    BlocProvider.of<ComponentOperationCubit>(context,
                        listen: false),
                screenConfigCubit: BlocProvider.of<ScreenConfigCubit>(context),
              ),
            ).then((value) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                BlocProvider.of<ScreenConfigCubit>(context)
                    .applyCurrentSizeToVariables();
                BlocProvider.of<ComponentCreationCubit>(context)
                    .changedComponent();
              });
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
                    BlocProvider.of<ScreenConfigCubit>(context)),
                '/projects/${ComponentOperationCubit.currentProject!.name}/preview'));
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
            variables: ComponentOperationCubit.currentProject!.variables,
            componentOperationCubit: componentOperationCubit,
            componentCreationCubit: componentCreationCubit,
            title: ComponentOperationCubit.currentProject!.currentScreen.name,
            onAdded: (model) {
              ComponentOperationCubit.currentProject!.variables[model.name] =
                  model;
              componentOperationCubit.addVariable(ComponentOperationCubit
                  .currentProject!.variables[model.name] as VariableModel);
              componentCreationCubit.changedComponent();
              componentSelectionCubit.emit(ComponentSelectionChange());
            },
            onEdited: (model) {
              ComponentOperationCubit
                  .currentProject!.variables[model.name]!.value = model.value;
              Future.delayed(const Duration(milliseconds: 500), () {
                componentOperationCubit.updateVariable(ComponentOperationCubit
                    .currentProject!.variables[model.name]! as VariableModel);
                componentCreationCubit.changedComponent();
                componentSelectionCubit.emit(ComponentSelectionChange());
              });
            },
            componentSelectionCubit: componentSelectionCubit,
            onDeleted: (VariableModel model) {
              ComponentOperationCubit.currentProject!.variables.remove(model);
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
  bool error = false;

  @override
  void initState() {
    super.initState();
    componentOperationCubit = context.read<ComponentOperationCubit>();
    final root = context.read<ComponentSelectionCubit>().currentSelectedRoot;
    dialog = ActionCodeDialog(
      functions: (root is! StatelessComponent) ? [setStateFunction] : [],
      context: context,
      title: componentOperationCubit.project!.name,
      onChanged: (String value) {
        componentOperationCubit.updateActionCode(value);
      },
      onDismiss: () {
        context.read<ComponentCreationCubit>().changedComponent();
      },
      onError: (bool error) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          setState(() {
            this.error = error;
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        dialog.show(
          context,
          code: componentOperationCubit.project!.actionCode,
          variables: () => componentOperationCubit.project!.variables.values
              .toList(growable: false),
        );
      },
      child: BadgeWidget(
        error: error,
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
    //         BlocProvider.of<FlutterProjectCubit>(context)
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
              if (ComponentOperationCubit.currentProject != null) {
                get<StackActionCubit>().stackOperation(StackOperation.push,
                    uiScreen:
                        ComponentOperationCubit.currentProject!.mainScreen);
                return ComponentOperationCubit.currentProject!.run(
                    context,
                    BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                        maxHeight: MediaQuery.of(context).size.height),
                    navigator: true);
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

class MobileVisualEditor extends StatefulWidget {
  const MobileVisualEditor({Key? key}) : super(key: key);

  @override
  State<MobileVisualEditor> createState() => _MobileVisualEditorState();
}

class _MobileVisualEditorState extends State<MobileVisualEditor> {
  Widget? drawerWidget;
  final SlidingPropertyBloc _slidingPropertyBloc = SlidingPropertyBloc();

  @override
  void initState() {
    super.initState();
    drawerWidget = const Drawer(
      width: 300,
      child: ComponentTree(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Scaffold(
              key: const GlobalObjectKey('ScaffoldKey'),
              resizeToAvoidBottomInset: false,
              drawer: drawerWidget,
              body: Stack(
                children: [
                  CenterMainSide(
                    slidingPropertyBloc: _slidingPropertyBloc,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Builder(builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(5),
                        child: AppIconButton(
                          iconSize: 24,
                          buttonSize: 40,
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          icon: Icons.list,
                          color: AppColors.theme,
                        ),
                      );
                    }),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        width: 20,
                        height: MediaQuery.of(context).size.height-500,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: StatefulBuilder(builder: (context, setState2) {
                            return Slider(
                              value: _slidingPropertyBloc.value,
                              activeColor: Colors.grey.withOpacity(0.5),
                              inactiveColor: Colors.grey.withOpacity(0.8),
                              onChanged: (newValue) {
                                setState2(() {});
                                _slidingPropertyBloc.add(
                                    SlidingPropertyChange(value: newValue));
                              },
                            );
                          }),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )),
        const SlidingPropertySection()
      ],
    );
  }
}

class SlidingPropertySection extends StatefulWidget {
  const SlidingPropertySection({Key? key}) : super(key: key);

  @override
  State<SlidingPropertySection> createState() => _SlidingPropertySectionState();
}

class _SlidingPropertySectionState extends State<SlidingPropertySection> {
  late final ErrorBloc _errorBloc;
  final panelController = slidingUp.PanelController();

  @override
  void initState() {
    _errorBloc = context.read<ErrorBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return slidingUp.SlidingUpPanel(
      panel: const ComponentPropertySection(),
      minHeight: 80,
      maxHeight: 500,
      controller: panelController,
      onPanelSlide: (value) {
        if (value == 0) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
            }
          });
        }
      },
      collapsed: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: BlocBuilder<ErrorBloc, ErrorState>(
            bloc: _errorBloc,
            builder: (context, state) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorBloc.consoleMessages.isNotEmpty)
                    SizedBox(
                      width: 150,
                      child: Text(
                        _errorBloc.consoleMessages.last.message,
                        style: AppFontStyle.roboto(
                            _errorBloc.consoleMessages.last.type ==
                                    ConsoleMessageType.event
                                ? 10
                                : 14,
                            color: getConsoleMessageColor(
                                _errorBloc.consoleMessages.last.type),
                            fontWeight: _errorBloc.consoleMessages.last.type ==
                                    ConsoleMessageType.event
                                ? FontWeight.w700
                                : FontWeight.w500),
                      ),
                    )
                  else
                    Text(
                      'No Messages',
                      style: AppFontStyle.roboto(14, color: Colors.grey),
                    )
                ],
              );
            },
          ),
        ),
      ),
      onPanelClosed: () {},
    );
  }
}

class DesktopVisualEditor extends StatefulWidget {
  const DesktopVisualEditor({Key? key}) : super(key: key);

  @override
  State<DesktopVisualEditor> createState() => _DesktopVisualEditorState();
}

class _DesktopVisualEditorState extends State<DesktopVisualEditor> {


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ResizableWidget(
      percentages: const [0.2, 0.5, 0.3],
      separatorSize: Dimen.separator,
      separatorColor: AppColors.separator,
      children: const [
        ComponentTree(),
        CenterMainSide(),
        ComponentPropertySection(),
      ],
    );
  }
}

class ComponentPropertySection extends StatefulWidget {
  const ComponentPropertySection({Key? key}) : super(key: key);

  @override
  State<ComponentPropertySection> createState() =>
      _ComponentPropertySectionState();
}

class _ComponentPropertySectionState extends State<ComponentPropertySection> {
  late final ComponentOperationCubit _componentOperationCubit;

  late final ComponentSelectionCubit _componentSelectionCubit;

  @override
  void initState() {
    super.initState();
    _componentSelectionCubit =
        BlocProvider.of<ComponentSelectionCubit>(context);
    _componentOperationCubit =
        BlocProvider.of<ComponentOperationCubit>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Responsive.isLargeScreen(context)
          ? const EdgeInsets.all(15)
          : const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _componentSelectionCubit
                        .currentSelected.propertySelection.name,
                    style: AppFontStyle.roboto(18, fontWeight: FontWeight.bold),
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
                  if (_componentSelectionCubit.currentSelected.propertySelection
                      is BuilderComponent)
                    BuilderComponentSettings(
                      component: _componentSelectionCubit.currentSelected
                          .propertySelection as BuilderComponent,
                    ),
                ],
              );
            },
          ),
          Expanded(
            child: BlocListener<ComponentCreationCubit, ComponentCreationState>(
              listener: (context, state) {
                if (state is ComponentCreationChangeState) {
                  if (state.ancestor != null) {
                    _componentOperationCubit
                        .updateGlobalCustomComponent(state.ancestor!);
                  } else if (_componentSelectionCubit.currentSelectedRoot
                      is CustomComponent) {
                    _componentOperationCubit.updateGlobalCustomComponent(
                        _componentSelectionCubit.currentSelectedRoot
                            as CustomComponent);
                  } else {
                    _componentOperationCubit.updateRootComponent();
                  }
                }
              },
              child: Responsive(
                mediumScreen: const PropertyPortion(),
                smallScreen: const PropertyPortion(),
                largeScreen: ResizableWidget(
                  percentages: const [0.8, 0.2],
                  isHorizontalSeparator: true,
                  separatorSize: Dimen.separator,
                  separatorColor: AppColors.separator,
                  children: const [
                    PropertyPortion(),
                    ConsoleWidget(),
                  ],
                ),
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

class PropertyPortion extends StatefulWidget {
  const PropertyPortion({Key? key}) : super(key: key);

  @override
  State<PropertyPortion> createState() => _PropertyPortionState();
}

class _PropertyPortionState extends State<PropertyPortion> {
  final ScrollController _propertyScrollController = ScrollController();
  late final ComponentOperationCubit _componentOperationCubit;

  late final ComponentSelectionCubit _componentSelectionCubit;

  @override
  void initState() {
    super.initState();
    _componentSelectionCubit =
        BlocProvider.of<ComponentSelectionCubit>(context);
    _componentOperationCubit =
        BlocProvider.of<ComponentOperationCubit>(context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
        builder: (context, state) {
          return ListView(
            controller: _propertyScrollController,
            children: [
              if (_componentSelectionCubit.currentSelected.propertySelection
                  is Clickable)
                BlocProvider<ActionEditCubit>(
                  create: (_) => ActionEditCubit(),
                  child: BlocListener<ActionEditCubit, ActionEditState>(
                    listener: (context, state) {
                      if (state is ActionChangeState) {
                        if (_componentSelectionCubit.currentSelectedRoot
                            is CustomComponent) {
                          _componentOperationCubit.updateGlobalCustomComponent(
                              _componentSelectionCubit.currentSelectedRoot
                                  as CustomComponent);
                        } else {
                          _componentOperationCubit.updateRootComponent();
                        }
                      }
                    },
                    child: ActionModelWidget(
                      clickable: _componentSelectionCubit
                          .currentSelected.propertySelection as Clickable,
                    ),
                  ),
                ),
              if (_componentSelectionCubit.currentSelected.intendedSelection
                  is CustomComponent)
                CustomComponentProperty(
                  component: _componentSelectionCubit
                      .currentSelected.intendedSelection as CustomComponent,
                ),
              for (final param in _componentSelectionCubit
                  .currentSelected.propertySelection.parameters)
                ParameterWidget(
                  parameter: param,
                ),
              // if (!Responsive.isLargeScreen(context) &&
              //     MediaQuery.of(context).viewInsets.bottom > 0)
              //   SizedBox(
              //     height: MediaQuery.of(context).viewInsets.bottom,
              //   )
            ],
          );
        },
      ),
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
  final SlidingPropertyBloc? slidingPropertyBloc;

  const CenterMainSide({
    Key? key,
    this.slidingPropertyBloc,
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
                    child: Responsive(
                      smallScreen: BlocBuilder<SlidingPropertyBloc,
                          SlidingPropertyState>(
                        bloc: slidingPropertyBloc,
                        builder: (context, state) {
                          return Transform.translate(
                            offset: Offset(0,
                                -(1 - (slidingPropertyBloc?.value ?? 0)) * 500),
                            child: const EditingView(),
                          );
                        },
                      ),
                      largeScreen: const EditingView(),
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
}

class EditingView extends StatefulWidget {
  const EditingView({Key? key}) : super(key: key);

  @override
  State<EditingView> createState() => _EditingViewState();
}

class _EditingViewState extends State<EditingView> {
  late final ComponentCreationCubit _componentCreationCubit;

  late final ComponentOperationCubit _componentOperationCubit;

  late final ScreenConfigCubit _screenConfigCubit;

  late final ComponentSelectionCubit _componentSelectionCubit;

  @override
  void initState() {
    super.initState();
    _componentSelectionCubit =
        BlocProvider.of<ComponentSelectionCubit>(context);
    _componentOperationCubit =
        BlocProvider.of<ComponentOperationCubit>(context);
    _screenConfigCubit = BlocProvider.of<ScreenConfigCubit>(context);
    _componentCreationCubit = BlocProvider.of<ComponentCreationCubit>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
        builder: (context, state) {
      return BlocBuilder<ComponentCreationCubit, ComponentCreationState>(
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
                  _componentOperationCubit.project!.run(
                      context,
                      BoxConstraints(
                          maxWidth: _screenConfigCubit.screenConfig.width,
                          maxHeight: _screenConfigCubit.screenConfig.height)),
                  const BoundaryWidget(),
                ],
              ),
            ),
          ),
          screenConfig: _screenConfigCubit.screenConfig,
        );
      });
    });
  }

  void onTapDown(TapDownDetails event) {
    final List<Component> components = [];
    _componentOperationCubit.project!.rootComponent!
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
      final visuals = [tappedComp];
      _componentSelectionCubit.changeComponentSelection(
        ComponentSelectionModel([original], visuals, original, original),
        root: original != tappedComp
            ? original.getRootCustomComponent(
                ComponentOperationCubit.currentProject!)!
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
