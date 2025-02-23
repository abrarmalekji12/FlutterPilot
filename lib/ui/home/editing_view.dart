import 'dart:core';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import '../../bloc/error/error_bloc.dart';
import '../../bloc/navigation/fvb_navigation_bloc.dart';
import '../../bloc/state_management/state_management_bloc.dart';
import '../../common/analyzer/render_models.dart';
import '../../common/context_popup.dart';
import '../../common/interactive_viewer/interactive_viewer_updated.dart';
import '../../common/logger.dart';
import '../../common/web/io_lib.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../cubit/user_details/user_details_cubit.dart';
import '../../cubit/visual_box_drawer/visual_box_cubit.dart';
import '../../injector.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/component_selection.dart';
import '../../runtime_provider.dart';
import '../../widgets/message/empty_text.dart';
import '../boundary_widget.dart';
import '../component_tree/component_sublist.dart';
import '../emulation_view.dart';
import '../visual_model.dart';
import 'component_control_widget.dart';
import 'cubit/home_cubit.dart';
import 'drop_layer_widget.dart';
import 'home_page.dart';

class ScreenKey extends GlobalObjectKey {
  ScreenKey(super.value);
}

class ScaleNotifier extends ChangeNotifier {
  double? scaleFactor;
  double? maxScaleFactor;
  double _scale = 1;

  set value(double value) {
    _scale = value;
    notifyListeners();
  }

  double get scaleValue {
    return scaleByFactor(value, scaleFactor);
  }

  double get value => _scale;

  update(BuildContext context, Size size, BoxConstraints constraints) {
    maxScaleFactor = 25;
    scaleFactor = ((size.width * size.height) /
            (constraints.maxWidth * constraints.maxHeight)) *
        0.8;
    scaleFactor = MediaQuery.of(context).textScaler.scale(scaleFactor!);
    notifyListeners();
  }
}

class EditingView extends StatefulWidget {
  const EditingView({Key? key}) : super(key: key);

  @override
  State<EditingView> createState() => _EditingViewState();
}

const double editHorizontalPadding = 500;
const double editVerticalPadding = 80;
const double dragObjectSize = 60;

class _EditingViewState extends State<EditingView> {
  late final CreationCubit _creationCubit;

  late final OperationCubit _operationCubit;

  late final UserDetailsCubit _userDetailsCubit;
  late final VisualBoxCubit _visualBoxCubit;

  late final SelectionCubit _selectionCubit;
  final navigationBloc = sl<FvbNavigationBloc>();
  final CustomTransformationController _controller =
      CustomTransformationController();

  final ValueNotifier<bool> dragEnable = ValueNotifier(true);
  final ScaleNotifier scaleNotifier = ScaleNotifier();
  final key = GlobalKey();
  final key2 = GlobalKey();
  double iVScale = 1;
  Size? lastSize;

  BoxConstraints? constraints;

  @override
  void initState() {
    super.initState();
    _selectionCubit = context.read<SelectionCubit>();
    _operationCubit = context.read<OperationCubit>();
    _userDetailsCubit = context.read<UserDetailsCubit>();
    _visualBoxCubit = context.read<VisualBoxCubit>();
    _creationCubit = context.read<CreationCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<StateManagementBloc, StateManagementState>(
          listener: (context, state) {
            if (state is StateManagementUpdatedState &&
                RuntimeProvider.of(context) == state.mode) {
              _selectionCubit.clearErrors(state.id);
              context
                  .read<EventLogBloc>()
                  .add(ClearComponentMessageEvent(state.id));

              if (state.mode == RuntimeMode.edit) {
                Future.delayed(const Duration(milliseconds: 50), () {
                  for (final screen in collection.project!.screens) {
                    screen.rootComponent?.forEachWithClones((p0) {
                      p0.updateBoundary(screen);
                      return false;
                    });
                  }
                });
              }
            }
          },
        ),
        BlocListener<ScreenConfigCubit, ScreenConfigState>(
          listener: (context, state) {
            if (state is ScreenConfigChangeState) {
              _updateScaleFactor();
            }
          },
        ),
        BlocListener<UserDetailsCubit, UserDetailsState>(
          listener: (context, state) {
            if (state is FlutterProjectScreenUpdatedState) {
              _updateScaleFactor();
            }
          },
        ),
        BlocListener(
          bloc: _operationCubit,
          listener: (context, state) {
            if (state is ComponentOperationFigmaScreensConvertedState) {
              _userDetailsCubit.updateScreen();
              if (state.screens.isNotEmpty) {
                _selectionCubit.init(ComponentSelectionModel.unique(
                    state.screens.first.rootComponent!,
                    state.screens.first.rootComponent!,
                    screen: state.screens.first));
              }
              _creationCubit.changedComponent();
            }
          },
        ),
      ],
      child: BlocBuilder<UserDetailsCubit, UserDetailsState>(
        buildWhen: (state1, state2) =>
            state2 is FlutterProjectScreenUpdatedState ||
            state2 is FlutterProjectLoadedState,
        builder: (context, state) {
          return LayoutBuilder(builder: (context, constraints) {
            this.constraints = constraints;
            _updateScaleFactor();
            return BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
                builder: (context, state) {
              context
                  .read<EventLogBloc>()
                  .add(ClearMessageEvent(RuntimeProvider.of(context)));
              sl<SelectionCubit>().clearErrors();
              systemProcessor.variables['dw']!
                  .setValue(systemProcessor, constraints.maxWidth);
              systemProcessor.variables['dh']!
                  .setValue(systemProcessor, constraints.maxHeight);
              if (collection.project!.screens.isEmpty) {
                return const Center(
                  child: EmptyTextIconWidget(
                    text: 'No screens yet',
                    icon: Icons.pages_rounded,
                  ),
                );
              }
              return RepaintBoundary(
                key: const GlobalObjectKey('repaint'),
                child: CustomInteractiveViewer(
                  onInteractionEnd: (details) {},
                  boundaryMargin: const EdgeInsets.all(100),
                  dragEnable: dragEnable,
                  scaleFactor: 1000,
                  minScale: 1 / (constraints.maxWidth),
                  transformationController: _controller,
                  scaleNotifier: scaleNotifier,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: FittedBox(
                      child: Padding(
                        key: key,
                        padding: const EdgeInsets.symmetric(
                          horizontal: editHorizontalPadding,
                          vertical: editVerticalPadding,
                        ),
                        child: RepaintBoundary(
                          key: const GlobalObjectKey('repaint_inside'),
                          child: ColoredBox(
                            color: ColorAssets.colorE5E5E5,
                            child: Stack(
                              children: [
                                BlocConsumer<HomeCubit, HomeState>(
                                  buildWhen: (_, state) => state
                                      is HomeCustomComponentPreviewUpdatedState,
                                  listenWhen: (_, state) => state
                                      is HomeCustomComponentPreviewUpdatedState,
                                  listener: (context, state) {
                                    if (state
                                        is HomeCustomComponentPreviewUpdatedState) {
                                      _updateScaleFactor();
                                    }
                                  },
                                  builder: (context, state) {
                                    return Wrap(
                                      spacing: 20,
                                      runSpacing: 20,
                                      children: [
                                        for (final screen
                                            in collection.project!.screens)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListenableBuilder(
                                                  listenable: scaleNotifier,
                                                  builder: (context, _) {
                                                    final s = scaleNotifier
                                                        .scaleValue;
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: s * 8),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          BlocBuilder<
                                                              OperationCubit,
                                                              OperationState>(
                                                            buildWhen: (_,
                                                                    state) =>
                                                                state
                                                                    is ComponentOperationScreensUpdatedState,
                                                            builder: (context,
                                                                state) {
                                                              return Container(
                                                                constraints:
                                                                    const BoxConstraints(
                                                                        maxWidth:
                                                                            250),
                                                                child: Text(
                                                                  screen.name,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: AppFontStyle.lato(
                                                                      s * 11,
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.8)),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                          SizedBox(
                                                            width: 8 * s,
                                                          ),
                                                          InkWell(
                                                            child: Icon(
                                                              Icons.refresh,
                                                              size: s * 12,
                                                            ),
                                                            onTap: () {
                                                              if (screen
                                                                      .rootComponent !=
                                                                  null) {
                                                                _creationCubit
                                                                    .changedComponent();
                                                              }
                                                            },
                                                          ),
                                                          // SizedBox(
                                                          //   width: 8 * s,
                                                          // ),
                                                          // InkWell(
                                                          //   child: Icon(
                                                          //     Icons.developer_mode,
                                                          //     size: s * 10,
                                                          //   ),
                                                          //   onTap: () {
                                                          //     _operationCubit.collection.project!.screens.removeLast();
                                                          //     _operationCubit.addScreensFromFigma(
                                                          //         _userSession.settingModel!.figmaAccessToken!,
                                                          //         'https://www.figma.com/file/YAzoE08Qr3RFM1ybSzTSPP/Untitled?type=design&node-id=0-1&t=TgPpFLMc20AZcioF-0');
                                                          //   },
                                                          // )
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                              RepaintBoundary(
                                                key: ScreenKey('${screen.id}'),
                                                child: SubEmulationView(
                                                  widget: MouseRegion(
                                                    // onEnter: onHover,
                                                    onHover: (event) => onHover
                                                        .call(event, screen),
                                                    // onExit: onHover,
                                                    child: GestureDetector(
                                                      onSecondaryTapDown:
                                                          (event) {
                                                        onSecondaryTapDown(
                                                            context,
                                                            screen,
                                                            event);
                                                      },
                                                      onTapDown: (event) =>
                                                          onTapDown.call(
                                                              event, screen),
                                                      child: ViewableProvider(
                                                        screen: screen,
                                                        key: GlobalObjectKey(
                                                            screen.id),
                                                        child: Stack(
                                                          clipBehavior:
                                                              Clip.none,
                                                          children: [
                                                            BlocBuilder<
                                                                    CreationCubit,
                                                                    CreationState>(
                                                                buildWhen: (prev,
                                                                        state) =>
                                                                    !fvbNavigationBloc.model.drawer &&
                                                                    !fvbNavigationBloc
                                                                        .model
                                                                        .dialog &&
                                                                    !fvbNavigationBloc
                                                                        .model
                                                                        .bottomSheet,
                                                                builder:
                                                                    (context,
                                                                        state) {
                                                                  if (_operationCubit
                                                                          .project ==
                                                                      null) {
                                                                    return const Offstage();
                                                                  }
                                                                  return _operationCubit.project!.run(
                                                                      context,
                                                                      BoxConstraints(
                                                                          maxWidth: selectedConfig!
                                                                              .width,
                                                                          maxHeight: selectedConfig!
                                                                              .height),
                                                                      debug:
                                                                          true,
                                                                      screen:
                                                                          screen);
                                                                }),
                                                            BlocBuilder<
                                                                    CreationCubit,
                                                                    CreationState>(
                                                                bloc:
                                                                    _creationCubit,
                                                                builder:
                                                                    (context,
                                                                        state) {
                                                                  return BoundaryWidget(
                                                                    scaleNotifier:
                                                                        scaleNotifier,
                                                                  );
                                                                }),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  screenConfig: selectedConfig!,
                                                ),
                                              ),
                                            ],
                                          ),
                                        for (final custom in collection
                                            .project!.customComponents)
                                          Visibility(
                                            visible: custom.previewEnable,
                                            child: BlocBuilder<OperationCubit,
                                                OperationState>(
                                              builder: (context, state) {
                                                final Size? s = (custom
                                                                .rootComponent
                                                            is CRenderModel
                                                        ? (custom.rootComponent
                                                                as CRenderModel)
                                                            .size
                                                        : null) ??
                                                    custom.rootComponent
                                                        ?.getAllClones()
                                                        .firstWhereOrNull(
                                                            (element) =>
                                                                element
                                                                    .boundary !=
                                                                null)
                                                        ?.boundary!
                                                        .size;
                                                final Size? size = s != null
                                                    ? Size(
                                                        s.width.isFinite
                                                            ? s.width
                                                            : selectedConfig!
                                                                .width,
                                                        s.height.isFinite
                                                            ? s.height
                                                            : selectedConfig!
                                                                .height)
                                                    : Size(
                                                        selectedConfig!.width,
                                                        selectedConfig!.height);
                                                if (size != null) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      ListenableBuilder(
                                                          listenable:
                                                              scaleNotifier,
                                                          builder:
                                                              (context, _) {
                                                            final s =
                                                                scaleNotifier
                                                                    .scaleValue;
                                                            return Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          s * 8),
                                                              child: Text(
                                                                custom.name,
                                                                style: AppFontStyle.lato(
                                                                    s * 10,
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.8)),
                                                              ),
                                                            );
                                                          }),
                                                      SizedBox(
                                                        width: size.width,
                                                        height: size.height,
                                                        child:
                                                            ProcessorProvider(
                                                          processor: collection
                                                              .project!
                                                              .processor,
                                                          child:
                                                              ViewableProvider(
                                                            screen: custom,
                                                            key:
                                                                GlobalObjectKey(
                                                                    custom.id),
                                                            child: MouseRegion(
                                                              // onEnter: onHover,
                                                              onHover: (event) =>
                                                                  onHover.call(
                                                                      event,
                                                                      custom),
                                                              // onExit: onHover,
                                                              child: Stack(
                                                                children: [
                                                                  GestureDetector(
                                                                    onSecondaryTapDown:
                                                                        (event) {
                                                                      onSecondaryTapDown(
                                                                          context,
                                                                          custom,
                                                                          event);
                                                                    },
                                                                    onTapDown: (event) =>
                                                                        onTapDown.call(
                                                                            event,
                                                                            custom),
                                                                    child:
                                                                        Stack(
                                                                      clipBehavior:
                                                                          Clip.none,
                                                                      children: [
                                                                        BlocBuilder<CreationCubit,
                                                                                CreationState>(
                                                                            buildWhen: (prev, state) =>
                                                                                !fvbNavigationBloc.model.drawer &&
                                                                                !fvbNavigationBloc.model.endDrawer &&
                                                                                !fvbNavigationBloc.model.dialog &&
                                                                                !fvbNavigationBloc.model.bottomSheet,
                                                                            builder: (context, state) {
                                                                              if (_operationCubit.project == null) {
                                                                                return const Offstage();
                                                                              }

                                                                              return Container(
                                                                                constraints: BoxConstraints(maxWidth: size.width, maxHeight: size.height),
                                                                                child: custom.build(context),
                                                                              );
                                                                            }),
                                                                        BlocBuilder<
                                                                            CreationCubit,
                                                                            CreationState>(builder: (context, state) {
                                                                          return BoundaryWidget(
                                                                            scaleNotifier:
                                                                                scaleNotifier,
                                                                          );
                                                                        }),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                                return const Offstage();
                                              },
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                Positioned.fill(
                                  child: ComponentControlWidget(
                                    rootKey: key,
                                    scaleNotifier: scaleNotifier,
                                  ),
                                ),
                                Positioned.fill(
                                  child: DropLayerWidget(
                                    project: collection.project!,
                                    scaleNotifier: scaleNotifier,
                                    rootKey: key,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            });
          });
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant EditingView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    _updateScaleFactor();
    super.didChangeDependencies();
  }

  void onHover(event, Viewable screen) {
    if (Platform.isAndroid || Platform.isIOS) {
      return;
    }
    final Set<Component> components = {};
    getSearchRoot(_operationCubit, screen)
        ?.searchTappedComponent(event.localPosition, components);
    if (components.isEmpty) {
      return;
    }
    int depth = -1;
    int index = -1;
    for (int i = 0; i < components.length; i++) {
      if ((components.elementAt(i).depth ?? 0) > depth) {
        depth = (components.elementAt(i).depth ?? 0);
        index = i;
      }
    }
    _visualBoxCubit.visualHoverUpdated([
      Boundary(
          components.elementAt(index).boundary!, components.elementAt(index))
    ], screen);
  }

  void onTapDown(TapDownDetails event, Viewable screen) {
    final Set<Component> components = {};
    getSearchRoot(_operationCubit, screen)
        ?.searchTappedComponent(event.localPosition, components);
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
            (component.depth ?? 0) > depth ||
            (_selectionCubit.lastTapped == finalComponent) ||
            (depth == component.depth && area! > componentArea)) {
          depth = component.depth ?? 0;
          area = componentArea;
          finalComponent = component;
        }
      }
      tappedComp = finalComponent!;
    } else {
      tappedComp = null;
    }
    if (tappedComp != null) {
      _selectionCubit.lastTapped = tappedComp;
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
      _selectionCubit.changeComponentSelection(ComponentSelectionModel(
          [original],
          visuals,
          original,
          original,
          original != tappedComp
              ? original.getRootCustomComponent(collection.project!, screen)!
              : _selectionCubit.currentSelectedRoot,
          viewable: screen));
      // }
      // }
    }
  }

  void onSecondaryTapDown(BuildContext context, screen, TapDownDetails event) {
    for (final component in _selectionCubit.selected.visualSelection) {
      if (component.boundary?.contains(event.localPosition) ?? false) {
        final ContextPopup contextPopup = ContextPopup();
        contextPopup.init(
            child: BlocListener<OperationCubit, OperationState>(
              listener: (context, state) {
                if (state is ComponentUpdatedState) {
                  contextPopup.hide();
                }
              },
              child: Material(
                child: ViewableProvider(
                  screen: screen,
                  child: OperationMenu(
                    component: component.getOriginal() ?? component,
                    ancestor: _selectionCubit.currentSelectedRoot,
                    creationCubit: _creationCubit,
                    operationCubit: _operationCubit,
                    componentSelectionCubit: _selectionCubit,
                  ),
                ),
              ),
            ),
            offset: event.globalPosition,
            width: 200,
            height: 50);
        contextPopup.show(context, onHide: () {});
      }
    }
  }

  void _updateScaleFactor() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && lastSize != box.size) {
        lastSize = box.size;
        scaleNotifier.update(context, box.size, constraints!);
      }
    });
  }
}
