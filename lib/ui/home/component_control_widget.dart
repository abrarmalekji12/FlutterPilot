import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../components/component_impl.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../cubit/visual_box_drawer/visual_box_cubit.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../boundary_painter.dart';
import '../boundary_widget.dart';
import '../paint_tools/paint_tools.dart';
import 'cubit/home_cubit.dart';
import 'editing_view.dart';
import 'home_page.dart';

class ComponentControlWidget extends StatefulWidget {
  final GlobalKey rootKey;
  final ScaleNotifier scaleNotifier;

  const ComponentControlWidget(
      {required this.rootKey, required this.scaleNotifier})
      : super();

  @override
  State<ComponentControlWidget> createState() => _ComponentControlWidgetState();
}

class _ComponentControlWidgetState extends State<ComponentControlWidget>
    with DragDropPosition {
  late SelectionCubit _selectionCubit;
  final ValueNotifier<bool> isRendered = ValueNotifier(false);
  List<Rect?>? boundaries;
  List<FVBPainter>? paints;
  List<Component>? list;

  @override
  void initState() {
    _selectionCubit = context.read<SelectionCubit>();
    isRendered.value = false;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    isRendered.value = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (!isRendered.value)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // This check is important to avoid calling setState on a disposed widget.
          isRendered.value = true;
        }
      });
    return BlocBuilder<SelectionCubit, SelectionState>(
      builder: (context, state) {
        return BlocConsumer<VisualBoxCubit, VisualBoxState>(
          listener: (_, state) {
            if (state is VisualBoxUpdatedState) {
              list = _selectionCubit.selected.visualSelection
                  .where((element) =>
                      element is Movable &&
                      element is Holder &&
                      element.child?.boundary != null &&
                      element.boundary != null)
                  .toList(growable: false);
              boundaries = list
                  ?.map((selection) =>
                      (selection as Movable).moveType == MoveType.self
                          ? selection.boundary
                          : (selection as Holder).child?.boundary)
                  .toList(growable: false);
              paints = _selectionCubit.selected.visualSelection
                  .where((element) => element.boundary != null)
                  .whereType<FVBPainter>()
                  .toList(growable: false);
            }
          },
          buildWhen: (state1, state2) => state2 is VisualBoxUpdatedState,
          builder: (context, state) {
            if (_selectionCubit.selected.viewable != null) {
              return BlocBuilder<HomeCubit, HomeState>(
                buildWhen: (_, state) =>
                    state is HomeCustomComponentPreviewUpdatedState,
                builder: (context, state) {
                  return ListenableBuilder(
                      listenable:
                          Listenable.merge([widget.scaleNotifier, isRendered]),
                      builder: (context, _) {
                        if (isRendered.value) {
                          final box = (GlobalObjectKey(
                                  _selectionCubit.selected.viewable!.id)
                              .currentContext
                              ?.findRenderObject() as RenderBox?);
                          if (!(box?.hasSize ?? false)) {
                            return const Offstage();
                          }
                          final position = box?.localToGlobal(Offset.zero,
                              ancestor: widget.rootKey.currentContext
                                  ?.findRenderObject());
                          if (position != null) {
                            final factor = widget.scaleNotifier.scaleValue;
                            if (factor > 1)
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: position.dx - editHorizontalPadding,
                                  top: position.dy - editVerticalPadding,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.topLeft,
                                  children: [
                                    if (paints != null)
                                      for (final painter in paints!)
                                        Positioned(
                                          left: (painter as Component)
                                              .boundary!
                                              .left,
                                          top: (painter as Component)
                                                  .boundary!
                                                  .top -
                                              (34 * factor),
                                          child: PaintViewWidget(
                                            paint: painter,
                                            scaleNotifier: widget.scaleNotifier,
                                          ),
                                        ),
                                    for (final selection in _selectionCubit
                                        .selected.visualSelection
                                        .where((element) =>
                                            element is Resizable &&
                                            element.boundary != null)) ...[
                                      if (![ResizeType.verticalOnly].contains(
                                          (selection as Resizable)
                                              .resizeType)) ...[
                                        Positioned(
                                          left: selection.boundary!.left -
                                              resizeBarHalf,
                                          top: selection.boundary!.top -
                                              resizeBarHalf,
                                          child: ResizableCursor(
                                            axis: ResizeAxis.horizontal,
                                            upper: true,
                                            width: selection.boundary!.width,
                                            height: selection.boundary!.height,
                                            component: (selection as Resizable),
                                          ),
                                        ),
                                        Positioned(
                                          left: selection.boundary!.right -
                                              resizeBarHalf,
                                          top: selection.boundary!.top -
                                              resizeBarHalf,
                                          child: ResizableCursor(
                                            axis: ResizeAxis.horizontal,
                                            upper: false,
                                            width: selection.boundary!.width,
                                            height: selection.boundary!.height,
                                            component: (selection as Resizable),
                                          ),
                                        ),
                                      ],
                                      if (![ResizeType.horizontalOnly].contains(
                                          (selection as Resizable)
                                              .resizeType)) ...[
                                        Positioned(
                                          left: selection.boundary!.left -
                                              resizeBarHalf,
                                          top: selection.boundary!.bottom -
                                              resizeBarHalf,
                                          child: ResizableCursor(
                                            axis: ResizeAxis.vertical,
                                            upper: false,
                                            width: selection.boundary!.width,
                                            height: selection.boundary!.height,
                                            component: (selection as Resizable),
                                          ),
                                        ),
                                      ],

                                      /// Inclined
                                      if ((selection as Resizable).resizeType !=
                                          ResizeType.symmetricResize) ...[
                                        Positioned(
                                          left: selection.boundary!.left -
                                              resizeBarHalf,
                                          top: selection.boundary!.bottom -
                                              resizeBarHalf,
                                          child: ResizableCursor(
                                            axis:
                                                ResizeAxis.bottomLeftToTopRight,
                                            upper: true,
                                            width: resizeBarSize,
                                            height: resizeBarSize,
                                            component: (selection as Resizable),
                                          ),
                                        ),
                                        Positioned(
                                          left: selection.boundary!.right -
                                              resizeBarHalf,
                                          top: selection.boundary!.bottom -
                                              resizeBarHalf,
                                          child: ResizableCursor(
                                            axis:
                                                ResizeAxis.bottomRightToTopLeft,
                                            upper: true,
                                            width: resizeBarSize,
                                            height: resizeBarSize,
                                            component: (selection as Resizable),
                                          ),
                                        ),
                                        if ((selection as Resizable)
                                            .canUpdateRadius) ...[
                                          PosOffset(
                                            offset:
                                                selection.boundary!.topLeft +
                                                    ((selection as Resizable)
                                                            .visualOffset ??
                                                        radiusOffset),
                                            child: const RadiusCursor(),
                                          )
                                        ]
                                      ],
                                    ],
                                    if (list != null && boundaries != null)
                                      for (int i = 0;
                                          i < list!.length;
                                          i++) ...[
                                        Positioned(
                                          left: boundaries![i]!.left -
                                              resizeBarHalf,
                                          top: boundaries![i]!.top -
                                              resizeBarHalf,
                                          child: MovableCursor(
                                            width: boundaries![i]!.width,
                                            component: (list![i] as Movable),
                                          ),
                                        )
                                      ],
                                  ],
                                ),
                              );
                          }
                        }
                        return const Offstage();
                      });
                },
              );
            }
            return const Offstage();
          },
        );
      },
    );
  }
}
