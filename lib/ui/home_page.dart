import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../common/dialog_selection.dart';
import '../models/builder_component.dart';
import '../runtime_provider.dart';
import 'build_view/build_view.dart';
import 'emulation_view.dart';
import 'models_view.dart';
import 'variable_ui.dart';
import '../common/custom_popup_menu_button.dart';
import 'package:get/get.dart';
import '../common/responsive/responsive_widget.dart';
import '../common/context_popup.dart';
import '../cubit/flutter_project/flutter_project_cubit.dart';
import '../common/custom_animated_dialog.dart';
import '../common/custom_drop_down.dart';
import '../common/logger.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/parameter_build_cubit/parameter_build_cubit.dart';
import '../cubit/screen_config/screen_config_cubit.dart';
import '../cubit/visual_box_drawer/visual_box_cubit.dart';
import '../screen_model.dart';
import 'boundary_widget.dart';
import 'code_view_widget.dart';
import 'component_selection_dialog.dart';
import 'parameter_ui.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';

import '../models/component_model.dart';
import 'component_tree.dart';

class HomePage extends StatefulWidget {
  final String projectName;
  final int userId;

  const HomePage({Key? key, required this.projectName, required this.userId})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static StreamSubscription? _streamSubscription;
  final ScrollController propertyScrollController = ScrollController();
  final componentCreationCubit = ComponentCreationCubit();
  final componentOperationCubit = ComponentOperationCubit();
  late final FlutterProjectCubit flutterProjectCubit;
  final ParameterBuildCubit _parameterBuildCubit = ParameterBuildCubit();
  final visualBoxCubit = VisualBoxCubit();
  final screenConfigCubit = ScreenConfigCubit();
  final ComponentSelectionCubit componentSelectionCubit =
      ComponentSelectionCubit();

  @override
  void initState() {
    super.initState();
    flutterProjectCubit = FlutterProjectCubit(widget.userId);
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      flutterProjectCubit.loadFlutterProject(
          componentSelectionCubit, componentOperationCubit, widget.projectName);
    });
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
    }
    _streamSubscription = html.window.onKeyDown.listen((event) {
      if (event.altKey &&
          componentOperationCubit.flutterProject?.rootComponent != null) {
        event.preventDefault();
        if (event.key == 'f') {
          componentOperationCubit
              .toggleFavourites(componentSelectionCubit.currentSelected);
        } else if (event.key == 'v') {
          if (componentOperationCubit.runtimeMode == RuntimeMode.edit) {
            Get.dialog(
              BuildView(
                onDismiss: () {
                  componentCreationCubit.changedComponent();
                },
                componentOperationCubit: componentOperationCubit,
                screenConfigCubit: screenConfigCubit,
              ),
            );
          } else if (componentOperationCubit.runtimeMode == RuntimeMode.run) {
            Get.back();
            componentOperationCubit.runtimeMode = RuntimeMode.edit;
            componentCreationCubit.changedComponent();
          }
        }
      }
    });
    html.window.onResize.listen((event) {
      componentCreationCubit.changedComponent();
    });
  }

  void showSelectionDialog(
      BuildContext context, void Function(Component) onSelection,
      {List<String>? possibleItems}) {
    Get.dialog(
      GestureDetector(
        onTap: () {
          Get.back();
        },
        child: ComponentSelectionDialog(
          possibleItems: possibleItems,
          onSelection: onSelection,
          componentOperationCubit: componentOperationCubit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ComponentCreationCubit>(
                create: (context) => componentCreationCubit),
            BlocProvider<ComponentOperationCubit>(
                create: (context) => componentOperationCubit),
            BlocProvider<ComponentSelectionCubit>(
                create: (context) => componentSelectionCubit),
            BlocProvider<ScreenConfigCubit>(
                create: (context) => screenConfigCubit),
            BlocProvider<VisualBoxCubit>(create: (_) => visualBoxCubit),
            BlocProvider<FlutterProjectCubit>(
                create: (context) => flutterProjectCubit),
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
                  Loader.show(context);
                  break;
                case FlutterProjectErrorState:
                  Loader.hide();
                  Fluttertoast.showToast(
                      msg: (state as FlutterProjectErrorState).message ??
                          'Something went wrong',
                      timeInSecForIosWeb: 3);
                  break;
                case FlutterProjectLoadedState:
                  Loader.hide();
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
              if (state is FlutterProjectLoadedState) {
                componentSelectionCubit.init(
                    state.flutterProject.rootComponent!,
                    state.flutterProject.rootComponent!);
              }
              return const ResponsiveWidget(
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
    return Align(
      alignment: Alignment.topRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                highlightColor: Colors.blueAccent.shade200,
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  CustomDialog.show(
                    context,
                    CodeViewerWidget(
                      code: BlocProvider.of<ComponentOperationCubit>(context,
                              listen: false)
                          .flutterProject!
                          .code(),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: Colors.blueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.code,
                          color: Colors.white,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          'view code',
                          style: AppFontStyle.roboto(14, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              InkWell(
                highlightColor: Colors.blueAccent.shade200,
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Get.dialog(
                    BuildView(
                      onDismiss: () {
                        BlocProvider.of<ComponentCreationCubit>(context,
                                listen: false)
                            .changedComponent();
                      },
                      componentOperationCubit:
                          BlocProvider.of<ComponentOperationCubit>(context,
                              listen: false),
                      screenConfigCubit: BlocProvider.of<ScreenConfigCubit>(
                          context,
                          listen: false),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: Colors.green.shade500,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.remove_red_eye_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          'view',
                          style: AppFontStyle.roboto(14, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              VariableShowHideMenu(),
              ModelShowHideMenu(),
            ],
          )
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

class _VariableShowHideMenuState extends State<VariableShowHideMenu> {
  bool _variableBoxOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _variableBoxOpen = !_variableBoxOpen;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(10),
              child: Text(
                _variableBoxOpen ? 'Hide' : 'Variables',
                style: AppFontStyle.roboto(15,
                    color: Colors.black, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          if (_variableBoxOpen) const VariableBox()
        ],
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
  bool _modelBoxOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _modelBoxOpen = !_modelBoxOpen;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(10),
              child: Text(
                _modelBoxOpen ? 'Hide' : 'Models',
                style: AppFontStyle.roboto(15,
                    color: Colors.black, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          if (_modelBoxOpen) const ModelBox()
        ],
      ),
    );
  }
}

class PrototypeShowcase extends StatelessWidget {
  const PrototypeShowcase({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
              onTap: () {
                BlocProvider.of<FlutterProjectCubit>(context, listen: false)
                    .reloadProject(
                        BlocProvider.of<ComponentSelectionCubit>(context,
                            listen: false),
                        BlocProvider.of<ComponentOperationCubit>(context,
                            listen: false));
              },
              borderRadius: BorderRadius.circular(10),
              child: const Icon(
                Icons.refresh,
                color: Colors.black,
              )),
        ),
        const Divider(
          height: 5,
          thickness: 0.4,
        ),
        Expanded(
          child: RuntimeProvider(
            runtimeMode: RuntimeMode.run,
            child: BlocBuilder<FlutterProjectCubit, FlutterProjectState>(
              buildWhen: (state1, state2) {
                if (state2 is FlutterProjectLoadingState) {
                  return false;
                }
                return true;
              },
              builder: (context, state) {
                if (state is FlutterProjectLoadedState) {
                  return state.flutterProject.run(context);
                }
                return Container();
              },
            ),
          ),
        ),
      ],
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
    return Row(
      children: [
        SizedBox(
          width: dw(context, 23),
          child: const ComponentTree(),
        ),
        Expanded(
          child: Stack(
            children: [
              CenterMainSide(_componentSelectionCubit, _componentCreationCubit,
                  _componentOperationCubit, _screenConfigCubit),
              const ToolbarButtons(),
            ],
          ),
        ),
        SizedBox(
          width: dw(context, 25),
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
                      _componentSelectionCubit.currentSelected.name,
                      style:
                          AppFontStyle.roboto(18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (_componentSelectionCubit.currentSelected
                        is BuilderComponent)
                      BuilderComponentSettings(
                        component: _componentSelectionCubit.currentSelected
                            as BuilderComponent,
                      ),
                    Expanded(
                      child: BlocListener<ComponentCreationCubit,
                          ComponentCreationState>(
                        listener: (context, state) {
                          if (state is ComponentCreationChangeState &&
                              _componentSelectionCubit.currentSelectedRoot
                                  is CustomComponent) {
                            _componentOperationCubit
                                .updateGlobalCustomComponent(
                                    _componentSelectionCubit.currentSelectedRoot
                                        as CustomComponent);
                          } else {
                            _componentOperationCubit.updateRootComponent();
                          }
                        },
                        child: ListView(
                          controller: _propertyScrollController,
                          children: [
                            for (final param in _componentSelectionCubit
                                .currentSelected.parameters)
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
        )
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
            return BlocBuilder<ComponentCreationCubit, ComponentCreationState>(
              builder: (context, state) {
                logger('======== COMPONENT CREATION ');
                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const ScreenConfigSelection(),
                      Expanded(
                        child: EmulationView(
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
                        ),
                      ),
                    ],
                  ),
                );
              },
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
      final lastRoot = tappedComp.getCustomComponentRoot();
      logger('==== CUSTOM ROOT FOUND == ${lastRoot?.name}');
      if (lastRoot != null && lastRoot is CustomComponent) {
        final rootClone = lastRoot.getRootClone;
        _componentSelectionCubit.changeComponentSelection(
          CustomComponent.findSameLevelComponent(
              rootClone, lastRoot, tappedComp),
          root: rootClone,
        );
      } else if (lastRoot != null) {
        _componentSelectionCubit.changeComponentSelection(
          tappedComp,
          root: lastRoot,
        );
      }
    }
  }

  void onSecondaryTapDown(BuildContext context, TapDownDetails event) {
    if (_componentSelectionCubit.currentSelected.boundary != null) {
      if (_componentSelectionCubit.currentSelected.boundary!
          .contains(event.localPosition)) {
        final ContextPopup contextPopup = ContextPopup();
        contextPopup.init(
            child: Material(
              child: ComponentModificationMenu(
                component: _componentSelectionCubit.currentSelected,
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
