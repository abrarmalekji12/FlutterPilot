import 'dart:convert';
import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bloc/component_drag/component_drag_bloc.dart';
import '../../bloc/paint_obj/paint_obj_bloc.dart';
import '../../bloc/state_management/state_management_bloc.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../collections/project_info_collection.dart';
import '../../common/app_button.dart';
import '../../common/common_methods.dart';
import '../../common/converter/string_operation.dart';
import '../../common/custom_extension_tile.dart';
import '../../common/custom_popup_menu_button.dart';
import '../../common/drag_target.dart';
import '../../common/extension_util.dart';
import '../../common/validations.dart';
import '../../components/component_impl.dart';
import '../../components/component_list.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../constant/image_asset.dart';
import '../../cubit/component_creation/component_creation_cubit.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../cubit/parameter_build_cubit/parameter_build_cubit.dart';
import '../../cubit/user_details/user_details_cubit.dart';
import '../../cubit/visual_box_drawer/visual_box_cubit.dart';
import '../../injector.dart';
import '../../models/component_selection.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/other_model.dart';
import '../../models/parameter_model.dart';
import '../../models/project_model.dart';
import '../../models/variable_model.dart';
import '../../riverpod/clipboard.dart';
import '../../runtime_provider.dart';
import '../../user_session.dart';
import '../../widgets/overlay/overlay_manager.dart';
import '../common/action_code_dialog.dart';
import '../common/badge_widget.dart';
import '../common/custom_widget_dialog.dart';
import '../common/variable_dialog.dart';
import '../component_selection_dialog.dart';
import '../custom_component_selection.dart';
import '../fvb_code_editor.dart';
import '../home/cubit/home_cubit.dart';
import '../home/home_page.dart';
import '../models_view.dart';
import '../navigation/animated_dialog.dart';
import '../navigation/animated_slider.dart';
import '../parameter_ui.dart';
import '../project/project_selection_page.dart';
import '../create_screen_dialog.dart';
import '../settings/models/collaborator.dart';
import 'component_sublist.dart';

const kCopyCode = 'Copy Code';

class VerticalScrollProvider extends InheritedWidget {
  final ScrollController controller;

  VerticalScrollProvider(
      {required this.controller, super.key, required super.child});

  @override
  bool updateShouldNotify(VerticalScrollProvider oldWidget) =>
      controller != oldWidget.controller;

  static ScrollController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<VerticalScrollProvider>()
      ?.controller;
}

class ComponentTree extends StatefulWidget {
  const ComponentTree({Key? key}) : super(key: key);

  @override
  _ComponentTreeState createState() => _ComponentTreeState();
}

final storageBucket = PageStorageBucket();
late ScrollController componentTreeScrollController;

class _ComponentTreeState extends State<ComponentTree> with OverlayManager {
  late final OperationCubit _operationCubit;
  late final CreationCubit _creationCubit;
  late final SelectionCubit _selectionCubit;
  late final ThemeBloc _themeBloc;
  final _focusNode = FocusNode();
  final _preference = sl<SharedPreferences>();

  @override
  void initState() {
    super.initState();
    componentTreeScrollController = ScrollController();
    _operationCubit = context.read<OperationCubit>();
    _creationCubit = context.read<CreationCubit>();
    _selectionCubit = context.read<SelectionCubit>();
    _themeBloc = context.read<ThemeBloc>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    destroyOverlays();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _themeBloc.background1,
      child: Column(
        children: [
          Visibility(
            visible: _operationCubit.project!.screens.isNotEmpty,
            child: BlocBuilder<OperationCubit, OperationState>(
              builder: (context, state) {
                return const Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: Text(
                      //     'Current Screen',
                      //     style: AppFontStyle.roboto(13,
                      //         color: _themeBloc.text1Color,
                      //         fontWeight: FontWeight.w500),
                      //   ),
                      // ),
                      // Row(
                      //   crossAxisAlignment: CrossAxisAlignment.center,
                      //   children: [
                      //     Expanded(
                      //       child: CustomDropdownButton<UIScreen>(
                      //           style: AppFontStyle.roboto(13),
                      //           value: _componentOperationCubit
                      //               .project!.currentScreen,
                      //           hint: null,
                      //           items: _componentOperationCubit
                      //               .project!.uiScreens
                      //               .map<CustomDropdownMenuItem<UIScreen>>(
                      //                 (e) =>
                      //                 CustomDropdownMenuItem<UIScreen>(
                      //                   value: e,
                      //                   child: Text(
                      //                     e.name,
                      //                     style: AppFontStyle.roboto(
                      //                       13,
                      //                       fontWeight: FontWeight.w500,
                      //                       color: _themeBloc.text1Color,
                      //                     ),
                      //                   ),
                      //                 ),
                      //           )
                      //               .toList(),
                      //           onChanged: (value) {
                      //             if (value !=
                      //                 _componentOperationCubit
                      //                     .project!.currentScreen) {
                      //               _componentOperationCubit
                      //                   .changeProjectScreen(value);
                      //               _componentSelectionCubit
                      //                   .changeComponentSelection(
                      //                   ComponentSelectionModel.unique(
                      //                       value.rootComponent!,
                      //                       value.rootComponent!,screen: _componentOperationCubit.project!.currentScreen));
                      //               _componentCreationCubit.changedComponent();
                      //             }
                      //           },
                      //           selectedItemBuilder: (context, config) {
                      //             return Text(
                      //               config.name,
                      //               style: AppFontStyle.roboto(
                      //                 13,
                      //                 fontWeight: FontWeight.w500,
                      //                 color: _themeBloc.text1Color,
                      //               ),
                      //             );
                      //           }),
                      //     ),
                      //
                      //   ],
                      // ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ListenableBuilder(
                        listenable: componentTreeScrollController,
                        builder: (context, _) {
                          return FractionallySizedBox(
                            heightFactor: max(
                                componentTreeScrollController.hasClients &&
                                        componentTreeScrollController
                                                .position.maxScrollExtent >
                                            0
                                    ? (componentTreeScrollController.offset /
                                        componentTreeScrollController
                                            .position.maxScrollExtent)
                                    : 0,
                                0),
                            child: Container(
                              width: 2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.blueAccent,
                              ),
                            ),
                          );
                        }),
                  ),
                ),
                Expanded(
                  child: BlocConsumer<SelectionCubit, SelectionState>(
                    listener: (context, state) {
                      if (state is SelectionChangeState && state.scroll) {
                        scrollToSelected();
                      }
                    },
                    buildWhen: (state1, state2) =>
                        state2 is SelectionChangeState &&
                        (state1 is! SelectionChangeState ||
                            state2.model.viewable != state1.model.viewable),
                    builder: (context, state) {
                      return BlocBuilder<OperationCubit, OperationState>(
                        bloc: _operationCubit,
                        buildWhen: (_, state) {
                          if (state is ComponentUpdatedState ||
                              state is ComponentOperationScreensUpdatedState) {
                            return true;
                          }
                          return false;
                        },
                        builder: (context, state) {
                          return ListView(
                            controller: componentTreeScrollController,
                            padding: const EdgeInsets.only(
                                right: 8, top: 12, bottom: 20),
                            restorationId: 'component_scroll_view',
                            children: [
                              const ProjectMainMenu(),
                              ViewableProvider(
                                screen: _collection.project!,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: _collection.project?.rootComponent ==
                                          null
                                      ? CustomDragTarget(
                                          onWillAccept: (data, _) {
                                            return data is String ||
                                                data is SameComponent ||
                                                data is FavouriteModel ||
                                                (data is Component);
                                          },
                                          onAccept: (data, _) {
                                            if (!shouldRemoveFromOldAncestor(
                                                data!)) {
                                              data = getComponentFromDragData(
                                                  context, data);
                                            }
                                            assert(data is Component);
                                            _collection.project?.rootComponent =
                                                data as Component;
                                            _selectionCubit
                                                .changeComponentSelection(
                                              ComponentSelectionModel.unique(
                                                  data as Component, data,
                                                  screen: _collection.project),
                                            );
                                            _creationCubit.changedComponent();
                                          },
                                          builder:
                                              (context, list, list2, offset) {
                                            if (list.isNotEmpty) {
                                              return const OnDragWidget(
                                                title: 'Add Root',
                                              );
                                            }
                                            return Row(
                                              children: [
                                                Text(
                                                  'Add Root Widget',
                                                  style: AppFontStyle.lato(13,
                                                      color: theme.text1Color,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                const SizedBox(
                                                  width: 20,
                                                ),
                                                AppIconButton(
                                                    icon: Icons.add,
                                                    size: 18,
                                                    margin: 2,
                                                    background:
                                                        ColorAssets.theme,
                                                    onPressed: () {
                                                      showSelectionDialog(
                                                          context, (comp) {
                                                        _collection.project
                                                                ?.rootComponent =
                                                            comp;
                                                        _creationCubit
                                                            .changedComponent();
                                                        WidgetsBinding.instance
                                                            .addPostFrameCallback(
                                                                (timeStamp) {
                                                          _selectionCubit.changeComponentSelection(
                                                              ComponentSelectionModel.unique(
                                                                  comp, comp,
                                                                  screen: _collection
                                                                      .project));
                                                        });
                                                      }, possibleItems: null);
                                                    }),
                                              ],
                                            );
                                          },
                                        )
                                      : ProcessorProvider(
                                          processor:
                                              _collection.project!.processor,
                                          child: ComponentTreeSublistWidget(
                                            component: _collection
                                                .project!.rootComponent!,
                                            ancestor: _collection
                                                .project!.rootComponent!,
                                            parent: null,
                                            selectionCubit: _selectionCubit,
                                            operationCubit: _operationCubit,
                                            creationCubit: _creationCubit,
                                            named: null,
                                            componentParameter: null,
                                          ),
                                        ),
                                ),
                              ),
                              const Divider(
                                thickness: 0.3,
                              ),
                              for (final screen in [
                                ..._collection.project!.screens,
                                // ...(FigmaToFVBConverter().convert(
                                //       _userDetailsCubit.figmaResponse?.document,
                                //       _userDetailsCubit.figmaDocumentMeta,
                                //     ) ??
                                //     [])
                              ]) ...[
                                CustomExpansionTile(
                                  title: ScreenMainMenu(
                                    screen: screen,
                                  ),
                                  maintainState: true,
                                  onExpansionChanged: (value) =>
                                      expansionChanged(screen.id, value),
                                  initiallyExpanded: _preference
                                          .getBool('expand_${screen.id}') ??
                                      true,
                                  children: [
                                    ViewableProvider(
                                      screen: screen,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        child: screen.rootComponent == null
                                            ? CustomDragTarget(
                                                onWillAccept: (data, _) {
                                                  return data is String ||
                                                      data is SameComponent ||
                                                      data is FavouriteModel ||
                                                      (data is Component);
                                                },
                                                onAccept: (data, _) {
                                                  if (!shouldRemoveFromOldAncestor(
                                                      data!)) {
                                                    data =
                                                        getComponentFromDragData(
                                                            context, data);
                                                  }
                                                  assert(data is Component);
                                                  screen.rootComponent =
                                                      data as Component;
                                                  _selectionCubit
                                                      .changeComponentSelection(
                                                    ComponentSelectionModel
                                                        .unique(data, data,
                                                            screen: screen),
                                                  );
                                                  _creationCubit
                                                      .changedComponent();
                                                },
                                                builder: (context, list, list2,
                                                    offset) {
                                                  if (list.isNotEmpty) {
                                                    return const OnDragWidget(
                                                      title: 'Add Root',
                                                    );
                                                  }
                                                  return Row(
                                                    children: [
                                                      Text(
                                                        'Add Root Widget',
                                                        style:
                                                            AppFontStyle.lato(
                                                                13,
                                                                color: theme
                                                                    .text1Color,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                      const SizedBox(
                                                        width: 20,
                                                      ),
                                                      AppIconButton(
                                                          icon: Icons.add,
                                                          size: 18,
                                                          margin: 2,
                                                          background:
                                                              ColorAssets.theme,
                                                          onPressed: () {
                                                            showSelectionDialog(
                                                                context,
                                                                (comp) {
                                                              screen.rootComponent =
                                                                  comp;
                                                              _creationCubit
                                                                  .changedComponent();
                                                              WidgetsBinding
                                                                  .instance
                                                                  .addPostFrameCallback(
                                                                      (timeStamp) {
                                                                _selectionCubit.changeComponentSelection(
                                                                    ComponentSelectionModel.unique(
                                                                        comp,
                                                                        comp,
                                                                        screen:
                                                                            screen));
                                                              });
                                                            },
                                                                possibleItems:
                                                                    null);
                                                          }),
                                                    ],
                                                  );
                                                },
                                              )
                                            : ProcessorProvider(
                                                processor: screen.processor,
                                                child:
                                                    ComponentTreeSublistWidget(
                                                  component:
                                                      screen.rootComponent!,
                                                  ancestor:
                                                      screen.rootComponent!,
                                                  parent: null,
                                                  selectionCubit:
                                                      _selectionCubit,
                                                  operationCubit:
                                                      _operationCubit,
                                                  creationCubit: _creationCubit,
                                                  named: null,
                                                  componentParameter: null,
                                                ),
                                              ),
                                      ),
                                    )
                                  ],
                                ),
                                5.hBox
                              ],
                              const Divider(
                                height: 20,
                              ),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Custom Widgets',
                                          style: AppFontStyle.titleStyle(),
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          //ADD Custom Widgets
                                          showCustomWidgetAdd(context, (type,
                                              value,
                                              [Map<String, dynamic>? code]) {
                                            _operationCubit.addCustomComponent(
                                                value, type,
                                                root: code != null
                                                    ? Component.fromJson(code,
                                                        _collection.project!)
                                                    : null);
                                            Navigator.pop(context);
                                          });
                                        },
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: ColorAssets.theme,
                                          child: Icon(
                                            Icons.add,
                                            size: 15,
                                            color: theme.background1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  AppButton(
                                    onPressed: () {
                                      AnimatedDialog.show(
                                        context,
                                        const CustomComponentSelection(),
                                      );
                                    },
                                    width: double.infinity,
                                    height: 40,
                                    enabledColor: ColorAssets.theme,
                                    title: 'Import...',
                                  )
                                ],
                              ),
                              10.hBox,
                              for (final CustomComponent custom
                                  in _operationCubit
                                      .project!.customComponents) ...[
                                CustomExpansionTile(
                                  maintainState: true,
                                  title: CustomComponentMainMenu(
                                    component: custom,
                                    _selectionCubit,
                                    _operationCubit,
                                    _creationCubit,
                                  ),
                                  onExpansionChanged: (value) =>
                                      expansionChanged(custom.id, value),
                                  initiallyExpanded: _preference
                                          .getBool('expand_${custom.id}') ??
                                      true,
                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    ViewableProvider(
                                      screen: custom,
                                      child: CustomComponentWidget(
                                        component: custom,
                                        _selectionCubit,
                                        _operationCubit,
                                        _creationCubit,
                                      ),
                                    )
                                  ],
                                ),
                                const Divider(
                                  height: 8,
                                ),
                              ],
                              20.hBox,
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void scrollToSelected() {
    if (GlobalObjectKey(_selectionCubit.selected.treeSelection.first.uniqueId)
            .currentContext ==
        null) {
      dynamic comp = _selectionCubit.selected.treeSelection.first;
      while (comp.parent != null) {
        comp = comp.parent!;
        if (_operationCubit.expandedTree.containsKey(comp) &&
            !(_operationCubit.expandedTree[comp] ?? true)) {
          _operationCubit.expandedTree[comp] = true;
          setState(() {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              ensureVisible();
            });
          });
        }
      }
    } else {
      ensureVisible();
    }
  }

  void ensureVisible() {
    Scrollable.ensureVisible(
        GlobalObjectKey(_selectionCubit.selected.treeSelection.first.uniqueId)
            .currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200));
  }

  void expansionChanged(String id, bool value) {
    _preference.setBool('expand_$id', value);
  }
}

class CustomComponentMainMenu extends StatefulWidget {
  final CustomComponent component;
  final SelectionCubit _selectionCubit;
  final OperationCubit _operationCubit;
  final CreationCubit _creationCubit;

  const CustomComponentMainMenu(
    this._selectionCubit,
    this._operationCubit,
    this._creationCubit, {
    Key? key,
    required this.component,
  }) : super(key: key);

  @override
  State<CustomComponentMainMenu> createState() =>
      _CustomComponentMainMenuState();
}

class _CustomComponentMainMenuState extends State<CustomComponentMainMenu>
    with OverlayManager {
  final _varKey = GlobalKey();
  final ValueNotifier<bool> hoverNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    destroyOverlays();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisualBoxCubit, VisualBoxState>(
      listener: (_, state) {
        if (state is VisualBoxHoverUpdatedState) {
          hoverNotifier.value = state.screen?.id == widget.component.id;
        }
      },
      listenWhen: (_, state) => state is VisualBoxHoverUpdatedState,
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder(
                valueListenable: hoverNotifier,
                builder: (context, value, _) => value
                    ? Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: ColorAssets.theme, width: 0.7),
                            borderRadius: BorderRadius.circular(6)),
                      )
                    : const SizedBox.shrink()),
          ),
          InkWell(
            onDoubleTap: () {
              widget._selectionCubit.changeComponentSelection(
                  ComponentSelectionModel.unique(
                      widget.component, widget.component));
            },
            onTap: () => CustomExpansionTile.of(context).toggle(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<SelectionCubit, SelectionState>(
                            bloc: widget._selectionCubit,
                            buildWhen: (_, state) =>
                                state is SelectionChangeState &&
                                (state.model.treeSelection
                                        .contains(widget.component) ||
                                    state.oldModel.treeSelection
                                        .contains(widget.component)),
                            builder: (context, state) {
                              final selectedComponent =
                                  widget._selectionCubit.selected;
                              final selected = (selectedComponent.treeSelection
                                  .contains(widget.component));
                              return Text(
                                widget.component.name,
                                style: AppFontStyle.subtitleStyle().copyWith(
                                    color: selected ? ColorAssets.theme : null),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                        Tooltip(
                          message: switch (widget.component) {
                            (StatefulComponent _) => 'Stateful Component',
                            (StatelessComponent _) => 'Stateless Component',
                          },
                          child: CircleAvatar(
                            backgroundColor: switch (widget.component) {
                              (StatefulComponent _) => Colors.blue,
                              (StatelessComponent _) => Colors.green,
                            },
                            radius: 4,
                          ),
                        ),
                        5.wBox,
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomActionCodeButton(
                        size: 14,
                        margin: 5,
                        code: () => widget.component.actionCode,
                        title: widget.component.name,
                        onChanged: (code, refresh) {
                          widget.component.actionCode = code;
                          widget._operationCubit
                              .updateCustomComponentActionCode(
                                  widget.component, code);
                          for (final element in widget.component.objects) {
                            element.actionCode = widget.component.actionCode;
                          }
                        },
                        onDismiss: () {
                          widget.component.processor.destroyProcess(deep: true);
                          widget.component.objects.forEach((element) {
                            element.processor.destroyProcess(deep: true);
                          });
                          widget._creationCubit
                              .changedComponent(ancestor: widget.component);
                        },
                        config: FVBEditorConfig(
                            variableHandler: VariableHandler(
                          variables: () {
                            return widget.component.argumentVariables;
                          },
                          onVariableAdded: (VariableModel variable) {
                            if (widget.component.argumentVariables
                                    .firstWhereOrNull((element) =>
                                        element.name == variable.name) ==
                                null) {
                              widget.component
                                  .updateArgument(UpdateType.add, variable);
                              widget._operationCubit
                                  .updateCustomComponentArguments(
                                widget.component,
                              );
                            }
                          },
                          onDelete: (variable) {
                            widget.component
                                .updateArgument(UpdateType.remove, variable);
                            widget._operationCubit
                                .updateCustomComponentArguments(
                              widget.component,
                            );
                          },
                          wrapper: widget.component is StatefulComponent
                              ? (variables) {
                                  final argValue = widget
                                      .component.argumentVariables
                                      .map((e) => e.value)
                                      .toList(growable: false);
                                  return FVBVariable(
                                      'widget',
                                      DataType.fvbInstance(
                                          widget.component.name),
                                      value: widget.component.componentClass
                                          .createInstance(
                                              widget.component.processor,
                                              argValue));
                                }
                              : null,
                        )),
                        processor: _collection.project!.processor,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      AppIconButton(
                        size: 14,
                        margin: 5,
                        key: _varKey,
                        icon: Icons.data_array,
                        background: theme.background1,
                        iconColor: Colors.blue,
                        onPressed: () {
                          final VariableDialog dialog = VariableDialog(
                              componentOperationCubit: widget._operationCubit,
                              componentCreationCubit: widget._creationCubit,
                              componentSelectionCubit: widget._selectionCubit,
                              title: widget.component.name,
                              options: [
                                VariableDialogOption('Move to global', (model) {
                                  widget._operationCubit.addVariable(model);
                                  widget.component.variables.remove(model.name);
                                  widget._operationCubit
                                      .updateCustomVariable(widget.component);
                                })
                              ],
                              onAdded: (model) {
                                widget.component.variables[model.name] = model;
                                widget._operationCubit
                                    .updateCustomVariable(widget.component);
                              },
                              onEdited: (model) {
                                widget.component.variables[model.name] = model;
                                widget._operationCubit
                                    .updateCustomVariable(widget.component);
                              },
                              onDeleted: (model) {
                                widget.component.variables.remove(model.name);
                                widget._operationCubit
                                    .updateCustomVariable(widget.component);
                              },
                              variables: widget.component.variables);
                          dialog.show(
                            context,
                            this,
                            _varKey,
                          );
                        },
                      ),
                      CustomPopupMenuButton(
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: theme.text1Color,
                        ),
                        itemBuilder: (BuildContext context) => [
                          CustomPopupMenuItem(
                            value: 0,
                            child: Text(
                              widget.component.previewEnable
                                  ? 'Disable Preview'
                                  : 'Enable Preview',
                            ),
                          ),
                          const CustomPopupMenuItem(
                            value: 1,
                            child: Text('Delete'),
                          ),
                          const CustomPopupMenuItem(
                            value: 2,
                            child: Text('Rename'),
                          )
                        ],
                        onSelected: (i) {
                          switch (i) {
                            case 0:
                              context
                                  .read<HomeCubit>()
                                  .updateCustomWidgetPreview(widget.component);
                              break;
                            case 1:
                              showConfirmDialog(
                                context: context,
                                title: 'Alert!',
                                subtitle:
                                    'Do you really want to delete ${widget.component.name}?',
                                positive: 'Yes',
                                negative: 'No',
                                onPositiveTap: () {
                                  widget._operationCubit.deleteCustomComponent(
                                      context, widget.component);
                                  widget._creationCubit.changedComponent();
                                },
                              );
                              break;
                            case 2:
                              showEnterInfoDialog(
                                context,
                                'Rename "${widget.component.name}"',
                                validator: (value) {
                                  if (value == widget.component.name) {
                                    return 'Please enter different name';
                                  } else if (componentMap.containsKey(value)) {
                                    return 'Built-in component already exist with this name!';
                                  } else if (_collection
                                          .project!.customComponents
                                          .firstWhereOrNull((element) =>
                                              element.name == value) !=
                                      null) {
                                    return 'Component with name "$value" already exist!';
                                  }
                                  return Validations.commonNameValidator()(
                                      value);
                                },
                                initialValue: widget.component.name,
                                onPositive: (value) {
                                  widget.component.name = value;
                                  widget._operationCubit
                                      .updateGlobalCustomComponent(
                                          widget.component);
                                  widget._operationCubit.update();
                                },
                              );
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScreenMainMenu extends StatefulWidget {
  final Screen screen;

  const ScreenMainMenu({super.key, required this.screen});

  @override
  State<ScreenMainMenu> createState() => _ScreenMainMenuState();
}

class _ScreenMainMenuState extends State<ScreenMainMenu> with OverlayManager {
  late OperationCubit _operationCubit;
  late CreationCubit _creationCubit;
  late SelectionCubit _selectionCubit;
  late UserDetailsCubit _userDetailsCubit;
  final variableKey = GlobalKey();
  late ProjectPermission _permission;
  final ValueNotifier<bool> hoverNotifier = ValueNotifier(false);
  final UserSession _userSession = sl();

  @override
  void initState() {
    _permission = _collection.project!.userRole(_userSession);
    _operationCubit = context.read<OperationCubit>();
    _creationCubit = context.read<CreationCubit>();
    _selectionCubit = context.read<SelectionCubit>();
    _userDetailsCubit = context.read<UserDetailsCubit>();
    super.initState();
  }

  @override
  void dispose() {
    destroyOverlays();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisualBoxCubit, VisualBoxState>(
      listener: (_, state) {
        if (state is VisualBoxHoverUpdatedState) {
          hoverNotifier.value = state.screen?.id == widget.screen.id;
        }
      },
      listenWhen: (_, state) => state is VisualBoxHoverUpdatedState,
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder(
                valueListenable: hoverNotifier,
                builder: (context, value, _) => value
                    ? Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: ColorAssets.theme, width: 0.7),
                            borderRadius: BorderRadius.circular(6)),
                      )
                    : const SizedBox.shrink()),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.screen.name,
                    style: AppFontStyle.subtitleStyle(),
                  ),
                ),
                5.wBox,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomActionCodeButton(
                      size: 14,
                      margin: 5,
                      code: () => widget.screen.actionCode,
                      title: widget.screen.name,
                      onChanged: (code, refresh) {
                        _operationCubit.updateScreenActionCode(
                            widget.screen, code);
                      },
                      config: FVBEditorConfig(
                        variables: () =>
                            [FVBVariable('context', DataType.fvbDynamic)],
                      ),
                      processor: widget.screen.processor,
                      onDismiss: () {
                        _creationCubit.changedComponent();
                      },
                    ),
                    5.wBox,
                    AppIconButton(
                      size: 14,
                      margin: 5,
                      icon: Icons.data_array,
                      background: theme.background1,
                      iconColor: Colors.blue,
                      key: variableKey,
                      onPressed: () {
                        final _variableDialog = VariableDialog(
                            options: [
                              VariableDialogOption('Move to global', (model) {
                                _operationCubit.addVariable(model);
                                widget.screen.variables.remove(model.name);
                                _operationCubit
                                    .updateScreenVariable(widget.screen);
                              })
                            ],
                            variables: widget.screen.variables,
                            componentOperationCubit: _operationCubit,
                            componentCreationCubit: _creationCubit,
                            title: widget.screen.name,
                            onAdded: (model) {
                              _operationCubit
                                  .addVariableForScreen(model as VariableModel);
                              _creationCubit.changedComponent();
                              _selectionCubit.refresh();
                            },
                            onEdited: (model) {
                              widget.screen.processor.variables[model.name]!
                                  .setValue(
                                      widget.screen.processor, model.value);
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                _operationCubit
                                    .updateScreenVariable(widget.screen);
                                _creationCubit.changedComponent();
                                _selectionCubit.refresh();
                              });
                            },
                            componentSelectionCubit: _selectionCubit,
                            onDeleted: (FVBVariable model) {
                              widget.screen.variables.remove(model.name);
                              _operationCubit
                                  .updateScreenVariable(widget.screen);
                              _creationCubit.changedComponent();
                              _selectionCubit.refresh();
                            });
                        _variableDialog.show(context, this, variableKey);
                      },
                    ),
                    5.wBox,
                    if (_permission == ProjectPermission.editor ||
                        _permission == ProjectPermission.owner)
                      CustomPopupMenuButton(
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: theme.text1Color,
                        ),
                        itemBuilder: (BuildContext context) => [
                          const CustomPopupMenuItem(
                            value: 0,
                            child: Text('Delete'),
                          ),
                          const CustomPopupMenuItem(
                            value: 1,
                            child: Text('Rename'),
                          )
                        ],
                        onSelected: (i) {
                          switch (i) {
                            case 0:
                              _onDelete.call(widget.screen);
                              break;
                            case 1:
                              showEnterInfoDialog(
                                context,
                                'Rename "${widget.screen.name}"',
                                validator: (value) {
                                  if (value == widget.screen.name) {
                                    return 'Please enter different name';
                                  } else if (_collection.project!.screens
                                          .firstWhereOrNull((element) =>
                                              element.name == value) !=
                                      null) {
                                    return 'Screen with name "$value" already exist!';
                                  }
                                  return Validations.commonNameValidator()(
                                      value);
                                },
                                initialValue: widget.screen.name,
                                onPositive: (value) {
                                  _operationCubit.renameScreen(
                                      widget.screen, value);
                                },
                              );
                              break;
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDelete(Screen screen) {
    showConfirmDialog(
      title: 'Alert!',
      subtitle:
          'Do you really want to delete this Screen?, you will not be able to recover',
      positive: 'delete',
      negative: 'cancel',
      onPositiveTap: () {
        _operationCubit.deleteCurrentUIScreen(screen);
        _operationCubit.project!.screens.remove(screen);
        if (_operationCubit.project!.screens.isNotEmpty) {
          final newScreen = _operationCubit.project!.screens.first;
          if (newScreen.rootComponent != null) {
            _selectionCubit.changeComponentSelection(
                ComponentSelectionModel.unique(
                    newScreen.rootComponent!, newScreen.rootComponent!,
                    screen: newScreen));
          }
        }
        // _operationCubit.changeProjectScreen(newScreen);
        _creationCubit.changedComponent();
        _userDetailsCubit.updateScreen();
      },
      context: context,
    );
  }
}

void showNoNetworkDialog(BuildContext context) {
  showConfirmDialog(
    context: context,
    title: 'No Connection',
    subtitle: 'Network is not available at the moment',
    positive: 'Ok',
    dismissible: false,
  );
}

void showCustomWidgetAdd(
    BuildContext context,
    Function(CustomWidgetType type, String value, [Map<String, dynamic> code])
        param1) {
  AnimatedDialog.show(
      context,
      CustomWidgetDialog(
        onSubmit: param1,
      ),
      barrierDismissible: true);
}

Future<void> showScreenCreationDialog(BuildContext context,
    {ValueChanged<Screen>? onCreated}) async {
  await AnimatedDialog.show(
      context,
      ScreenCreationDialog(
        onCreated: onCreated,
      ),
      barrierDismissible: true);
}

class CustomActionCodeButton extends StatefulWidget {
  final String Function() code;
  final String title;
  final Processor processor;
  final void Function(String, bool) onChanged;
  final void Function() onDismiss;
  final FVBEditorConfig? config;
  final double? size;
  final double? margin;

  const CustomActionCodeButton(
      {Key? key,
      this.size,
      this.margin,
      required this.code,
      required this.title,
      required this.onChanged,
      required this.processor,
      this.config,
      required this.onDismiss})
      : super(key: key);

  @override
  State<CustomActionCodeButton> createState() => _CustomActionCodeButtonState();
}

class _CustomActionCodeButtonState extends State<CustomActionCodeButton>
    with OverlayManager {
  final ValueNotifier<bool> error = ValueNotifier<bool>(false);
  late FVBCodeEditorDialog dialog;
  final key = GlobalKey();

  @override
  void dispose() {
    destroyOverlays();
    super.dispose();
  }

  @override
  void initState() {
    dialog = FVBCodeEditorDialog(
        onChanged: widget.onChanged,
        onError: (message, error) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            this.error.value = error;
          });
        },
        onDismiss: widget.onDismiss,
        context: context,
        config: widget.config,
        title: widget.title,
        processor: widget.processor);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BadgeWidget(
      error: error,
      child: AppIconButton(
        key: key,
        icon: Icons.code,
        size: widget.size ?? 16,
        margin: widget.margin ?? 8,
        iconColor: ColorAssets.green,
        background: theme.background1,
        onPressed: () {
          dialog.show(
            context,
            this,
            key,
            code: widget.code.call(),
          );
        },
      ),
    );
  }
}

class CustomComponentWidget extends StatefulWidget {
  final CustomComponent component;
  final SelectionCubit _selectionCubit;
  final OperationCubit _operationCubit;
  final CreationCubit _creationCubit;

  const CustomComponentWidget(
    this._selectionCubit,
    this._operationCubit,
    this._creationCubit, {
    Key? key,
    required this.component,
  }) : super(key: key);

  @override
  State<CustomComponentWidget> createState() => _CustomComponentWidgetState();
}

class _CustomComponentWidgetState extends State<CustomComponentWidget>
    with OverlayManager {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.component.rootComponent != null)
          ProcessorProvider(
            processor: widget.component.processor,
            child: ComponentTreeSublistWidget(
              component: widget.component.rootComponent!,
              ancestor: widget.component,
              parent: widget.component,
              selectionCubit: widget._selectionCubit,
              operationCubit: widget._operationCubit,
              creationCubit: widget._creationCubit,
              named: null,
              componentParameter: null,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CustomDragTarget(
                builder: (context, candidateData, rejectedData, _) {
              if (candidateData.isNotEmpty) {
                return OnDragWidget(
                  component: widget.component,
                );
              }
              return DottedBorder(
                color: ColorAssets.theme,
                radius: const Radius.circular(4),
                borderType: BorderType.RRect,
                strokeWidth: 1.5,
                dashPattern: [4, 4],
                child: GestureDetector(
                  onTap: () {
                    showSelectionDialog(context, (p0) {});
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Tap or Drop a child',
                      style: AppFontStyle.lato(13, color: ColorAssets.theme),
                    ),
                  ),
                ),
              );
            }, onWillAccept: (data, _) {
              return data is String ||
                  data is SameComponent ||
                  data is FavouriteModel ||
                  (data is Component) && data != widget.component;
            }, onAccept: (data, _) async {
              bool removeOld = true;
              if (!shouldRemoveFromOldAncestor(data!)) {
                data = getComponentFromDragData(context, data);
                removeOld = false;
              }
              assert(data is Component);
              final root = (data as Component).getCustomComponentRoot() ??
                  widget._selectionCubit.selected.viewable!.rootComponent!;
              if (removeOld)
                widget._operationCubit
                    .removeAllComponent(data, root, clear: false);
              await widget._operationCubit.addOperation(
                context,
                widget.component,
                data,
                widget.component,
                undo: true,
              );

              widget._creationCubit
                  .changedComponent(ancestor: widget.component);
              widget._operationCubit.updateState(root);
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                widget._selectionCubit.changeComponentSelection(
                    ComponentSelectionModel.unique(
                        data as Component, widget.component,
                        screen: ViewableProvider.maybeOf(context)));
              });
            }),
          )
      ],
    );
  }
}

class SingleChildWidget extends StatelessWidget {
  final Component component;
  final Component child;
  final Component ancestor;
  final ComponentParameter? componentParameter;
  final OperationCubit componentOperationCubit;
  final SelectionCubit componentSelectionCubit;
  final CreationCubit componentCreationCubit;
  final String? named;
  final ComponentParameter? parameter;

  const SingleChildWidget({
    Key? key,
    this.componentParameter,
    required this.component,
    required this.ancestor,
    required this.child,
    required this.componentOperationCubit,
    required this.componentSelectionCubit,
    required this.componentCreationCubit,
    this.named,
    this.parameter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 0),
      child: ComponentTreeSublistWidget(
        component: child,
        parent: component,
        componentParameter: componentParameter,
        ancestor: ancestor,
        selectionCubit: componentSelectionCubit,
        operationCubit: componentOperationCubit,
        creationCubit: componentCreationCubit,
        named: named,
      ),
    );
  }
}

class ComponentParameterWidget extends StatelessWidget {
  final Component component;
  final Component ancestor;
  final OperationCubit componentOperationCubit;
  final SelectionCubit componentSelectionCubit;
  final CreationCubit componentCreationCubit;

  const ComponentParameterWidget(
      {Key? key,
      required this.component,
      required this.ancestor,
      required this.componentOperationCubit,
      required this.componentSelectionCubit,
      required this.componentCreationCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 0),
      child: Column(children: [
        for (final child in component.componentParameters) ...[
          Column(
            children: [
              CustomDragTarget(onWillAccept: (data, _) {
                return data is String ||
                    data is FavouriteModel ||
                    data is SameComponent ||
                    (data is Component &&
                        data != component &&
                        !child.components.contains(data));
              }, onAccept: (object, _) {
                bool removeOld = true;
                if (!shouldRemoveFromOldAncestor(object!)) {
                  object = getComponentFromDragData(context, object);
                  removeOld = false;
                }
                assert(object is Component);
                componentOperationCubit.reversibleComponentOperation(
                    ViewableProvider.maybeOf(context)!, () async {
                  if (removeOld) {
                    componentOperationCubit.removeAllComponent(
                        object as Component, ancestor,
                        clear: false);
                  }
                  await componentOperationCubit.addOperation(
                      context, component, object as Component, ancestor,
                      undo: true,
                      componentParameter: child,
                      componentParameterOperation: true);
                  componentCreationCubit.changedComponent();
                  componentOperationCubit.updateState(ancestor);
                  componentSelectionCubit.changeComponentSelection(
                      ComponentSelectionModel.unique(object, ancestor,
                          screen: ViewableProvider.maybeOf(context)!));
                }, ancestor);
              }, builder: (context, list1, list2, _) {
                if (list1.isNotEmpty) {
                  return OnDragWidget(
                    component: component,
                    title: '${component.name} -> ${child.displayName}',
                  );
                }
                return SizedBox(
                  height: 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        child.displayName!,
                        style: AppFontStyle.lato(12,
                            color: theme.text3Color,
                            fontWeight: FontWeight.w500),
                      ),
                      OperationMenu(
                          component: component,
                          ancestor: ancestor,
                          componentParameterOperation: true,
                          disableOperations: true,
                          menuEnable: false,
                          componentParameter: child,
                          componentSelectionCubit: componentSelectionCubit,
                          operationCubit: componentOperationCubit,
                          creationCubit: componentCreationCubit),
                    ],
                  ),
                );
              }),
              if (child.multiple && child.components.isNotEmpty)
                MultipleChildWidget(
                    component: component,
                    ancestor: ancestor,
                    componentParameter: child,
                    children: child.components,
                    extraHeight: -35,
                    componentOperationCubit: componentOperationCubit,
                    componentSelectionCubit: componentSelectionCubit,
                    componentCreationCubit: componentCreationCubit)
              else if (child.components.isNotEmpty)
                SingleChildWidget(
                    component: component,
                    ancestor: ancestor,
                    componentParameter: child,
                    child: child.components.first,
                    componentOperationCubit: componentOperationCubit,
                    componentSelectionCubit: componentSelectionCubit,
                    componentCreationCubit: componentCreationCubit),
            ],
          ),
          const SizedBox(
            height: 5,
          )
        ]
      ]),
    );
  }
}

class ProjectMainMenu extends StatefulWidget {
  const ProjectMainMenu({super.key});

  @override
  State<ProjectMainMenu> createState() => _ProjectMainMenuState();
}

class _ProjectMainMenuState extends State<ProjectMainMenu> with OverlayManager {
  final GlobalKey _projectVariableKey = GlobalKey(),
      _projectModelKey = GlobalKey();
  late FVBCodeEditorDialog dialog;
  late OperationCubit _operationCubit;
  late CreationCubit _creationCubit;
  final codeButtonKey = GlobalKey();
  final UserSession _userSession = sl();
  late ProjectPermission _permission;

  final AnimatedSlider _variableSlider = AnimatedSlider(),
      _modelSlider = AnimatedSlider();

  @override
  void initState() {
    _permission = _collection.project!.userRole(_userSession);
    _operationCubit = context.read<OperationCubit>();
    _creationCubit = context.read<CreationCubit>();
    dialog = FVBCodeEditorDialog(
      context: context,
      title: 'main.dart',
      onChanged: (String value, refresh) {
        _operationCubit.updateActionCode(value);
      },
      onDismiss: () {
        _creationCubit.changedComponent();
      },
      onError: (message, bool error) {
        // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        //   error.value = error;
        // });
      },
      processor: _collection.project!.processor,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _collection.project!.name,
              style: AppFontStyle.subtitleStyle(),
              overflow: TextOverflow.ellipsis,
            ),
            3.hBox,
            Text(
              'main.dart',
              style: AppFontStyle.lato(
                12,
                color: theme.text3Color.withOpacity(0.7),
              ),
            ),
          ],
        )),
        5.wBox,
        // CustomActionCodeButton(
        //   code: () => screen.actionCode,
        //   title: screen.name,
        //   onChanged: (code, refresh) {
        //     _operationCubit.updateScreenActionCode(screen, code);
        //   },
        //   config: FVBEditorConfig(
        //     variables: () => [FVBVariable('context', DataType.fvbDynamic)],
        //   ),
        //   processor: screen.processor,
        //   onDismiss: () {
        //     _componentCreationCubit.changedComponent();
        //   },
        // ),
        AppIconButton(
          icon: Icons.code,
          background: theme.background1,
          iconColor: Colors.green,
          key: codeButtonKey,
          size: 14,
          margin: 5,
          onPressed: () {
            dialog.show(
              context,
              this,
              codeButtonKey,
              code: collection.project?.actionCode ?? '',
            );
          },
        ),
        5.wBox,
        AppIconButton(
          icon: Icons.data_array,
          background: theme.background1,
          key: _projectVariableKey,
          iconColor: Colors.blue,
          size: 14,
          margin: 5,
          onPressed: () {
            if (_variableSlider.visible) {
              _variableSlider.hide();
            } else {
              _variableSlider.show(
                context,
                this,
                const ProjectVariableBox(),
                _projectVariableKey,
              );
            }
          },
        ),
        5.wBox,
        AppIconButton(
          icon: Icons.storage,
          background: theme.background1,
          key: _projectModelKey,
          size: 14,
          margin: 5,
          iconColor: Colors.blue,
          onPressed: () {
            if (_modelSlider.visible) {
              _modelSlider.hide();
            } else {
              _modelSlider.show(
                context,
                this,
                const ModelBox(),
                _projectModelKey,
              );
            }
          },
        ),
        if (_permission == ProjectPermission.owner) ...[
          5.wBox,
          CustomPopupMenuButton(
            child: const Icon(
              Icons.more_vert_rounded,
              color: ColorAssets.darkerTheme,
              size: 18,
            ),
            itemBuilder: (BuildContext context) => [
              const CustomPopupMenuItem(
                value: 0,
                child: Text('Delete'),
              ),
              const CustomPopupMenuItem(
                value: 1,
                child: Text('Rename'),
              ),
              if (kDebugMode)
                const CustomPopupMenuItem(
                  value: 2,
                  child: Text('Add to Templates'),
                )
            ],
            onSelected: (i) {
              switch (i) {
                case 0:
                  deleteProject(context, _collection.project!);
                  break;
                case 1:
                  renameProject(context, _collection.project!);
                  break;
                case 2:
                  addToTemplates(context, _collection.project!);
                  break;
              }
            },
          )
        ],
      ],
    );
  }
}

class MultipleChildWidget extends StatelessWidget {
  final Component component;
  final List<Component> children;
  final Component ancestor;
  final double extraHeight;
  final String? named;
  final ComponentParameter? componentParameter;
  final OperationCubit componentOperationCubit;
  final SelectionCubit componentSelectionCubit;
  final CreationCubit componentCreationCubit;

  const MultipleChildWidget(
      {Key? key,
      required this.component,
      required this.ancestor,
      required this.children,
      this.extraHeight = 0,
      this.named,
      this.componentParameter,
      required this.componentOperationCubit,
      required this.componentSelectionCubit,
      required this.componentCreationCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 2, top: 0),
      padding: const EdgeInsets.only(left: 2, top: 0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(width: 0.7, color: theme.line),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext _, int index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpDownButtons(
                  componentOperationCubit, component, ancestor, children, index,
                  parameter: componentParameter, named: named),
              Expanded(
                child: ComponentTreeSublistWidget(
                  component: children[index],
                  ancestor: ancestor,
                  parent: component,
                  componentParameter: componentParameter,
                  operationCubit: componentOperationCubit,
                  creationCubit: componentCreationCubit,
                  selectionCubit: componentSelectionCubit,
                  named: named,
                ),
              ),
            ],
          );
        },
        itemCount: children.length,
      ),
    );
  }

  double getCalculatedHeight(final Component component) {
    switch (component.type) {
      case 1:
        double height = 35;
        for (final compParam in component.componentParameters) {
          height += 30;
          for (final comp in compParam.components) {
            height += getCalculatedHeight(comp);
          }
        }
        return height;
      case 5:
        return 35;
      case 2:
        double height = 35;
        for (final Component comp in (component as MultiHolder).children) {
          height += getCalculatedHeight(comp);
        }
        for (final compParam in component.componentParameters) {
          height += 30;
          for (final comp in compParam.components) {
            height += getCalculatedHeight(comp);
          }
        }

        return height;
      case 3:
        double height = 35;
        for (final compParam in component.componentParameters) {
          height += 30;
          for (final comp in compParam.components) {
            height += getCalculatedHeight(comp);
          }
        }
        return (component as Holder).child != null
            ? height + getCalculatedHeight(component.child!)
            : height;
      case 4:
        double height = 0;
        for (final Component? comp
            in (component as CustomNamedHolder).childMap.values) {
          height += 40;
          if (comp != null) {
            height += getCalculatedHeight(comp);
          }
        }
        for (final compParam in component.componentParameters) {
          height += 30;
          for (final comp in compParam.components) {
            height += getCalculatedHeight(comp);
          }
        }
        return height;
    }
    return 0;
  }
}

class UpDownButtons extends StatelessWidget {
  final OperationCubit componentOperationCubit;
  final Component component, ancestor;
  final List<Component> children;
  final int index;
  final ComponentParameter? parameter;
  final String? named;

  const UpDownButtons(
    this.componentOperationCubit,
    this.component,
    this.ancestor,
    this.children,
    this.index, {
    Key? key,
    required this.parameter,
    required this.named,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            componentOperationCubit.arrangeComponentOperation(
              context,
              component,
              index,
              (index - 1) >= 0 ? index - 1 : children.length - 1,
              ancestor,
              parameter: parameter,
              named: named,
            );
          },
          child: Icon(
            Icons.keyboard_arrow_up,
            size: 14,
            color: theme.dropDownColor1,
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            componentOperationCubit.arrangeComponentOperation(
              context,
              component,
              index,
              index + 1 < children.length ? index + 1 : 0,
              ancestor,
              parameter: parameter,
              named: named,
            );
          },
          child: Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: theme.dropDownColor1,
          ),
        ),
      ],
    );
  }
}

void removeAll(
  BuildContext context,
  OperationCubit operationCubit,
  CreationCubit creationCubit,
  SelectionCubit selectionCubit,
  Component component,
  Component ancestor,
  ComponentParameter? componentParameter,
) {
  operationCubit
      .reversibleComponentOperation(ViewableProvider.maybeOf(context)!, () {
    if (component.parent is ComponentParameter) {
      operationCubit.removeRootComponentFromComponentParameter(
          componentParameter!, component,
          removeAll: true);
      creationCubit.changedComponent();
    } else {
      final parent = component.parent;
      operationCubit.removeAllComponent(component, ancestor);
      if (parent != null && parent is Component) {
        selectionCubit.changeComponentSelection(ComponentSelectionModel.unique(
            parent, ancestor,
            screen: ViewableProvider.maybeOf(context)));
      }
      operationCubit.removedComponent();
      creationCubit.changedComponent();
    }
  }, ancestor);
}

void showSelectionDialog(
    BuildContext context, void Function(Component) onSelection,
    {List<String>? possibleItems, bool favouritesEnable = true}) {
  AnimatedDialog.show(
    context,
    ComponentSelectionDialog(
      possibleItems: possibleItems,
      onSelection: onSelection,
      shouldShowFavourites: favouritesEnable,
    ),
  );
}

final UserProjectCollection _collection = sl<UserProjectCollection>();

class ComponentTile extends StatefulWidget {
  final Component component;
  final Component ancestor;
  final ComponentParameter? parameter;
  final String? named;
  final Color? color;

  final SelectionCubit componentSelectionCubit;

  const ComponentTile(
      {Key? key,
      this.color,
      required this.component,
      required this.ancestor,
      required this.componentSelectionCubit,
      required this.parameter,
      required this.named})
      : super(key: key);

  @override
  State<ComponentTile> createState() => _ComponentTileState();
}

class _ComponentTileState extends State<ComponentTile> with GetProcessor {
  final _focusNode = FocusNode();
  late OperationCubit componentOperationCubit;
  late VisualBoxCubit visualBoxCubit;
  final ValueNotifier<bool> _hoverNotifier = ValueNotifier(false);

  void _onClick() {
    final List<Component> clones = widget.component.getAllClones();
    _focusNode.requestFocus();
    widget.componentSelectionCubit.changeComponentSelection(
        ComponentSelectionModel(
            [widget.component],
            [widget.component, ...clones],
            widget.component,
            widget.component,
            widget.ancestor,
            viewable: ViewableProvider.maybeOf(context)),
        scroll: false);
    if (GlobalObjectKey(widget.component).currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Scrollable.ensureVisible(
            GlobalObjectKey(widget.component).currentContext!,
            alignment: 0.5);
      });
    }
  }

  @override
  void initState() {
    componentOperationCubit = context.read<OperationCubit>();
    visualBoxCubit = context.read<VisualBoxCubit>();
    super.initState();
  }

  void arrange(bool up,
      {required ComponentParameter? parameter, required String? named}) {
    if (widget.component.parent is MultiHolder) {
      final parent = widget.component.parent as MultiHolder;
      final index = parent.children.indexOf(widget.component);
      componentOperationCubit.arrangeComponentOperation(
          context,
          widget.component,
          index,
          up
              ? (index - 1) >= 0
                  ? index - 1
                  : parent.children.length - 1
              : (index + 1) % parent.children.length,
          widget.ancestor,
          parameter: widget.parameter,
          named: widget.named);
    } else if (widget.component.parent is CustomNamedHolder &&
        !(widget.component.parent as CustomNamedHolder)
            .childMap
            .containsValue(widget.component)) {
      final parent = widget.component.parent as CustomNamedHolder;
      final named = (parent.childrenMap.entries.firstWhere(
          (element) => element.value.contains(widget.component))).key;
      final children = parent.childrenMap[named]!;
      final index = children.indexOf(widget.component);
      componentOperationCubit.arrangeComponentOperation(
          context,
          widget.component,
          index,
          up
              ? (index - 1) >= 0
                  ? index - 1
                  : children.length - 1
              : (index + 1) % children.length,
          widget.ancestor,
          parameter: widget.parameter,
          named: widget.named);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: BlocListener<VisualBoxCubit, VisualBoxState>(
        bloc: visualBoxCubit,
        listener: (_, state) {
          if (state is VisualBoxHoverUpdatedState) {
            final hovering = state.boundaries.firstWhereOrNull(
                    (element) => element.comp.id == widget.component.id) !=
                null;
            _hoverNotifier.value = hovering;
          }
        },
        listenWhen: (_, state) => state is VisualBoxHoverUpdatedState,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.delete): () {
              if (context.read<SelectionCubit>().selected.intendedSelection
                  is! CCustomPaint) {
                removeAll(
                    context,
                    componentOperationCubit,
                    context.read<CreationCubit>(),
                    context.read<SelectionCubit>(),
                    widget.component,
                    widget.ancestor,
                    widget.parameter);
              } else {
                context.read<PaintObjBloc>().add(RemovePaintObjEvent());
              }
            },
            const SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
                () {
              arrange(true, named: widget.named, parameter: widget.parameter);
            },
            const SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
                () {
              arrange(false, named: widget.named, parameter: widget.parameter);
            },
            const SingleActivator(LogicalKeyboardKey.arrowUp): () {
              move(true);
            },
            const SingleActivator(LogicalKeyboardKey.arrowDown): () {
              move(false);
            },
            const SingleActivator(LogicalKeyboardKey.keyD, control: true): () {
              componentOperationCubit.duplicateComponentOperation(
                  context, widget.component, widget.ancestor, widget.named);
            },
            const SingleActivator(LogicalKeyboardKey.keyC, control: true): () {
              Clipboard.setData(
                  ClipboardData(text: jsonEncode(widget.component.toJson())));
              clipboardProvider.addData(ComponentWithProcessor(widget.component,
                  needfulProcessor(context.read<SelectionCubit>())));
            },
            const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                () async {
              if (widget.component is CImage) {
                final img = await Pasteboard.image;
                if (img != null) {
                  final name = '${DateTime.now().toString()}';
                  byteCache[name] = img;
                  collection.project!.imageList.add(name);
                  final image = FVBImage(bytes: img, name: name);
                  componentOperationCubit.uploadImage(image);
                  if (widget.component is CImage) {
                    (widget.component.parameters[0] as ChoiceParameter).val =
                        (widget.component.parameters[0] as ChoiceParameter)
                            .options[0];
                    ((widget.component.parameters[0] as ChoiceParameter)
                            .options[0] as SimpleParameter)
                        .compiler
                        .code = name;
                    ((widget.component.parameters[0] as ChoiceParameter).val
                            as SimpleParameter)
                        .defaultValue = image;
                    context.read<StateManagementBloc>().add(
                        StateManagementUpdateEvent(
                            widget.component, RuntimeMode.edit));
                  } else {
                    final comp = CImage();
                    (comp.parameters[0] as ChoiceParameter).val =
                        (comp.parameters[0] as ChoiceParameter).options[0];
                    ((comp.parameters[0] as ChoiceParameter).options[0]
                            as SimpleParameter)
                        .compiler
                        .code = name;
                    ((comp.parameters[0] as ChoiceParameter).val
                            as SimpleParameter)
                        .defaultValue = image;
                    componentOperationCubit.performAddOperation(
                      context,
                      widget.component,
                      comp,
                      widget.ancestor,
                      componentParameterOperation: false,
                      componentParameter: widget.parameter,
                      customNamed: widget.named,
                      undo: true,
                    );
                  }
                }
              } else if (widget.component is CText) {
                final text = await Pasteboard.text;
                if (text != null) {
                  widget.component.parameters[0].compiler.code = '$text';
                  context
                      .read<ParameterBuildCubit>()
                      .parameterChanged(widget.component.parameters[0]);
                }
              } else if ([2, 3].contains(widget.component.type)) {
                if (clipboardProvider.data.isNotEmpty) {
                  componentOperationCubit.performAddOperation(
                    context,
                    widget.component,
                    clipboardProvider.data.first.component
                        .clone(null, deepClone: true, connect: false),
                    widget.ancestor,
                    componentParameterOperation: false,
                    componentParameter: widget.parameter,
                    customNamed: widget.named,
                    undo: true,
                  );
                }
              }
            },
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CustomDraggable(
              onDragUpdate: (details) {},
              data: widget.component,
              area: DragArea.tree,
              childWhenDragging: Material(
                color: Colors.transparent,
                child: Container(
                  height: 24,
                  width: 100,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 2.5, vertical: 2.5),
                ),
              ),
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  height: 24,
                  width: 100,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: theme.background2,
                      boxShadow: kElevationToShadow[10],
                      border: Border.all(
                          color: theme.text1Color.withOpacity(0.3),
                          width: 0.4)),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 2.5, vertical: 2.5),
                  child: Text(
                    widget.component.name,
                    maxLines: 1,
                    style: AppFontStyle.subtitleStyle(),
                  ),
                ),
              ),
              child: InkWell(
                focusNode: _focusNode,
                autofocus: true,
                onTap: () {
                  _onClick();
                },
                child: BlocConsumer<SelectionCubit, SelectionState>(
                  bloc: widget.componentSelectionCubit,
                  listener: (context, state) {
                    if (state is SelectionChangeState) {
                      final selectedComponent =
                          widget.componentSelectionCubit.selected;
                      if ((selectedComponent.treeSelection
                          .contains(widget.component))) {
                        WidgetsBinding.instance
                            .addPostFrameCallback((timeStamp) {
                          _focusNode.requestFocus();
                        });
                      }
                    }
                  },
                  listenWhen: (state1, state2) {
                    if (state2 is SelectionChangeState) {
                      if (state2.model.treeSelection
                              .contains(widget.component) ||
                          state2.oldModel.treeSelection
                              .contains(widget.component)) {
                        return true;
                      }
                    }
                    return false;
                  },
                  builder: (context, state) {
                    final selectedComponent =
                        widget.componentSelectionCubit.selected;
                    final selected = (selectedComponent.treeSelection
                        .contains(widget.component));
                    return ValueListenableBuilder(
                        valueListenable: _hoverNotifier,
                        builder: (context, hovering, _) {
                          return Container(
                            height: 22,
                            key: GlobalObjectKey(widget.component.uniqueId),
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.symmetric(vertical: 2.5),
                            decoration: BoxDecoration(
                              border: hovering
                                  ? Border.all(
                                      color: ColorAssets.theme, width: 0.5)
                                  : null,
                              borderRadius:
                                  hovering ? BorderRadius.circular(4) : null,
                              gradient: selected
                                  ? RadialGradient(
                                      colors: [
                                        ColorAssets.theme.withOpacity(0.04),
                                        ColorAssets.theme.withOpacity(0.08),
                                      ],
                                      radius: 3,
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BlocBuilder<OperationCubit, OperationState>(
                                  builder: (context, state) {
                                    return Visibility(
                                      visible: sl<OperationCubit>()
                                          .isFavourite(widget.component),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 5),
                                        child: Icon(
                                          Icons.star,
                                          size: 15,
                                          color: Colors.yellow.shade600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (componentImages
                                    .containsKey(widget.component.name)) ...[
                                  Image.asset(
                                    Images.componentImages +
                                        componentImages[
                                            widget.component.name]! +
                                        '.png',
                                    width: 15,
                                    color: widget.componentSelectionCubit
                                            .isErrorEnable(widget.component)
                                        ? ColorAssets.red
                                        : (selected
                                            ? ColorAssets.theme
                                            : theme.text1Color),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  )
                                ],
                                Flexible(
                                  child: Text(
                                    StringOperation.toNormalCase(
                                        widget.component.name),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFontStyle.lato(12,
                                        color: widget.componentSelectionCubit
                                                .isErrorEnable(widget.component)
                                            ? ColorAssets.red
                                            : (selected
                                                ? ColorAssets.theme
                                                : theme.text1Color),
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void move(bool up) {
    Component? selected;

    final parent = widget.component.parent;
    if (up) {
      if (parent is CustomNamedHolder) {
        if (parent.childMap.containsValue(widget.component)) {
          final entries = parent.childMap.entries.toList(growable: false);
          if (entries.length > 1) {
            final key = entries
                .firstWhere((element) => element.value == widget.component)
                .key;
            final index = entries.indexWhere((element) => element.key == key);
            if (index >= 1) {
              selected = entries[index - 1].value;
            } else {
              selected = parent;
            }
          } else {
            selected = parent;
          }
        } else {
          final key = parent.childrenMap.entries
              .firstWhere((element) => element.value.contains(widget.component))
              .key;
          final index = parent.childrenMap[key]!.indexOf(widget.component);
          if (index == 0) {
            selected = parent;
          } else {
            selected = parent.childrenMap[key]![index - 1];
          }
        }
      } else if (parent is MultiHolder) {
        final index = parent.children.indexOf(widget.component);
        if (index == 0) {
          selected = parent;
        } else {
          selected = parent.children[index - 1];
        }
      } else if (parent is Holder) {
        selected = parent;
      }
    } else {
      if (widget.component is Holder &&
          (widget.component as Holder).child != null) {
        selected = (widget.component as Holder).child;
      } else if (widget.component is MultiHolder &&
          (widget.component as MultiHolder).children.isNotEmpty) {
        selected = (widget.component as MultiHolder).children.first;
      } else if (parent is MultiHolder) {
        final index = parent.children.indexOf(widget.component);
        if (index == parent.children.length - 1) {
          selected = parent;
        } else {
          selected = parent.children[index + 1];
        }
      } else if (parent is CustomNamedHolder) {
        if (parent.childMap.containsValue(widget.component)) {
          final entries = parent.childMap.entries.toList(growable: false);
          if (entries.length > 1) {
            final key = entries
                .firstWhere((element) => element.value == widget.component)
                .key;
            final index = entries.indexWhere((element) => element.key == key);
            if (index < entries.length - 1) {
              selected = entries[index + 1].value;
            } else {
              selected = parent;
            }
          } else {
            selected = parent;
          }
        } else {
          final key = parent.childrenMap.entries
              .firstWhere((element) => element.value.contains(widget.component))
              .key;
          final index = parent.childrenMap[key]!.indexOf(widget.component);
          if (index == parent.childrenMap[key]!.length - 1) {
            selected = parent;
          } else {
            selected = parent.childrenMap[key]![index + 1];
          }
        }
      } else if (parent?.parent is MultiHolder) {
        final index = (parent!.parent as MultiHolder).children.indexOf(parent);
        if (index < (parent.parent as MultiHolder).children.length - 1) {
          selected = (parent.parent as MultiHolder).children[index + 1];
        } else {
          selected = parent.parent;
        }
      }
    }
    if (selected != null) {
      widget.componentSelectionCubit.changeComponentSelection(
          ComponentSelectionModel(
              [selected], [selected], selected, selected, widget.ancestor,
              viewable: ViewableProvider.maybeOf(context)!));
    }
  }
}

Component getComponentFromDragData(BuildContext context, Object? data) {
  if (data is String) {
    if (componentList.containsKey(data)) {
      final comp = componentList[data]!.call();
      comp.onFreshAdded();
      context.read<OperationCubit>().addInSameComponentList(comp);
      return comp;
    } else {
      final comp = _collection.project!.customComponents
          .firstWhere((element) => element.name == data)
          .createInstance(null);
      context.read<OperationCubit>().addInSameComponentList(comp);
      return comp;
    }
  } else if (data is FavouriteModel) {
    return sl<OperationCubit>().favouriteInComponent(data);
  } else if (data is CustomComponent) {
    return data.createInstance(null);
  } else if (data is Component) {
    return data.clone(null, deepClone: true, connect: false);
  } else if (data is SameComponent) {
    return data.component.clone(null, deepClone: true, connect: false);
  } else {
    throw Exception(''
        'getComponentFromDragData:: unhandled drop $data ${data.runtimeType}');
  }
}

bool shouldRemoveFromOldAncestor(Object? data) {
  return (data is! String && data is! FavouriteModel) &&
      (data is! CustomComponent || data.parent != null) &&
      (data is! SameComponent);
}
