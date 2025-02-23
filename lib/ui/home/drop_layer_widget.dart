import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/processor_component.dart';

import '../../bloc/component_drag/component_drag_bloc.dart';
import '../../bloc/state_management/state_management_bloc.dart';
import '../../common/drag_target.dart';
import '../../components/component_list.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../injector.dart';
import '../../models/component_selection.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/other_model.dart';
import '../../models/parameter_model.dart';
import '../../models/project_model.dart';
import '../../runtime_provider.dart';
import '../boundary_widget.dart';
import '../component_selection_dialog.dart';
import 'editing_view.dart';
import 'home_page.dart';

const double kDropBoxWidth = 50, kDropBoxHeight = 50;

class CustomNamedDropLayer {
  final Map<String, Rect> map;

  CustomNamedDropLayer(this.map);

  Rect evaluate(Rect rect, Size size) {
    final r = Rect.fromLTWH(
        point(rect.left, size.width),
        point(rect.top, size.height),
        point(rect.width, size.width),
        point(rect.height, size.height));
    return r;
  }

  double point(double t, double size) {
    final p = t.abs();
    final out = p > 1 ? p : (size * p);
    if (t < 0) {
      return size - out;
    }
    return out;
  }
}

final Map<String, CustomNamedDropLayer> dropLayerMap = {
  'AppBar': CustomNamedDropLayer({
    'leading': const Rect.fromLTWH(0, 0, 30, 1),
    'title': const Rect.fromLTWH(10, 0, 0.7, 1),
    'actions': const Rect.fromLTWH(-100, 0, 100, 1),
    'flexibleSpace': const Rect.fromLTWH(0, 0, 1, 1),
  }),
  'Scaffold': CustomNamedDropLayer(
    {
      'floatingActionButton': const Rect.fromLTWH(-110, -110, 100, 100),
      'bottomNavigationBar': const Rect.fromLTWH(0, -100, 1, 100),
      'bottomSheet': const Rect.fromLTWH(0, -250, 1, 250),
      'drawer': const Rect.fromLTWH(0, 0, 0.3, 1),
      'endDrawer': const Rect.fromLTWH(-0.3, 0, 0.3, 1),
      'appBar': const Rect.fromLTWH(0, 0, 1, 70),
      'body': const Rect.fromLTWH(0, 0, 1, 1),
    },
  )
};

class DropLayerWidget extends StatefulWidget {
  final FVBProject project;
  final ScaleNotifier scaleNotifier;
  final GlobalKey rootKey;

  const DropLayerWidget({
    super.key,
    required this.project,
    required this.scaleNotifier,
    required this.rootKey,
  });

  @override
  State<DropLayerWidget> createState() => _DropLayerWidgetState();
}

class _DropLayerWidgetState extends State<DropLayerWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComponentDragBloc, ComponentDragState>(
      builder: (context, state) {
        return Visibility(
          visible: state is ComponentDraggingState,
          child: ListenableBuilder(
              listenable: widget.scaleNotifier,
              builder: (context, _) {
                return Stack(
                  children: [
                    for (final screen in widget.project.screens)
                      ViewableDropLayer(
                        rootKey: widget.rootKey,
                        screen: screen,
                        scaleNotifier: widget.scaleNotifier,
                      ),
                    for (final screen in widget.project.customComponents)
                      ViewableDropLayer(
                        rootKey: widget.rootKey,
                        screen: screen,
                        scaleNotifier: widget.scaleNotifier,
                      )
                  ],
                );
              }),
        );
      },
    );
  }
}

double area(Component comp) {
  if (comp.boundary != null) {
    return (comp.boundary!.width * comp.boundary!.height);
  }
  return -1;
}

class ViewableDropLayer extends StatefulWidget {
  final GlobalKey rootKey;
  final Viewable screen;
  final ScaleNotifier scaleNotifier;

  const ViewableDropLayer(
      {super.key,
      required this.rootKey,
      required this.screen,
      required this.scaleNotifier});

  @override
  State<ViewableDropLayer> createState() => _ViewableDropLayerState();
}

class _ViewableDropLayerState extends State<ViewableDropLayer>
    with DragDropPosition {
  final _focus = FocusNode();
  String? dragKey;
  final ValueNotifier<int?> dragIndex = ValueNotifier(null);
  Component? lastDragComponent;
  late OperationCubit _operationCubit;
  Timer? dragHoldTimer;

  late SelectionCubit _componentSelectionCubit;
  late CreationCubit _creationCubit;
  late StateManagementBloc _stateManagementBloc;

  @override
  void initState() {
    _operationCubit = context.read<OperationCubit>();

    _componentSelectionCubit = context.read<SelectionCubit>();
    _creationCubit = context.read<CreationCubit>();
    _stateManagementBloc = context.read<StateManagementBloc>();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = selectedConfig!.width;
    final screenHeight = selectedConfig!.height;
    // final factorX = selectedConfig!.width / screenWidth;
    // final factorY = selectedConfig!.height / screenHeight;
    final box = (GlobalObjectKey(widget.screen.id)
        .currentContext
        ?.findRenderObject() as RenderBox?);
    if (!(box?.hasSize ?? false)) {
      return const Offstage();
    }
    final position = box?.localToGlobal(Offset.zero,
        ancestor: widget.rootKey.currentContext?.findRenderObject());
    if (position == null) {
      return const Center(
        child: Offstage(),
      );
    }
    final List<Component> dropList = [];

    widget.screen.rootComponent?.forEachWithClones((p0) {
      if ((p0.boundary != null &&
              ((p0 is Holder) ||
                  p0 is MultiHolder ||
                  p0 is CustomNamedHolder ||
                  p0.componentParameters.isNotEmpty)) &&
          !dropList.contains(p0)) {
        dropList.add(p0);
      }
      return false;
    });
    dropList.sort((a, b) {
      return area(a) < area(b) ? 1 : -1;
    });
    return ViewableProvider(
      screen: widget.screen,
      child: Positioned(
        left: position.dx - editHorizontalPadding,
        top: position.dy - editVerticalPadding,
        width: box?.size.width,
        height: box?.size.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (widget.screen.rootComponent == null)
              Center(
                child: CustomDragTarget(
                  onAccept: (object, position) {
                    dragHoldTimer?.cancel();
                    if (_focus.hasFocus) {
                      _focus.unfocus();
                    }
                    keyboardInput = false;
                    Component? temp;
                    if (object is String) {
                      temp = componentList.containsKey(object)
                          ? componentList[object]!()
                          : _operationCubit.project!.customComponents
                              .firstWhere((comp) => comp.name == object)
                              .createInstance(null);
                      temp.onFreshAdded();
                    } else if (object is FavouriteModel) {
                      temp = _operationCubit.favouriteInComponent(object);
                    } else if (object is Component) {
                      temp =
                          object.clone(null, connect: false, deepClone: true);
                    } else if (object is SameComponent) {
                      temp = object.component
                          .clone(null, connect: false, deepClone: true);
                    } else {
                      return;
                    }
                    if (temp.parent == null)
                      _operationCubit.revertWork.add(null, () {
                        _operationCubit.update();
                        _creationCubit.changedComponent();
                        WidgetsBinding.instance
                            .addPostFrameCallback((timeStamp) {
                          _componentSelectionCubit.changeComponentSelection(
                              ComponentSelectionModel.unique(
                                  temp!, temp.getLastRoot(),
                                  screen: widget.screen));
                        });
                      }, (old) {
                        setSearchRoot(_operationCubit, widget.screen, null);
                        _operationCubit.update();
                        _creationCubit.changedComponent();
                      });
                  },
                  onMove: (details) {
                    if (!_focus.hasFocus) {
                      _focus.requestFocus();
                    }
                  },
                  onLeave: (details) {
                    keyboardInput = false;
                    if (_focus.hasFocus) {
                      _focus.unfocus();
                    }
                  },
                  onWillAccept: (comp, position) {
                    if (comp is! CustomComponent &&
                        comp is! String &&
                        comp is! Component &&
                        comp is! SameComponent &&
                        comp is! FavouriteModel) {
                      return false;
                    }
                    return true;
                  },
                  builder: (_, candidate, rejected, position) {
                    if (candidate.isNotEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                            color: ColorAssets.theme.withOpacity(0.1),
                            border:
                                Border.all(color: ColorAssets.theme, width: 5),
                            borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.topLeft,
                        width: screenWidth,
                        height: screenHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Add Root',
                                    style: AppFontStyle.lato(16,
                                        color: ColorAssets.theme,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    height: 30,
                                    child: VerticalDivider(
                                      thickness: 2,
                                      color: ColorAssets.theme,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      width: screenWidth,
                      height: screenHeight,
                    );
                  },
                ),
              )
            else
              for (final model in dropList)
                if (model is! Holder || model.child == null)
                  Positioned(
                    left: model.boundary!.left,
                    top: model.boundary!.top,
                    // key: GlobalObjectKey(model.boundary!),
                    child: CustomDragTarget(onAccept: (object, position) {
                      if (_focus.hasFocus) {
                        _focus.unfocus();
                      }
                      String? named;
                      ComponentParameter? comp;

                      keyboardInput = false;
                      final original = model.getOriginal()!;
                      if (dragKey != null) {
                        named = dragKey;
                      } else if (dragIndex.value != null) {
                        if (model is CustomNamedHolder) {
                          if (dragIndex.value! < model.childMap.length) {
                            named =
                                model.childMap.keys.elementAt(dragIndex.value!);
                          } else if (dragIndex.value! - model.childMap.length <
                              model.childrenMap.length) {
                            named = model.childrenMap.keys.elementAt(
                                dragIndex.value! - model.childMap.length);
                          }
                        } else if (model.type == 1 &&
                            model.componentParameters.isNotEmpty) {
                          comp = original.componentParameters[dragIndex.value!];
                        }
                      } else {
                        return;
                      }
                      Component? temp;
                      if (object is String) {
                        temp = componentList.containsKey(object)
                            ? componentList[object]!()
                            : _operationCubit.project!.customComponents
                                .firstWhere((comp) => comp.name == object)
                                .createInstance(null);
                        temp.onFreshAdded();
                      } else if (object is FavouriteModel) {
                        temp = _operationCubit.favouriteInComponent(object);
                      } else if (object is Component) {
                        temp =
                            object.clone(null, connect: false, deepClone: true);
                      } else if (object is SameComponent) {
                        temp = object.component
                            .clone(null, connect: false, deepClone: true);
                      } else {
                        return;
                      }
                      if (temp.parent == null)
                        _operationCubit.addInSameComponentList(temp);
                      final ancestor = original.getRootCustomComponent(
                              _operationCubit.project!, widget.screen) ??
                          widget.screen.rootComponent!;

                      _operationCubit.reversibleComponentOperation(
                          widget.screen, () async {
                        await _operationCubit.addOperation(
                            context, original, temp!, ancestor,
                            undo: true,
                            customNamed: named,
                            index: dragIndex.value,
                            componentParameter: comp,
                            componentParameterOperation: comp != null);
                        _operationCubit.update();

                        _stateManagementBloc.add(StateManagementRefreshEvent(
                            original.id, RuntimeMode.edit));
                        WidgetsBinding.instance
                            .addPostFrameCallback((timeStamp) {
                          _componentSelectionCubit.changeComponentSelection(
                              ComponentSelectionModel.unique(temp!, ancestor,
                                  screen: widget.screen));
                        });
                      }, ancestor);
                    }, onMove: (details) {
                      if (!_focus.hasFocus) {
                        _focus.requestFocus();
                      }
                    }, onLeave: (details) {
                      dragHoldTimer?.cancel();
                      keyboardInput = false;
                      if (_focus.hasFocus) {
                        _focus.unfocus();
                      }
                    }, onWillAccept: (comp, position) {
                      if (model is Holder && model.child != null) {
                        return false;
                      }
                      if (comp is! CustomComponent &&
                          comp is! String &&
                          comp is! Component &&
                          comp is! SameComponent &&
                          comp is! FavouriteModel) {
                        return false;
                      }
                      return true;
                    }, builder: (_, candidate, rejected, p) {
                      dragHoldTimer?.cancel();
                      final newComponent = lastDragComponent == null ||
                          lastDragComponent != model;
                      lastDragComponent = model;

                      if (newComponent) {
                        dragKey = null;
                      }
                      final sc = widget.scaleNotifier.scaleValue;
                      if (p != null && candidate.isNotEmpty) {
                        p = p -
                            (_.findRenderObject() as RenderBox)
                                .localToGlobal(Offset.zero);
                        p = (p *
                            (widget.scaleNotifier.scaleFactor ?? 1) /
                            widget.scaleNotifier.value);
                        Rect? rect;
                        int maxLength = 0;
                        if (model is CustomNamedHolder &&
                            dropLayerMap.containsKey(model.name)) {
                          final pos = p - model.boundary!.topLeft;
                          final layer = dropLayerMap[model.name]!;

                          final entry = layer.map.entries.firstWhereOrNull(
                              (element) => layer
                                  .evaluate(element.value, model.boundary!.size)
                                  .contains(pos));
                          dragKey = entry?.key;
                          if (entry != null) {
                            rect = layer.evaluate(
                                entry.value, model.boundary!.size);
                          }
                        } else {
                          final (t, length) = getIndex(model, p);
                          maxLength = length;
                          if (newComponent) {
                            dragIndex.value = t;
                          }
                        }
                        if (newComponent || dragIndex.value == null) {
                          dragIndex.value = 0;
                        }
                        final name = (candidate[0]! is String)
                            ? candidate[0]!.toString()
                            : (candidate[0]! is Component
                                ? (candidate[0]! as Component).name
                                : (candidate[0]! is FavouriteModel
                                    ? (candidate[0]! as FavouriteModel)
                                        .component
                                        .name
                                    : ''));
                        if (model is MultiHolder || model is CustomNamedHolder)
                          dragHoldTimer = Timer.periodic(
                              const Duration(milliseconds: 800), (timer) {
                            dragIndex.value =
                                (dragIndex.value! + 1) % (maxLength + 1);
                          });
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (rect != null)
                              Container(
                                margin: EdgeInsets.only(
                                  left: rect.left,
                                  top: rect.top,
                                ),
                                decoration: BoxDecoration(
                                    color: ColorAssets.theme.withOpacity(0.1),
                                    border: Border.all(
                                        color: ColorAssets.theme,
                                        width: sc * 1.5),
                                    borderRadius: BorderRadius.circular(10)),
                                alignment: Alignment.center,
                                width: max(rect.width, kDropBoxWidth),
                                height: max(rect.height, kDropBoxHeight),
                                padding: EdgeInsets.all(8 * sc),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                    color: ColorAssets.theme.withOpacity(0.1),
                                    border: Border.all(
                                        color: ColorAssets.theme,
                                        width: sc * 1.5),
                                    borderRadius: BorderRadius.circular(10)),
                                alignment: Alignment.topLeft,
                                width:
                                    max(model.boundary!.width, kDropBoxWidth),
                                height:
                                    max(model.boundary!.height, kDropBoxHeight),
                                padding: EdgeInsets.all(8 * sc),
                              ),
                            Container(
                              margin: EdgeInsets.only(left: 20 * sc),
                              padding: EdgeInsets.all(4 * sc),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: theme.background1,
                                boxShadow: kElevationToShadow[3],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    model.name,
                                    style: AppFontStyle.lato(sc * 11,
                                        color: ColorAssets.theme,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 20 * sc,
                                    child: VerticalDivider(
                                      thickness: sc,
                                      color: ColorAssets.theme,
                                    ),
                                  ),
                                  ValueListenableBuilder(
                                      valueListenable: dragIndex,
                                      builder: (context, index, _) =>
                                          Stack(children: [
                                            if (model is Holder)
                                              HolderDropWidget(
                                                model: model,
                                                name: name,
                                                sc: sc,
                                              )
                                            else if (model is MultiHolder)
                                              MultiHolderDropWidget(
                                                name: name,
                                                model: model,
                                                index: dragIndex.value!,
                                                sc: sc,
                                              )
                                            else if (model
                                                is CustomNamedHolder) ...[
                                              if (dragKey != null)
                                                Text(
                                                  dragKey!,
                                                  style: AppFontStyle.lato(
                                                      11 * sc,
                                                      color: ColorAssets.theme,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                )
                                              else if (dragIndex.value != null)
                                                CustomNamedHolderDropWidget(
                                                  name: name,
                                                  model: model,
                                                  index: dragIndex.value!,
                                                  sc: sc,
                                                )
                                            ] else
                                              ComponentParameterDropWidget(
                                                component: model,
                                                index: dragIndex.value!,
                                                sc: sc,
                                              )
                                          ]))
                                ],
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .scale(
                                begin: const Offset(0.5, 0.5),
                                delay: const Duration(milliseconds: 70),
                                duration: const Duration(milliseconds: 120))
                            .fadeIn(
                                duration: const Duration(milliseconds: 200));
                      }
                      return Container(
                        color: Colors.transparent,
                        width: max(model.boundary?.width ?? 0, kDropBoxWidth),
                        height:
                            max(model.boundary?.height ?? 0, kDropBoxHeight),
                      );
                    }),
                  ),
          ],
        ),
      ),
    );
  }
}
