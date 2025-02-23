import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get_rx/src/rx_workers/utils/debouncer.dart';

import '../bloc/state_management/state_management_bloc.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/parameter_build_cubit/parameter_build_cubit.dart';
import '../cubit/screen_config/screen_config_cubit.dart';
import '../cubit/visual_box_drawer/visual_box_cubit.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../runtime_provider.dart';
import 'boundary_painter.dart';
import 'home/drop_layer_widget.dart';
import 'home/editing_view.dart';
import 'visual_model.dart';

mixin DragDropPosition {
  static const part = 10.0;
  static const horizontalPart = 80.0;
  double place = 0;
  bool keyboardInput = false;
  int keyboardIndex = 0;

  (int?, int) getIndex(Component model, Offset position) {
    int? index;
    if (model is MultiHolder) {
      final part = model.direction == Axis.vertical
          ? (model.boundary!.height / (model.children.length + 1))
          : model.boundary!.width / (model.children.length + 1);
      if (keyboardInput) {
        index = keyboardIndex;
      } else {
        if (model.direction == Axis.vertical) {
          index = ((position.dy - model.boundary!.top) ~/ part);
        } else {
          index = ((position.dx - model.boundary!.left) ~/ part);
        }
      }
      if (index > model.children.length) {
        index = model.children.length;
      } else if (index < 0) {
        index = 0;
      }
      keyboardIndex = index;
    } else if (model is CustomNamedHolder) {
      final list = model.childMap.keys.toList(growable: false) +
          model.childrenMap.keys.toList(growable: false);
      if (keyboardInput) {
        index = keyboardIndex;
      } else {
        if (model.direction == Axis.vertical) {
          index = (position.dy - model.boundary!.top) ~/
              (max(model.boundary!.height, kDropBoxHeight) / (list.length + 1));
        } else {
          index = (position.dx - model.boundary!.left) ~/
              (max(model.boundary!.width, kDropBoxWidth) / (list.length + 1));
        }
      }
      if (index >= list.length) {
        index = list.length - 1;
      } else if (index < 0) {
        index = 0;
      }
      keyboardIndex = index;
    } else if (model.componentParameters.isNotEmpty) {
      index = (position.dy - model.boundary!.top) ~/
          (max(model.boundary!.height, kDropBoxHeight) /
              (model.componentParameters.length));
      if (index > model.componentParameters.length) {
        index = model.componentParameters.length;
      } else if (index < 0) {
        index = 0;
      }
    }
    return (
      index,
      switch (model) {
        (MultiHolder m) => m.children.length,
        (CustomNamedHolder c) => c.childMap.length + c.childrenMap.length,
        (Holder _) => 1,
        _ => 0
      }
    );
  }
}

mixin Viewable {
  Processor get processor;

  Component? get rootComponent;

  String get id;

  set id(String id);

  String get name;

  Map<String, FVBVariable> get variables;

  String get actionCode;

  set rootComponent(Component? component);

  set actionCode(String code);
}

class BoundaryWidget extends StatefulWidget {
  final ScaleNotifier scaleNotifier;

  const BoundaryWidget({Key? key, required this.scaleNotifier})
      : super(key: key);

  @override
  State<BoundaryWidget> createState() => _BoundaryWidgetState();
}

class _BoundaryWidgetState extends State<BoundaryWidget> {
  late SelectionCubit _componentSelectionCubit;
  late VisualBoxCubit _visualBoxCubit;

  late Viewable screen;

  @override
  void initState() {
    _componentSelectionCubit = context.read<SelectionCubit>();
    _visualBoxCubit = context.read<VisualBoxCubit>();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    screen = ViewableProvider.maybeOf(context)!;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: BlocBuilder<SelectionCubit, SelectionState>(
        builder: (context, state) {
          return BlocBuilder<VisualBoxCubit, VisualBoxState>(
            builder: (context, state) {
              final List<Boundary> boundaries = [];
              if (_componentSelectionCubit.selected.viewable == screen) {
                boundaries.addAll(getAllBoundaries(context));
              } else if (_componentSelectionCubit.selected.viewable == null &&
                  _componentSelectionCubit.selected.root
                      .isAttachedToScreen(screen)) {
                boundaries.addAll(getAllBoundaries(context));
              }

              final errorBoundary = (_visualBoxCubit
                      .analysisErrors[selectedConfig!]
                      ?.where((element) => element.screen == screen)
                      .map((e) => Boundary(
                          e.component.boundary ?? Rect.zero, e.component,
                          errorMessage: 'Analyzer: ${e.message}'))
                      .toList() ??
                  []);
              final List<Boundary> hoverBounds =
                  state is VisualBoxHoverUpdatedState && state.screen == screen
                      ? state.boundaries.toList()
                      : [];
              return Stack(clipBehavior: Clip.none, children: [
                ListenableBuilder(
                    listenable: widget.scaleNotifier,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: BoundaryPainter(
                          boundaries: boundaries,
                          errorBoundaries: errorBoundary,
                          hoverBoundaries: hoverBounds,
                          scale: widget.scaleNotifier.scaleValue,
                          context: context,
                        ),
                      );
                    }),
                for (final boundary
                    in errorBoundary.where((element) => element.onTap != null))
                  ListenableBuilder(
                      listenable: widget.scaleNotifier,
                      builder: (context, _) {
                        final sc = widget.scaleNotifier.scaleValue;
                        final gap = 8 * sc;
                        final w = boundary.rect.width;
                        final h = 20 * sc;
                        final l = boundary.rect.center.dx - (w / 2);
                        final t = boundary.rect.bottom + gap;
                        return Positioned(
                          left: l,
                          top: t,
                          width: w,
                          height: h,
                          child: InkWell(
                            onTap: boundary.onTap,
                            child: SizedBox(
                              width: w,
                              height: h,
                            ),
                          ),
                        );
                      })
              ]);
            },
          );
        },
      ),
    );
  }

  List<Boundary> getAllBoundaries(BuildContext context) {
    final list = _componentSelectionCubit.selected.visualSelection
        .where((element) => element.boundary != null)
        .where((element) => GlobalObjectKey(element).currentContext != null)
        .map<Boundary>((e) => Boundary(e.boundary!, e))
        .toList(growable: false);
    if (list.isEmpty) {
      // _componentSelectionCubit
      //     .currentSelected.propertySelection.cloneElements.removeWhere((element) => GlobalObjectKey(element).currentContext==null);
      final outList = _componentSelectionCubit
          .selected.treeSelection[0].cloneElements
          .where((element) => element.boundary != null)
          .where((element) => GlobalObjectKey(element).currentContext != null)
          .map((e) => Boundary(e.boundary!, e))
          .toList(growable: false);
      return outList;
    }
    return list;
  }
}

double scaleByFactor(double value, double? factor) {
  return 1.4 * (factor != null ? factor : 1) / value;
}

enum ResizeAxis {
  horizontal,
  vertical,
  bottomLeftToTopRight,
  bottomRightToTopLeft,
  topRightToBottomLeft,
  topLeftToBottomRight
}

class MovableCursor extends StatefulWidget {
  final double width;
  final Movable component;

  const MovableCursor({Key? key, required this.width, required this.component})
      : super(key: key);

  @override
  State<MovableCursor> createState() => _MovableCursorState();
}

class _MovableCursorState extends State<MovableCursor> {
  final Debouncer _debounce =
      Debouncer(delay: const Duration(milliseconds: 200));

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        widget.component.onMove
            .call(Offset(event.localDelta.dx, event.localDelta.dy));
        context.read<OperationCubit>().updateRootOnFirestore();
        if (mounted) {
          context.read<StateManagementBloc>().add(StateManagementUpdateEvent(
                (widget.component as Component),
                RuntimeMode.edit,
              ));
          _debounce.call(() {
            context
                .read<ParameterBuildCubit>()
                .paramAltered(widget.component.movableAffectedParameters);
          });
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: AbsorbPointer(
          child: Container(
            height: resizeBarSize,
            width: widget.width,
          ),
        ),
      ),
    );
  }
}

class RadiusCursor extends StatefulWidget {
  const RadiusCursor({Key? key}) : super(key: key);

  @override
  State<RadiusCursor> createState() => _RadiusCursorState();
}

class _RadiusCursorState extends State<RadiusCursor> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {},
      onPointerMove: (event) {},
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          width: 30,
          height: 30,
        ),
      ),
    );
  }
}

class ResizableCursor extends StatefulWidget {
  final ResizeAxis axis;
  final double width;
  final double height;
  final bool upper;
  final Resizable component;

  const ResizableCursor(
      {Key? key,
      required this.axis,
      required this.width,
      required this.height,
      required this.upper,
      required this.component})
      : super(key: key);

  @override
  State<ResizableCursor> createState() => _ResizableCursorState();
}

const resizeBarSize = 15.0;
const resizeBarHalf = resizeBarSize / 2;

class _ResizableCursorState extends State<ResizableCursor> {
  final Debouncer _debounce =
      Debouncer(delay: const Duration(milliseconds: 200));

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        if (widget.axis == ResizeAxis.horizontal) {
          widget.component.onResize
              .call(Size(event.localDelta.dx * (widget.upper ? -1 : 1), 0));
        } else if (widget.axis == ResizeAxis.vertical) {
          widget.component.onResize
              .call(Size(0, event.localDelta.dy * (widget.upper ? -1 : 1)));
        } else if (widget.axis == ResizeAxis.bottomLeftToTopRight) {
          widget.component.onResize.call(Size(0, -event.localDelta.dy));
        } else if (widget.axis == ResizeAxis.bottomRightToTopLeft) {
          widget.component.onResize
              .call(Size(event.localDelta.dx, event.localDelta.dy));
        }
        context.read<OperationCubit>().updateRootOnFirestore();
        if (mounted) {
          context.read<StateManagementBloc>().add(StateManagementUpdateEvent(
                (widget.component as Component),
                RuntimeMode.edit,
              ));
          _debounce.call(() {
            context
                .read<ParameterBuildCubit>()
                .paramAltered(widget.component.resizeAffectedParameters);
          });
        }
      },
      child: MouseRegion(
        cursor: cursor,
        child: AbsorbPointer(
          child: Container(
            width: widget.axis == ResizeAxis.vertical
                ? max(widget.width, 20)
                : resizeBarSize,
            height: widget.axis == ResizeAxis.vertical
                ? resizeBarSize
                : max(widget.height, 20),
          ),
        ),
      ),
    );
  }

  MouseCursor get cursor {
    if (widget.axis == ResizeAxis.vertical) {
      return SystemMouseCursors.resizeUpDown;
    } else if (widget.axis == ResizeAxis.horizontal) {
      return SystemMouseCursors.resizeLeftRight;
    } else if (widget.axis == ResizeAxis.bottomLeftToTopRight) {
      return SystemMouseCursors.resizeUpRightDownLeft;
    } else {
      return SystemMouseCursors.resizeUpLeftDownRight;
    }
  }
}

class CustomNamedHolderDropWidget extends StatelessWidget {
  final String name;
  final int index;
  final CustomNamedHolder model;
  final double sc;

  const CustomNamedHolderDropWidget(
      {Key? key,
      required this.name,
      required this.model,
      required this.index,
      required this.sc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final list = model.childMap.keys.toList(growable: false) +
        model.childrenMap.keys.map((e) => '$e (list)').toList(growable: false);
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(bottom: sc * 2),
          width: 72 * sc,
          child: ListView.builder(
            itemBuilder: (_, i) {
              return Text(
                list[i],
                style: AppFontStyle.lato(
                  11 * sc,
                  color: index == i ? ColorAssets.theme : Colors.grey.shade600,
                  fontWeight: index == i ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            },
            itemCount: list.length,
            shrinkWrap: true,
          ),
        )
      ],
    );
  }
}

class ComponentParameterDropWidget extends StatelessWidget {
  final Component component;
  final int index;
  final double sc;

  const ComponentParameterDropWidget(
      {Key? key,
      required this.component,
      required this.index,
      required this.sc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final list = component.componentParameters;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(bottom: sc),
          width: sc * 70,
          child: ListView.builder(
            itemBuilder: (_, i) {
              return Text(
                list[i].displayName!,
                style: AppFontStyle.lato(9 * sc,
                    color:
                        index == i ? ColorAssets.theme : Colors.grey.shade800,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              );
            },
            itemCount: list.length,
            shrinkWrap: true,
          ),
        )
      ],
    );
  }
}

class MultiHolderDropWidget extends StatelessWidget {
  final String name;
  final int index;
  final MultiHolder model;
  final double sc;

  const MultiHolderDropWidget(
      {Key? key,
      required this.name,
      required this.model,
      required this.index,
      required this.sc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(bottom: sc * 2),
          width: 75 * sc,
          child: ListView.separated(
            itemBuilder: (_, i) {
              if (i - 1 < 0 || i - 1 >= model.children.length) {
                return const Offstage();
              }
              return Padding(
                padding: EdgeInsets.symmetric(vertical: sc * 4),
                child: Text(
                  model.children[i - 1].name,
                  style: AppFontStyle.lato(10 * sc,
                      color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
            separatorBuilder: (BuildContext context, int i) {
              if (index == i) {
                return Container(
                  padding: EdgeInsets.all(2 * sc),
                  decoration: BoxDecoration(
                    color: ColorAssets.theme,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    name,
                    style: AppFontStyle.lato(10 * sc,
                        color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }
              return const Offstage();
            },
            itemCount: model.children.length + 2,
            shrinkWrap: true,
          ),
        )
      ],
    );
  }
}

class HolderDropWidget extends StatelessWidget {
  final Holder model;
  final String name;
  final double sc;

  const HolderDropWidget(
      {Key? key, required this.model, required this.name, required this.sc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: sc * 2),
          child: Text(
            name,
            style: AppFontStyle.lato(11 * sc,
                color: ColorAssets.theme, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (model.child != null)
          Padding(
            padding: EdgeInsets.only(bottom: sc * 2),
            child: Text(
              model.child!.name,
              style: AppFontStyle.lato(10 * sc,
                      color: ColorAssets.theme, fontWeight: FontWeight.bold)
                  .copyWith(decoration: TextDecoration.lineThrough),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
