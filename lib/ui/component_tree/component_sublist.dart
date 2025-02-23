import 'dart:convert';

import 'package:dart_style/dart_style.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get.dart';

import '../../bloc/state_management/state_management_bloc.dart';
import '../../common/common_methods.dart';
import '../../common/custom_popup_menu_button.dart';
import '../../common/drag_target.dart';
import '../../common/extension_util.dart';
import '../../common/web/io_lib.dart';
import '../../components/component_list.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../injector.dart';
import '../../models/builder_component.dart';
import '../../models/component_selection.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/global_component.dart';
import '../../models/operation_model.dart';
import '../../models/other_model.dart';
import '../../models/parameter_model.dart';
import '../../runtime_provider.dart';
import '../../user_session.dart';
import '../boundary_widget.dart';
import '../component_selection_dialog.dart';
import '../fvb_code_editor.dart';
import '../parameter_ui.dart';
import 'component_tree.dart';

class ComponentTreeSublistWidget extends StatefulWidget {
  final Component component, ancestor;
  final Component? parent;
  final SelectionCubit selectionCubit;
  final OperationCubit operationCubit;
  final CreationCubit creationCubit;
  final ComponentParameter? componentParameter;
  final String? named;

  const ComponentTreeSublistWidget(
      {Key? key,
      this.componentParameter,
      required this.component,
      required this.parent,
      required this.ancestor,
      required this.selectionCubit,
      required this.operationCubit,
      required this.creationCubit,
      required this.named})
      : super(key: key);

  @override
  State<ComponentTreeSublistWidget> createState() =>
      _ComponentTreeSublistWidgetState();
}

class _ComponentTreeSublistWidgetState
    extends State<ComponentTreeSublistWidget> {
  final Debounce _saveCode = Debounce(const Duration(milliseconds: 300));
  late Viewable _viewable;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _viewable = ViewableProvider.maybeOf(context)!;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final open = (widget.operationCubit.expandedTree[widget.component] ?? true);
    if (widget.component is MultiHolder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnHoverMenuChangeWidget(
            buildWidget: (showMenu) => Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    widget.operationCubit.expandedTree[widget.component] =
                        (!(widget.operationCubit
                                .expandedTree[widget.component] ??
                            true));
                    setState(() {});
                  },
                  child: Icon(
                    open ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                    color: open ? theme.dropDownColor1 : theme.dropDownColor2,
                    size: 18,
                  ),
                ),
                Flexible(
                  child: CustomDragTarget(
                    onWillAccept: (data, _) {
                      return data is String ||
                          data is FavouriteModel ||
                          data is SameComponent ||
                          (data is Component &&
                              data != widget.component &&
                              !(widget.component as MultiHolder)
                                  .children
                                  .contains(data));
                    },
                    onAccept: (object, _) {
                      bool removeOld = true;
                      if (!shouldRemoveFromOldAncestor(object!)) {
                        object = getComponentFromDragData(context, object);
                        removeOld = false;
                      }
                      assert(object is Component);
                      widget.operationCubit.reversibleComponentOperation(
                          ViewableProvider.maybeOf(context)!, () async {
                        if (removeOld)
                          widget.operationCubit.removeAllComponent(
                              object as Component, widget.ancestor,
                              clear: false);
                        await widget.operationCubit.addOperation(
                          context,
                          widget.component,
                          object as Component,
                          widget.ancestor,
                          undo: true,
                        );
                        widget.operationCubit.updateState(widget.ancestor);
                        widget.creationCubit
                            .changedComponent(ancestor: widget.ancestor);
                        widget.selectionCubit.changeComponentSelection(
                            ComponentSelectionModel.unique(
                                object, widget.ancestor,
                                screen: _viewable));
                      }, widget.ancestor);
                    },
                    builder: (context, list1, list2, _) {
                      if (list1.isNotEmpty) {
                        return OnDragWidget(
                          component: widget.component,
                        );
                      }
                      return Row(
                        children: [
                          ComponentTile(
                            component: widget.component,
                            ancestor: widget.ancestor,
                            componentSelectionCubit: widget.selectionCubit,
                            parameter: widget.componentParameter,
                            named: widget.named,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (showMenu) ...[
                  const SizedBox(
                    width: 4,
                  ),
                  OperationMenu(
                    component: widget.component,
                    ancestor: widget.ancestor,
                    componentParameter: widget.componentParameter,
                    operationCubit: widget.operationCubit,
                    creationCubit: widget.creationCubit,
                    componentSelectionCubit: widget.selectionCubit,
                  )
                ]
              ],
            ),
          ),
          if ((widget.component as MultiHolder).children.isNotEmpty)
            Visibility(
              visible:
                  widget.operationCubit.expandedTree[widget.component] ?? true,
              child: MultipleChildWidget(
                  component: widget.component,
                  ancestor: widget.ancestor,
                  componentParameter: null,
                  named: null,
                  children: (widget.component as MultiHolder).children,
                  componentOperationCubit: widget.operationCubit,
                  componentSelectionCubit: widget.selectionCubit,
                  componentCreationCubit: widget.creationCubit),
            ),
          if (widget.component.componentParameters.isNotEmpty)
            ComponentParameterWidget(
                component: widget.component,
                ancestor: widget.ancestor,
                componentOperationCubit: widget.operationCubit,
                componentSelectionCubit: widget.selectionCubit,
                componentCreationCubit: widget.creationCubit)
        ],
      );
    } else if (widget.component is Holder) {
      return Column(
        children: [
          OnHoverMenuChangeWidget(
              buildWidget: (showMenu) => Row(
                    children: [
                      Flexible(
                        child: CustomDragTarget(onWillAccept: (data, _) {
                          return data is String ||
                              data is FavouriteModel ||
                              data is SameComponent ||
                              (data is Component &&
                                  data != widget.component &&
                                  data != (widget.component as Holder).child);
                        }, onAccept: (object, _) {
                          bool removeOld = true;
                          if (!shouldRemoveFromOldAncestor(object!)) {
                            object = getComponentFromDragData(context, object);
                            removeOld = false;
                          }
                          assert(object is Component);
                          widget.operationCubit.reversibleComponentOperation(
                              ViewableProvider.maybeOf(context)!, () async {
                            if (removeOld)
                              widget.operationCubit.removeAllComponent(
                                  object as Component, widget.ancestor,
                                  clear: false);
                            await widget.operationCubit.addOperation(
                              context,
                              widget.component,
                              object as Component,
                              widget.ancestor,
                              undo: true,
                            );
                            widget.creationCubit
                                .changedComponent(ancestor: widget.ancestor);
                            widget.operationCubit.updateState(widget.ancestor);
                            widget.selectionCubit.changeComponentSelection(
                                ComponentSelectionModel.unique(
                                    object, widget.ancestor,
                                    screen: _viewable));
                          }, widget.ancestor);
                        }, builder: (context, list1, list2, _) {
                          if (list1.isNotEmpty) {
                            return OnDragWidget(
                              component: widget.component,
                            );
                          }
                          return Row(
                            children: [
                              ComponentTile(
                                component: widget.component,
                                ancestor: widget.ancestor,
                                componentSelectionCubit: widget.selectionCubit,
                                parameter: widget.componentParameter,
                                named: widget.named,
                              ),
                            ],
                          );
                        }),
                      ),
                      if (showMenu) ...[
                        const SizedBox(
                          width: 4,
                        ),
                        OperationMenu(
                          component: widget.component,
                          ancestor: widget.ancestor,
                          componentParameter: widget.componentParameter,
                          operationCubit: widget.operationCubit,
                          creationCubit: widget.creationCubit,
                          componentSelectionCubit: widget.selectionCubit,
                        )
                      ]
                    ],
                  )),
          if ((widget.component as Holder).child != null)
            SingleChildWidget(
                component: widget.component,
                ancestor: widget.ancestor,
                componentParameter: widget.componentParameter,
                child: (widget.component as Holder).child!,
                componentOperationCubit: widget.operationCubit,
                componentSelectionCubit: widget.selectionCubit,
                componentCreationCubit: widget.creationCubit),
          if (widget.component.componentParameters.isNotEmpty)
            ComponentParameterWidget(
                component: widget.component,
                ancestor: widget.ancestor,
                componentOperationCubit: widget.operationCubit,
                componentSelectionCubit: widget.selectionCubit,
                componentCreationCubit: widget.creationCubit)
        ],
      );
    } else if (widget.component is CustomNamedHolder) {
      return Column(
        children: [
          OnHoverMenuChangeWidget(
              buildWidget: (showMenu) => Row(
                    children: [
                      ComponentTile(
                        component: widget.component,
                        ancestor: widget.ancestor,
                        componentSelectionCubit: widget.selectionCubit,
                        parameter: widget.componentParameter,
                        named: widget.named,
                      ),
                      if (showMenu) ...[
                        const SizedBox(
                          width: 4,
                        ),
                        OperationMenu(
                          component: widget.component,
                          customNamed: null,
                          componentParameter: widget.componentParameter,
                          ancestor: widget.ancestor,
                          operationCubit: widget.operationCubit,
                          creationCubit: widget.creationCubit,
                          componentSelectionCubit: widget.selectionCubit,
                        ),
                      ]
                    ],
                  )),
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(width: 0.7, color: theme.line),
              ),
            ),
            padding: const EdgeInsets.only(
              left: 5,
            ),
            child: Column(children: [
              for (final child
                  in (widget.component as CustomNamedHolder).childMap.keys) ...[
                Column(
                  children: [
                    OnHoverMenuChangeWidget(
                        buildWidget: (showMenu) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomDragTarget(
                                  onAccept: (object, _) {
                                    bool removeOld = true;
                                    if (!shouldRemoveFromOldAncestor(object!)) {
                                      object = getComponentFromDragData(
                                          context, object);
                                      removeOld = false;
                                    }
                                    assert(object is Component);
                                    widget.operationCubit
                                        .reversibleComponentOperation(
                                            ViewableProvider.maybeOf(context)!,
                                            () async {
                                      if (removeOld)
                                        widget.operationCubit
                                            .removeAllComponent(
                                                object as Component,
                                                widget.ancestor,
                                                clear: false);
                                      await widget.operationCubit.addOperation(
                                        context,
                                        widget.component,
                                        object as Component,
                                        widget.ancestor,
                                        customNamed: child,
                                        undo: true,
                                      );
                                      widget.creationCubit.changedComponent(
                                          ancestor: widget.ancestor);
                                      widget.operationCubit
                                          .updateState(widget.ancestor);
                                      widget.selectionCubit
                                          .changeComponentSelection(
                                              ComponentSelectionModel.unique(
                                                  object, widget.ancestor,
                                                  screen: _viewable));
                                    }, widget.ancestor);
                                  },
                                  onWillAccept: (data, _) {
                                    return data is String ||
                                        data is FavouriteModel ||
                                        data is SameComponent ||
                                        (data is Component &&
                                            data != widget.component &&
                                            (widget.component
                                                        as CustomNamedHolder)
                                                    .childMap[child] !=
                                                data);
                                  },
                                  builder: (context, candidates, rejected, _) {
                                    if (candidates.isNotEmpty) {
                                      return OnDragWidget(
                                        component: widget.component,
                                        title:
                                            '${widget.component.name} -> ${child}',
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Text(
                                            child,
                                            style: AppFontStyle.lato(12,
                                                color: theme.text3Color,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        if (showMenu) ...[
                                          const SizedBox(
                                            width: 4,
                                          ),
                                          OperationMenu(
                                              component: widget.component,
                                              customNamed: child,
                                              ancestor: widget.ancestor,
                                              componentSelectionCubit:
                                                  widget.selectionCubit,
                                              operationCubit:
                                                  widget.operationCubit,
                                              creationCubit:
                                                  widget.creationCubit),
                                        ]
                                      ],
                                    );
                                  },
                                ),
                                if (widget.component is BuilderComponent) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (widget.component as BuilderComponent)
                                                  .functionMap[child]
                                                  ?.suggestionPreviewCode ??
                                              '',
                                          style: AppFontStyle.lato(10,
                                              color: ColorAssets.theme,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      if ((widget.component as BuilderComponent)
                                          .functionMap
                                          .containsKey(child))
                                        CustomActionCodeButton(
                                            size: 14,
                                            margin: 5,
                                            code: () =>
                                                (widget.component
                                                        as BuilderComponent)
                                                    .functionMap[child]
                                                    ?.code ??
                                                '',
                                            config: FVBEditorConfig(
                                                variables: () => (widget
                                                            .component
                                                        as BuilderComponent)
                                                    .functionMap[child]!
                                                    .arguments
                                                    .map(
                                                      (e) => e.toVar
                                                        ..setValue(
                                                          collection.project!
                                                              .processor,
                                                          FVBTest(e.dataType,
                                                              e.nullable),
                                                        ),
                                                    )
                                                    .toList(growable: false),
                                                upCode: (widget.component
                                                        as BuilderComponent)
                                                    .functionMap[child]!
                                                    .cleanUpCode,
                                                parentProcessorGiven: true,
                                                downCode: '}  '),
                                            processor: ProcessorProvider
                                                    .maybeOf(context) ??
                                                collection.project!.processor,
                                            title: child,
                                            onChanged: (code, refresh) {
                                              (widget.component
                                                      as BuilderComponent)
                                                  .functionMap[child]
                                                  ?.code = code;
                                              _saveCode.run(() {
                                                widget.operationCubit
                                                    .updateRootComponent(
                                                        _viewable);
                                              });
                                            },
                                            onDismiss: () {
                                              if (widget.ancestor
                                                  is CustomComponent) {
                                                widget.operationCubit
                                                    .refreshCustomComponents(
                                                        widget.ancestor
                                                            as CustomComponent);
                                              }
                                              widget.creationCubit
                                                  .changedComponent(
                                                      ancestor:
                                                          widget.ancestor);
                                            })
                                    ],
                                  ),
                                ]
                              ],
                            )),
                    if ((widget.component as CustomNamedHolder)
                            .childMap[child] !=
                        null)
                      ProcessorProvider(
                        processor: (widget.component is BuilderComponent)
                            ? (widget.component as BuilderComponent)
                                    .functionMap[child]
                                    ?.processor ??
                                ProcessorProvider.maybeOf(context)!
                            : ProcessorProvider.maybeOf(context)!,
                        child: ComponentTreeSublistWidget(
                          ancestor: widget.ancestor,
                          component: (widget.component as CustomNamedHolder)
                              .childMap[child]!,
                          parent: widget.component,
                          componentParameter: widget.componentParameter,
                          selectionCubit: widget.selectionCubit,
                          operationCubit: widget.operationCubit,
                          creationCubit: widget.creationCubit,
                          named: widget.named,
                        ),
                      ),
                    const SizedBox(
                      height: 4,
                    )
                  ],
                ),
              ],
              for (final child in (widget.component as CustomNamedHolder)
                  .childrenMap
                  .keys) ...[
                Column(
                  children: [
                    OnHoverMenuChangeWidget(
                        buildWidget: (showMenu) => CustomDragTarget(
                              onAccept: (object, _) {
                                bool removeOld = true;
                                if (!shouldRemoveFromOldAncestor(object!)) {
                                  object =
                                      getComponentFromDragData(context, object);
                                  removeOld = false;
                                }
                                assert(object is Component);
                                widget.operationCubit
                                    .reversibleComponentOperation(
                                        ViewableProvider.maybeOf(context)!,
                                        () async {
                                  if (removeOld)
                                    widget.operationCubit.removeAllComponent(
                                        object as Component, widget.ancestor,
                                        clear: false);
                                  await widget.operationCubit.addOperation(
                                    context,
                                    widget.component,
                                    object as Component,
                                    widget.ancestor,
                                    customNamed: child,
                                    undo: true,
                                  );
                                  widget.creationCubit.changedComponent(
                                      ancestor: widget.ancestor);
                                  widget.operationCubit
                                      .updateState(widget.ancestor);
                                  widget.selectionCubit
                                      .changeComponentSelection(
                                          ComponentSelectionModel.unique(
                                    object,
                                    widget.ancestor,
                                    screen: _viewable,
                                  ));
                                }, widget.ancestor);
                              },
                              onWillAccept: (data, _) {
                                return data is String ||
                                    data is FavouriteModel ||
                                    data is SameComponent ||
                                    (data is Component &&
                                        data != widget.component &&
                                        !(widget.component as CustomNamedHolder)
                                            .childrenMap[child]!
                                            .contains(data));
                              },
                              builder: (context, candidates, rejected, _) {
                                if (candidates.isNotEmpty) {
                                  return OnDragWidget(
                                    component: widget.component,
                                    title:
                                        '${widget.component.name} -> ${child}',
                                  );
                                }
                                return Row(
                                  children: [
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Text(
                                          '$child (List)',
                                          style: AppFontStyle.lato(12,
                                              color: theme.text3Color,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                    if (showMenu) ...[
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      OperationMenu(
                                          component: widget.component,
                                          customNamed: child,
                                          ancestor: widget.ancestor,
                                          componentSelectionCubit:
                                              widget.selectionCubit,
                                          operationCubit: widget.operationCubit,
                                          creationCubit: widget.creationCubit),
                                    ]
                                  ],
                                );
                              },
                            )),
                    if ((widget.component as CustomNamedHolder)
                            .childrenMap[child] !=
                        null)
                      MultipleChildWidget(
                        ancestor: widget.ancestor,
                        component: widget.component,
                        children: (widget.component as CustomNamedHolder)
                            .childrenMap[child]!,
                        named: child,
                        componentSelectionCubit: widget.selectionCubit,
                        componentOperationCubit: widget.operationCubit,
                        componentCreationCubit: widget.creationCubit,
                      ),
                    const SizedBox(
                      height: 4,
                    )
                  ],
                ),
              ]
            ]),
          ),
        ],
      );
    } else if (widget.component is CustomComponent) {
      return OnHoverMenuChangeWidget(
          buildWidget: (showMenu) => Row(
                children: [
                  ComponentTile(
                    component: widget.component,
                    ancestor: widget.ancestor,
                    componentSelectionCubit: widget.selectionCubit,
                    parameter: widget.componentParameter,
                    named: widget.named,
                  ),
                  if (showMenu) ...[
                    const SizedBox(
                      width: 4,
                    ),
                    OperationMenu(
                      component: widget.component,
                      ancestor: widget.ancestor,
                      componentParameter: widget.componentParameter,
                      operationCubit: widget.operationCubit,
                      creationCubit: widget.creationCubit,
                      componentSelectionCubit: widget.selectionCubit,
                    )
                  ]
                ],
              ));
    }
    return Column(
      children: [
        OnHoverMenuChangeWidget(
          buildWidget: (showMenu) => Row(
            children: [
              ComponentTile(
                component: widget.component,
                ancestor: widget.ancestor,
                componentSelectionCubit: widget.selectionCubit,
                parameter: widget.componentParameter,
                named: widget.named,
              ),
              if (showMenu) ...[
                const SizedBox(
                  width: 4,
                ),
                OperationMenu(
                  component: widget.component,
                  ancestor: widget.ancestor,
                  componentParameter: widget.componentParameter,
                  operationCubit: widget.operationCubit,
                  creationCubit: widget.creationCubit,
                  componentSelectionCubit: widget.selectionCubit,
                )
              ]
            ],
          ),
        ),
        if (widget.component.componentParameters.isNotEmpty)
          ComponentParameterWidget(
              component: widget.component,
              ancestor: widget.ancestor,
              componentSelectionCubit: widget.selectionCubit,
              componentOperationCubit: widget.operationCubit,
              componentCreationCubit: widget.creationCubit)
      ],
    );
  }
}

class OnDragWidget extends StatelessWidget {
  final String? title;
  final Component? component;

  const OnDragWidget({super.key, this.component, this.title});

  @override
  Widget build(BuildContext context) {
    final replace = component is Holder && (component as Holder).child != null;
    return DottedBorder(
      color: ColorAssets.theme,
      radius: const Radius.circular(4),
      borderType: BorderType.RRect,
      strokeWidth: 1.5,
      dashPattern: [4, 4],
      child: Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 180),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title ?? component?.name ?? '',
              style: AppFontStyle.lato(
                13,
                fontWeight: FontWeight.w600,
                color: ColorAssets.theme,
              ),
            ),
            10.hBox,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (replace)
                  const Icon(
                    Icons.find_replace,
                    color: ColorAssets.red,
                    size: 16,
                  )
                else
                  const Icon(
                    Icons.add,
                    color: ColorAssets.theme,
                    size: 16,
                  ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    replace ? 'Replace Child' : 'Add Child',
                    style: AppFontStyle.lato(12,
                        color: replace ? ColorAssets.red : ColorAssets.theme,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OnHoverMenuChangeWidget extends StatefulWidget {
  final Widget Function(bool) buildWidget;

  const OnHoverMenuChangeWidget({Key? key, required this.buildWidget})
      : super(key: key);

  @override
  _OnHoverMenuChangeWidgetState createState() =>
      _OnHoverMenuChangeWidgetState();
}

class _OnHoverMenuChangeWidgetState extends State<OnHoverMenuChangeWidget> {
  static _OnHoverMenuChangeWidgetState? _currentState;

  void rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return widget.buildWidget(true);
    }
    return MouseRegion(
      onEnter: (_) {
        if (_currentState != null) {
          final oldState = _currentState;
          _currentState = this;
          if (oldState!.mounted) {
            oldState.rebuild();
          }
        } else {
          _currentState = this;
        }

        _currentState!.rebuild();
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _currentState == this
                ? theme.background3.withOpacity(0.5)
                : null),
        child: widget.buildWidget.call(_currentState == this),
      ),
    );
  }
}

class OperationMenu extends StatelessWidget {
  final Component component;
  final Component ancestor;
  final ComponentParameter? componentParameter;
  final String? customNamed;
  final OperationCubit operationCubit;
  final CreationCubit creationCubit;
  final SelectionCubit componentSelectionCubit;
  final bool menuEnable;
  final bool disableOperations;
  final bool componentParameterOperation;
  static final components =
      componentList.map((key, value) => MapEntry(key, value()));

  const OperationMenu(
      {Key? key,
      this.customNamed,
      this.componentParameter,
      this.menuEnable = true,
      this.disableOperations = false,
      this.componentParameterOperation = false,
      required this.component,
      required this.ancestor,
      required this.operationCubit,
      required this.creationCubit,
      required this.componentSelectionCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favourite = customNamed == null &&
        !componentParameterOperation &&
        operationCubit.isFavourite(component);
    final screen = ViewableProvider.maybeOf(context);

    return Container(
      color: theme.background3,
      child: Row(
        children: [
          if ((componentParameterOperation && !componentParameter!.isFull()) ||
              (!componentParameterOperation &&
                  operationCubit.shouldAddingEnable(
                      component, ancestor, customNamed))) ...[
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                //ADDING COMPONENT
                if (component is CTabBar && customNamed == 'tabs') {
                  operationCubit.performAddOperation(
                    context,
                    component,
                    CTab()..onFreshAdded(),
                    ancestor,
                    componentParameterOperation: componentParameterOperation,
                    componentParameter: componentParameter,
                    customNamed: customNamed,
                    undo: true,
                  );
                } else {
                  showSelectionDialog(context, (comp) {
                    operationCubit.performAddOperation(
                      context,
                      component,
                      comp,
                      ancestor,
                      componentParameterOperation: componentParameterOperation,
                      componentParameter: componentParameter,
                      customNamed: customNamed,
                      undo: true,
                    );
                  }, possibleItems: null);
                }
              },
              child: const Icon(
                Icons.add,
                size: 15,
                color: ColorAssets.theme,
              ),
            ),
            const SizedBox(
              width: 3,
            ),
          ],
          if (([1, 2, 3, 5].contains(component.type) ||
                  (customNamed == null && component is BuilderComponent)) &&
              component != ancestor &&
              !disableOperations) ...[
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                //Replacing component
                showSelectionDialog(context, (comp) {
                  operationCubit.revertWork
                      .add(ReplaceOperation(component, comp, screen), () {
                    operationCubit.replaceWith(component, comp, ancestor);
                    creationCubit.changedComponent();

                    operationCubit.updateState(ancestor);

                    componentSelectionCubit.changeComponentSelection(
                        ComponentSelectionModel.unique(comp, ancestor,
                            screen: screen));
                  }, (oldValue) {
                    final ReplaceOperation operation = oldValue;
                    operationCubit.replaceWith(
                        operation.component2, operation.component1, ancestor);
                    creationCubit.changedComponent();

                    operationCubit.updateState(ancestor);

                    componentSelectionCubit.changeComponentSelection(
                        ComponentSelectionModel.unique(
                            operation.component1, ancestor,
                            screen: operation.screen));
                  });
                },
                    favouritesEnable: false,
                    possibleItems: getSameComponents(components, component));
              },
              child: const Icon(
                Icons.find_replace_outlined,
                size: 15,
                color: ColorAssets.theme,
              ),
            ),
            const SizedBox(
              width: 3,
            ),
          ],
          if (!disableOperations && menuEnable && customNamed == null) ...[
            CustomPopupMenuButton(
              itemHeight: 35,
              itemBuilder: (_) {
                late final int compChildren;
                switch (component.type) {
                  case 2:
                    compChildren = (component as MultiHolder).children.length;
                    break;
                  case 3:
                    compChildren =
                        ((component as Holder).child == null ? 0 : 1);
                    break;
                  default:
                    compChildren = 0;
                }

                final list = [
                  'Duplicate',
                  kCopyCode,
                  if (kDebugMode) 'Copy Json',
                  if (!favourite)
                    'Add to favourites'
                  else
                    'Remove from favourites',
                  if (customNamed == null &&
                      (component.type == 1 ||
                          ((component.type == 2) &&
                              (((component.parent?.type == 4 ||
                                          component.parent?.type == 7) &&
                                      compChildren <= 1) ||
                                  component.parent?.type == 2 ||
                                  ((component.parent == null ||
                                          component.parent?.type == 3 ||
                                          component.parent?.type == 5) &&
                                      compChildren < 2))) ||
                          (component.type == 3 &&
                              (([2, 3, 4, 5].contains(component.parent?.type) ||
                                  component.parent == null))) ||
                          (component.type == 4) ||
                          (component.type == 5)))
                    'Remove',
                  if (customNamed == null && component.type != 1) 'Remove tree',
                  'Create global widget',
                  if (component.type != 5) 'Create custom widget',
                  if (component.type == 3 &&
                      (component as Holder).child?.type == 3)
                    'Swap with child',
                  ...getTypeComponents(
                          components, customNamed == null ? [2, 3, 4] : [])
                      .map((e) => 'Wrap with $e')
                ];

                return list
                    .map(
                      (item) => CustomPopupMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: AppFontStyle.lato(12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                    .toList();
              },
              onSelected: (e) {
                if (e == 'Copy Json') {
                  Clipboard.setData(
                      ClipboardData(text: jsonEncode(component.toJson())));
                } else if (e == 'Duplicate') {
                  operationCubit.duplicateComponentOperation(
                      context, component, ancestor, customNamed);
                } else if (e == kCopyCode) {
                  Clipboard.setData(ClipboardData(
                      text: DartFormatter()
                          .formatStatement(component.code() + ';')));
                } else if (e == 'Add to favourites') {
                  final report = operationCubit.checkIfCanBeFavourite(
                      component, ancestor, screen);
                  if (report == null) {
                    operationCubit.addToFavourites(component);
                  } else {
                    if (report.error != null) {
                      showToast(report.error!);
                    } else
                      showToast(
                          'Favourite widget should not be dependent on any variables, ${report.errorCount} error Found in ${report.componentError.keys.map((e) => e.name).join(',')}');
                  }
                } else if (e == 'Remove from favourites') {
                  operationCubit.removeFromFavourites(component);
                } else if (e == 'Create global widget') {
                  showGlobalComponentDialog(
                    context,
                    model: GlobalComponentModel(
                      name: '',
                      code: component.toJson(),
                      customs: [],
                      publisherId: sl<UserSession>().user.userId!,
                      publisherName: sl<UserSession>().user.email,
                      width: component.boundary?.width,
                      height: component.boundary?.height,
                    ),
                  );
                } else if (e == 'Create custom widget') {
                  showCustomWidgetAdd(context, (type, value,
                      [Map<String, dynamic>? code]) {
                    operationCubit.revertWork.add(component.parent, () {
                      operationCubit.addCustomComponent(value, type,
                          root: component);
                    }, (p0) async {
                      await operationCubit.addOperation(
                        context,
                        p0,
                        component,
                        ancestor,
                        undo: true,
                      );
                      final comp = operationCubit.project!.customComponents
                          .firstWhereOrNull((element) => element.name == value);
                      if (comp != null) {
                        operationCubit.deleteCustomComponent(context, comp);
                      }
                      creationCubit.changedComponent();
                    });

                    Navigator.pop(context);
                  });
                } else if (e == 'Remove') {
                  operationCubit.removeComponentOperation(
                      context, component, ancestor, screen);
                } else if (e == 'Remove tree') {
                  removeAll(
                      context,
                      operationCubit,
                      creationCubit,
                      componentSelectionCubit,
                      component,
                      ancestor,
                      componentParameter);
                } else if (e == 'Swap with child') {
                  operationCubit.reversibleComponentOperation(
                      ViewableProvider.maybeOf(context)!, () {
                    final child = (component as Holder).child;
                    final parent = component.parent;

                    final grandChild =
                        (((component as Holder).child) as Holder).child;
                    (child as Holder).child = component;
                    (component as Holder).child = grandChild;
                    child.parent = component.parent;
                    grandChild?.parent = component;
                    if (parent != null) replaceChildOfParent(component, child);
                    component.parent = child;
                    operationCubit.updateState(ancestor);
                    creationCubit.changedComponent();
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      componentSelectionCubit.changeComponentSelection(
                          ComponentSelectionModel.unique(child, ancestor,
                              screen: screen!));
                    });
                  }, ancestor);
                } else if ((e as String).startsWith('Wrap')) {
                  final split = e.split(' ');
                  final compName = split[2];
                  final Component wrapperComp = componentList[compName]!();
                  wrapperComp.onFreshAdded();
                  operationCubit.wrapWithComponent(
                      component, wrapperComp, ancestor, screen,
                      customName: split.length == 4 ? split[3] : null,
                      undo: true);
                  operationCubit.updateState(ancestor);
                  if (wrapperComp.parent is Component) {
                    context.read<StateManagementBloc>().add(
                        StateManagementRefreshEvent(
                            (wrapperComp.parent as Component).id,
                            RuntimeMode.edit));
                  } else {
                    creationCubit.changedComponent();
                  }
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    componentSelectionCubit.changeComponentSelection(
                        ComponentSelectionModel.unique(wrapperComp, ancestor,
                            screen: screen));
                  });
                }
              },
              child: const Icon(
                Icons.more_vert,
                color: ColorAssets.theme,
                size: 15,
              ),
            ),
          ]
        ],
      ),
    );
  }

  // void performReversibleOperation(void Function() work) {
  //   componentOperationCubit.revertWork.add(
  //       Operation2(
  //           componentOperationCubit.flutterProject!.rootComponent!
  //               .clone(null, cloneParam: true),
  //           componentOperationCubit.flutterProject!.rootComponent!.uniqueId),
  //       work, (p0) {
  //     componentOperationCubit.flutterProject!.rootComponent = (p0 as Operation2).component;
  //     componentOperationCubit.emit(ComponentUpdatedState());
  //     componentOperationCubit.flutterProject!.rootComponent!.forEach((comp) {
  //       if (comp.name == 'Image.asset') {
  //         final imageData = (comp.parameters[0].value as ImageData);
  //         if (componentOperationCubit.byteCache
  //             .containsKey(imageData.imageName)) {
  //           imageData.bytes =
  //               componentOperationCubit.byteCache[imageData.imageName];
  //         }
  //       }
  //       if (comp.id == (p0).selectedId) {
  //         componentSelectionCubit.changeComponentSelection(
  //             ComponentSelectionModel.unique(comp),
  //             root: ancestor);
  //       }
  //     });
  //     componentCreationCubit.changedComponent();
  //   });
  // }

  List<String> getSameComponents(
      Map<String, Component> components, Component component) {
    final List<String> sameComponents = [];
    for (final key in components.keys) {
      if ((component is! BuilderComponent ||
              components[key] is BuilderComponent) &&
          components[key]!.childCount == component.childCount) {
        sameComponents.add(key);
      }
    }
    return sameComponents;
  }

  List<String> getTypeComponents(
      Map<String, Component> components, List<int> types) {
    final List<String> sameComponents = [];
    for (final entry in components.entries) {
      if (types.contains(entry.value.type)) {
        if (entry.value.type == 4) {
          sameComponents.addAll((entry.value as CustomNamedHolder)
              .childMap
              .keys
              .map((e) => entry.key + ' ' + e)
              .toList());
        } else {
          sameComponents.add(entry.key);
        }
      }
    }
    sameComponents.sort((a, b) =>
        (operationCubit.sameComponentCollection[a]?.length ?? 0) <
                (operationCubit.sameComponentCollection[b]?.length ?? 0)
            ? 1
            : -1);
    return sameComponents;
  }

  void replaceChildOfParent(Component component, Component comp) {
    switch (component.parent?.type) {
      case 2:
        //MultiHolder
        (component.parent as MultiHolder).replaceChild(component, comp);
        break;
      case 3:
        //Holder
        (component.parent as Holder).updateChild(comp);
        break;
      case 4:
        //CustomNamedHolder
        (component.parent as CustomNamedHolder).replaceChild(component, comp);
        break;
      case 5:
        (component.parent as CustomComponent).updateRoot(comp);
        break;
    }
  }

  void replaceChildOfComponent(
      Component component, Component old, Component comp) {
    switch (component.type) {
      case 2:
        //MultiHolder
        (component as MultiHolder).replaceChild(old, comp);
        break;
      case 3:
        //Holder
        (component as Holder).updateChild(comp);
        break;
      case 4:
        //CustomNamedHolder
        (component as CustomNamedHolder).replaceChild(old, comp);
        break;
      case 5:
        (component as CustomComponent).updateRoot(comp);
        break;
    }
  }
}
