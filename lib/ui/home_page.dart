import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/flutter_project/flutter_project_cubit.dart';
import '../firestore/firestore_bridge.dart';
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
import 'parameter_ui.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:provider/provider.dart';

import '../models/component_model.dart';
import 'component_tree.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController propertyScrollController = ScrollController();
  final componentPropertyCubit = ComponentCreationCubit();
  final componentOperationCubit = ComponentOperationCubit();
  final flutterProjectCubit = FlutterProjectCubit();
  final ParameterBuildCubit _parameterBuildCubit = ParameterBuildCubit();
  final visualBoxCubit = VisualBoxCubit();
  final screenConfigCubit = ScreenConfigCubit();
  final ComponentSelectionCubit componentSelectionCubit =
      ComponentSelectionCubit();

  @override
  void initState() {
    super.initState();
    FireBridge.init().then((value) {
    flutterProjectCubit.loadFlutterProject(
            componentSelectionCubit, componentOperationCubit);
    });

    html.window.onResize.listen((event) {
      componentPropertyCubit.changedComponent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ComponentCreationCubit>(
                create: (context) => componentPropertyCubit),
            BlocProvider<ComponentOperationCubit>(
                create: (context) => componentOperationCubit),
            BlocProvider<ComponentSelectionCubit>(
                create: (context) => componentSelectionCubit),
            BlocProvider<ScreenConfigCubit>(
                create: (context) => screenConfigCubit),
            BlocProvider<VisualBoxCubit>(create: (context) => visualBoxCubit),
            BlocProvider<FlutterProjectCubit>(
                create: (context) => flutterProjectCubit),
          ],
          child: BlocConsumer<FlutterProjectCubit, FlutterProjectState>(
            listener: (context, state) {
              switch (state.runtimeType) {
                case FlutterProjectLoadingState:
                  Loader.show(context);
                  break;
                case FlutterProjectLoadedState:
                  Loader.hide();
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
              return Row(
                children: [
                  BlocListener<ComponentOperationCubit,
                      ComponentOperationState>(
                    bloc: componentOperationCubit,
                    listener: (BuildContext context, state) {
                      switch (state.runtimeType) {
                        case ComponentOperationLoadingState:
                          Loader.show(context);
                          break;
                        case ComponentOperationInitial:
                          Loader.hide();
                          break;
                      }
                    },
                    child: const SizedBox(
                      width: 300,
                      child: ComponentTree(),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildLeftSide(),
                        const CodeViewerButton(),
                      ],
                    ),
                  ),

                  // const SizedBox(
                  //   width: 200,
                  //   child: ComponentSelection(),
                  // ),
                  SizedBox(
                    width: 300,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: BlocBuilder<ComponentSelectionCubit,
                          ComponentSelectionState>(
                        builder: (context, state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 20,
                              ),
                              Text(
                                componentSelectionCubit.currentSelected.name,
                                style: AppFontStyle.roboto(18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Expanded(
                                child: BlocListener<ComponentCreationCubit,
                                    ComponentCreationState>(
                                  listener: (context, state) {
                                    if (state is ComponentCreationChangeState &&
                                        componentSelectionCubit
                                                .currentSelectedRoot
                                            is CustomComponent) {
                                      componentOperationCubit
                                          .updateGlobalCustomComponent(
                                              componentSelectionCubit
                                                      .currentSelectedRoot
                                                  as CustomComponent);
                                    } else {
                                      componentOperationCubit
                                          .updateRootComponent(
                                              componentSelectionCubit
                                                  .currentSelectedRoot);
                                    }
                                  },
                                  child: BlocProvider(
                                      create: (context) => _parameterBuildCubit,
                                      child: ListView(
                                        controller: propertyScrollController,
                                        children: [
                                          for (final param
                                              in componentSelectionCubit
                                                  .currentSelected.parameters)
                                            ParameterWidget(
                                              parameter: param,
                                            ),
                                        ],
                                      )),
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSide() {
    return Container(
      decoration: const BoxDecoration(
          gradient: RadialGradient(colors: [
        Color(0xffd3d3d3),
        Color(0xffffffff),
      ], tileMode: TileMode.clamp, radius: 0.9, focalRadius: 0.6)),
      child: Center(
        child: BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
          builder: (context, state) {
            return BlocBuilder<ComponentCreationCubit, ComponentCreationState>(
              builder: (context, state) {
                logger('======== COMPONENT CREATION ');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ScreenConfigSelection(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Transform.scale(
                          scale: 1,
                          child: GestureDetector(
                            onTapDown: (event) {
                              logger(
                                  '==== onTap --- ${event.localPosition.dx} ${event.localPosition.dy}');
                              final tappedComp = componentOperationCubit
                                  .flutterProject!.rootComponent!
                                  .searchTappedComponent(event.localPosition);
                              if (tappedComp != null) {
                                final lastRoot =
                                    tappedComp.getCustomComponentRoot();
                                logger(
                                    '==== CUSTOM ROOT FOUND == ${lastRoot?.name}');
                                if (lastRoot != null &&
                                    lastRoot is CustomComponent) {
                                  final rootClone = lastRoot.getRootClone;
                                  componentSelectionCubit
                                      .changeComponentSelection(
                                    CustomComponent.findSameLevelComponent(
                                        rootClone, lastRoot, tappedComp),
                                    root: rootClone,
                                  );
                                } else if (lastRoot != null) {
                                  componentSelectionCubit
                                      .changeComponentSelection(
                                    tappedComp,
                                    root: lastRoot,
                                  );
                                }
                              }
                            },
                            child: Container(
                              key: const GlobalObjectKey('device window'),
                              width: screenConfigCubit.screenConfig.width,
                              height: screenConfigCubit.screenConfig.height,
                              color: Colors.white,
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: BlocListener<ComponentOperationCubit,
                                        ComponentOperationState>(
                                      listener: (context, state) {},
                                      child: componentOperationCubit
                                          .flutterProject!
                                          .run(context),
                                    ),
                                  ),
                                  const BoundaryWidget(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void onErrorIgnoreOverflowErrors(
    FlutterErrorDetails details, {
    bool forceReport = false,
  }) {
    bool ifIsOverflowError = false;

    // Detect overflow error.
    var exception = details.exception;
    if (exception is FlutterError) {
      ifIsOverflowError = !exception.diagnostics.any(
          (e) => e.value.toString().startsWith('A RenderFlex overflowed by'));
    }

    // Ignore if is overflow error.
    if (ifIsOverflowError) {
      logger('Overflow error.');
      visualBoxCubit.enableError('Error happened');
    } else {
      FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
    }
  }
}

class ScreenConfigSelection extends StatelessWidget {
  const ScreenConfigSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = Provider.of<ScreenConfigCubit>(context, listen: false);
    return BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(left: 30),
          child: SizedBox(
            width: 200,
            height: 50,
            child: CustomDropdownButton<ScreenConfig>(
                style: AppFontStyle.roboto(14),
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
                            style: AppFontStyle.roboto(14,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  cubit.changeScreenConfig(value);
                },
                selectedItemBuilder: (context, config) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${config.name} (${config.width}x${config.height})',
                      style:
                          AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
                    ),
                  );
                }),
          ),
        );
      },
    );
  }
}

class CodeViewerButton extends StatelessWidget {
  const CodeViewerButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: InkWell(
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
              padding: const EdgeInsets.all(8),
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
                    style: AppFontStyle.roboto(16, color: Colors.white),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
