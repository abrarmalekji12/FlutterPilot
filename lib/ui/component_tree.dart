import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../code_to_component.dart';
import '../models/operation_model.dart';
import '../models/other_model.dart';
import '../common/custom_drop_down.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../common/app_button.dart';
import '../common/app_text_field.dart';
import '../common/custom_animated_dialog.dart';
import '../common/custom_popup_menu_button.dart';
import '../cubit/flutter_project/flutter_project_cubit.dart';
import '../models/component_model.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../models/component_selection.dart';
import '../models/parameter_model.dart';
import '../models/project_model.dart';
import 'component_selection_dialog.dart';
import 'package:get/get.dart';

import '../component_list.dart';

class ComponentTree extends StatefulWidget {
  const ComponentTree({Key? key}) : super(key: key);

  @override
  _ComponentTreeState createState() => _ComponentTreeState();
}

class _ComponentTreeState extends State<ComponentTree> {
  final ScrollController _scrollController = ScrollController();
  late final ComponentOperationCubit _componentOperationCubit;
  late final ComponentCreationCubit _componentCreationCubit;
  late final ComponentSelectionCubit _componentSelectionCubit;
  late final FlutterProjectCubit _flutterProjectCubit;

  @override
  void initState() {
    super.initState();
    _componentOperationCubit =
        BlocProvider.of<ComponentOperationCubit>(context, listen: false);
    _componentCreationCubit =
        BlocProvider.of<ComponentCreationCubit>(context, listen: false);
    _componentSelectionCubit =
        BlocProvider.of<ComponentSelectionCubit>(context, listen: false);
    _flutterProjectCubit =
        BlocProvider.of<FlutterProjectCubit>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        size: 18,
                      )),
                  const SizedBox(
                    width: 20,
                  ),
                  Text(
                    BlocProvider.of<ComponentOperationCubit>(context,
                            listen: false)
                        .flutterProject!
                        .name,
                    style: AppFontStyle.roboto(16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
                bloc: _componentOperationCubit,
                builder: (context, state) {
                  if (state is ComponentOperationLoadingState) {
                    return const Icon(
                      Icons.cloud_upload,
                      color: Colors.blueAccent,
                      size: 20,
                    );
                  } else if (state is ComponentOperationErrorState) {
                    return InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(10),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    );
                  }
                  return Row(
                    children: [
                      if (_componentOperationCubit.revertWork.totalOperations >
                          0)
                        InkWell(
                          onTap: () {
                            _componentOperationCubit.revertWork.undo();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Icon(
                            Icons.undo,
                            color: Colors.black,
                          ),
                        ),
                      const SizedBox(
                        width: 30,
                      ),
                      const Icon(
                        Icons.cloud_done,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ],
                  );
                },
              )
            ],
          ),
        ),
        if (_componentOperationCubit.flutterProject!.uiScreens.isNotEmpty)
          BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Screens',
                            style: AppFontStyle.roboto(13,
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                          ),
                          SizedBox(
                              height: 50,
                              child: CustomDropdownButton<UIScreen>(
                                  style: AppFontStyle.roboto(13),
                                  value: _componentOperationCubit
                                      .flutterProject!.currentScreen,
                                  hint: null,
                                  items: _componentOperationCubit
                                      .flutterProject!.uiScreens
                                      .map<CustomDropdownMenuItem<UIScreen>>(
                                        (e) => CustomDropdownMenuItem<UIScreen>(
                                          value: e,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              e.name,
                                              style: AppFontStyle.roboto(13,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value !=
                                        _componentOperationCubit
                                            .flutterProject!.currentScreen) {
                                      _componentOperationCubit.flutterProject!
                                          .currentScreen = value;
                                      _componentOperationCubit
                                              .flutterProject!.rootComponent =
                                          _componentOperationCubit
                                              .flutterProject!
                                              .currentScreen!
                                              .rootComponent;
                                      _componentOperationCubit
                                          .emit(ComponentUpdatedState());
                                      _componentSelectionCubit
                                          .emit(ComponentSelectionChange());
                                      _componentCreationCubit
                                          .changedComponent();
                                    }
                                  },
                                  selectedItemBuilder: (context, config) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        config.name,
                                        style: AppFontStyle.roboto(13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  })),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showCustomWidgetRename(context, 'Enter Screen Name',
                            (name) {
                          final screen = UIScreen.otherScreen(name);
                          _componentOperationCubit.flutterProject!.uiScreens
                              .add(screen);
                          _componentOperationCubit
                              .flutterProject!.currentScreen = screen;
                          _componentOperationCubit
                                  .flutterProject!.rootComponent =
                              _componentOperationCubit
                                  .flutterProject!.currentScreen!.rootComponent;
                          _componentOperationCubit
                              .emit(ComponentUpdatedState());
                          _componentSelectionCubit
                              .emit(ComponentSelectionChange());
                          _componentCreationCubit.changedComponent();
                          Get.back();
                        });
                      },
                      icon: const Icon(
                        Icons.add,
                        color: Colors.blueAccent,
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        Expanded(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: StatefulBuilder(builder: (context, setState2) {
                    if (!_scrollController.hasListeners) {
                      _scrollController.addListener(() {
                        setState2(() {});
                      });
                    }
                    return FractionallySizedBox(
                      heightFactor: _scrollController.hasClients &&
                              _scrollController.position.maxScrollExtent > 0
                          ? (_scrollController.offset /
                              _scrollController.position.maxScrollExtent)
                          : 0,
                      child: Container(
                        width: 3,
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
                child: Align(
                  alignment: Alignment.topLeft,
                  child: BlocListener<ComponentSelectionCubit,
                      ComponentSelectionState>(
                    listener: (context, state) {
                      if (state is ComponentSelectionChange && state.scroll) {
                        scrollToSelected();
                      }
                    },
                    child: BlocBuilder<ComponentOperationCubit,
                        ComponentOperationState>(
                      bloc: _componentOperationCubit,
                      buildWhen: (state1, state2) {
                        debugPrint(
                            '=== ComponentOperationCubit == buildWhen ${state1.runtimeType} to ${state2.runtimeType}');
                        if (state2 is ComponentUpdatedState) {
                          return true;
                        }
                        return false;
                      },
                      builder: (context, state) {
                        debugPrint(
                            '=== ComponentOperationCubit == state ${state.runtimeType}');
                        return SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.all(6),
                                child: SublistWidget(
                                    component: _componentOperationCubit
                                        .flutterProject!.rootComponent!,
                                    ancestor: _componentOperationCubit
                                        .flutterProject!.rootComponent!,
                                    componentSelectionCubit:
                                        _componentSelectionCubit,
                                    componentOperationCubit:
                                        _componentOperationCubit,
                                    componentCreationCubit:
                                        _componentCreationCubit),
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.all(10),
                              //   child: Row(
                              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //     children: [
                              //       Text(
                              //         'Custom Widgets',
                              //         style: AppFontStyle.roboto(14,
                              //             color: const Color(0xff494949),
                              //             fontWeight: FontWeight.bold),
                              //       ),
                              //       InkWell(
                              //         borderRadius: BorderRadius.circular(10),
                              //         onTap: () {
                              //           //ADD Custom Widgets
                              //           showCustomWidgetRename(
                              //               context, 'Enter widget name', (name) {
                              //             Get.back();
                              //
                              //             BlocProvider.of<ComponentOperationCubit>(
                              //                     context,
                              //                     listen: false)
                              //                 .addCustomComponent(name);
                              //           });
                              //         },
                              //         child: const CircleAvatar(
                              //           radius: 10,
                              //           backgroundColor: AppColors.theme,
                              //           child: Icon(
                              //             Icons.add,
                              //             size: 15,
                              //             color: Colors.white,
                              //           ),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              // for (final CustomComponent comp in _componentOperationCubit
                              //     .flutterProject!.customComponents) ...[
                              //   Row(
                              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //     children: [
                              //       Container(
                              //         decoration: BoxDecoration(
                              //             border: Border.all(
                              //                 color: AppColors.theme, width: 1.5),
                              //             borderRadius: BorderRadius.circular(4)),
                              //         padding: const EdgeInsets.all(5),
                              //         margin: const EdgeInsets.symmetric(
                              //             horizontal: 10, vertical: 5),
                              //         child: Text(
                              //           comp.name,
                              //           style: AppFontStyle.roboto(15,
                              //               color: AppColors.theme,
                              //               fontWeight: FontWeight.bold),
                              //         ),
                              //       ),
                              //       ComponentModificationMenu(
                              //         component: comp,
                              //         ancestor: comp,
                              //         componentOperationCubit: _componentOperationCubit,
                              //         componentCreationCubit: _componentCreationCubit,
                              //         componentSelectionCubit: _componentSelectionCubit,
                              //       )
                              //     ],
                              //   ),
                              //   if (comp.root != null)
                              //     Container(
                              //       alignment: Alignment.topLeft,
                              //       padding: const EdgeInsets.all(10),
                              //       child: SublistWidget(
                              //           component: comp.root!,
                              //           ancestor: comp,
                              //           componentSelectionCubit: _componentSelectionCubit,
                              //           componentOperationCubit: _componentOperationCubit,
                              //           componentCreationCubit: _componentCreationCubit),
                              //     ),
                              // ],
                              const SizedBox(
                                height: 100,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void scrollToSelected() {
    if (GlobalObjectKey(_componentSelectionCubit
                .currentSelected.treeSelection.first.uniqueId)
            .currentContext ==
        null) {
      Component comp =
          _componentSelectionCubit.currentSelected.treeSelection.first;
      while (comp.parent != null) {
        comp = comp.parent!;
        if (_componentOperationCubit.expandedTree.containsKey(comp) &&
            !(_componentOperationCubit.expandedTree[comp] ?? true)) {
          _componentOperationCubit.expandedTree[comp] = true;
          setState(() {
            WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
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
        GlobalObjectKey(_componentSelectionCubit
                .currentSelected.treeSelection.first.uniqueId)
            .currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200));
  }

  void showCustomWidgetRename(
      BuildContext context, String title, Function(String) onSubmit) {
    CustomDialog.show(
        context,
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppFontStyle.roboto(14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 40,
                  child: AppTextField(
                    value: '',
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                AppButton(
                  height: 40,
                  title: 'create',
                  onPressed: () {
                    if (AppTextField.changedValue.length > 1 &&
                        !AppTextField.changedValue.contains(' ') &&
                        !AppTextField.changedValue.contains('.')) {
                      onSubmit(AppTextField.changedValue);
                    }
                  },
                )
              ],
            ),
          ),
        ));
  }
}

class SingleChildWidget extends StatelessWidget {
  final Component component;
  final Component child;
  final Component ancestor;
  final ComponentParameter? componentParameter;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final ComponentCreationCubit componentCreationCubit;

  const SingleChildWidget(
      {Key? key,
      this.componentParameter,
      required this.component,
      required this.ancestor,
      required this.child,
      required this.componentOperationCubit,
      required this.componentSelectionCubit,
      required this.componentCreationCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 0),
      child: SublistWidget(
          component: child,
          componentParameter: componentParameter,
          ancestor: ancestor,
          componentSelectionCubit: componentSelectionCubit,
          componentOperationCubit: componentOperationCubit,
          componentCreationCubit: componentCreationCubit),
    );
  }
}

class ComponentParameterWidget extends StatelessWidget {
  final Component component;
  final Component ancestor;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final ComponentCreationCubit componentCreationCubit;

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
              SizedBox(
                height: 25,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      child.displayName!,
                      style: AppFontStyle.roboto(12,
                          color: const Color(0xff494949),
                          fontWeight: FontWeight.w500),
                    ),
                    ComponentModificationMenu(
                        component: component,
                        ancestor: ancestor,
                        componentParameterOperation: true,
                        disableOperations: true,
                        menuEnable: false,
                        componentParameter: child,
                        componentSelectionCubit: componentSelectionCubit,
                        componentOperationCubit: componentOperationCubit,
                        componentCreationCubit: componentCreationCubit),
                  ],
                ),
              ),
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

class MultipleChildWidget extends StatelessWidget {
  final Component component;
  final List<Component> children;
  final Component ancestor;
  final double extraHeight;
  final ComponentParameter? componentParameter;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final ComponentCreationCubit componentCreationCubit;

  const MultipleChildWidget(
      {Key? key,
      required this.component,
      required this.ancestor,
      required this.children,
      this.extraHeight = 0,
      this.componentParameter,
      required this.componentOperationCubit,
      required this.componentSelectionCubit,
      required this.componentCreationCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 5, top: 0),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(width: 0.4, color: Colors.grey),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemBuilder: (BuildContext _, int index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpDownButtons(componentOperationCubit, componentSelectionCubit,
                  component, ancestor, children, index),
              Expanded(
                child: SublistWidget(
                  component: children[index],
                  ancestor: ancestor,
                  componentParameter: componentParameter,
                  componentOperationCubit: componentOperationCubit,
                  componentCreationCubit: componentCreationCubit,
                  componentSelectionCubit: componentSelectionCubit,
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
  final ComponentOperationCubit componentOperationCubit;
  final Component component, ancestor;
  final List<Component> children;
  final ComponentSelectionCubit _componentSelectionCubit;
  final int index;

  const UpDownButtons(
    this.componentOperationCubit,
    this._componentSelectionCubit,
    this.component,
    this.ancestor,
    this.children,
    this.index, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            componentOperationCubit.revertWork.add(
                [index, index - 1 >= 0 ? index - 1 : children.length - 1], () {
              componentOperationCubit.arrangeComponent(
                  context,
                  component,
                  children,
                  index,
                  index - 1 >= 0 ? index - 1 : children.length - 1,
                  ancestor);
              _componentSelectionCubit.changeComponentSelection(
                  ComponentSelectionModel.unique(component),
                  root: ancestor);
            }, (p0) {
              componentOperationCubit.arrangeComponent(
                  context, component, children, p0[1], p0[0], ancestor);
            });
          },
          child: const Icon(
            Icons.arrow_drop_up,
            size: 15,
            color: Color(0xffd3d3d3),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            componentOperationCubit.arrangeComponent(
                context,
                component,
                children,
                index,
                index + 1 < children.length ? index + 1 : 0,
                ancestor);
          },
          child: const Icon(
            Icons.arrow_drop_down,
            size: 15,
            color: Color(0xffd3d3d3),
          ),
        ),
      ],
    );
  }
}

class SublistWidget extends StatefulWidget {
  final Component component, ancestor;
  final ComponentSelectionCubit componentSelectionCubit;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentCreationCubit componentCreationCubit;
  final ComponentParameter? componentParameter;

  const SublistWidget(
      {Key? key,
      this.componentParameter,
      required this.component,
      required this.ancestor,
      required this.componentSelectionCubit,
      required this.componentOperationCubit,
      required this.componentCreationCubit})
      : super(key: key);

  @override
  State<SublistWidget> createState() => _SublistWidgetState();
}

class _SublistWidgetState extends State<SublistWidget> {
  @override
  Widget build(BuildContext context) {
    final open =
        (widget.componentOperationCubit.expandedTree[widget.component] ?? true);
    if (widget.component is MultiHolder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  widget.componentOperationCubit
                      .expandedTree[widget.component] = (!(widget
                          .componentOperationCubit
                          .expandedTree[widget.component] ??
                      true));
                  setState(() {});
                },
                child: Icon(
                  open ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                  color: open ? Colors.grey.shade400 : Colors.grey.shade700,
                  size: 20,
                ),
              ),
              DragTarget(
                onWillAccept: (object) {
                  return true;
                },
                onAccept: (object) {
                  debugPrint('ACCEPTED $object');
                  BlocProvider.of<ComponentOperationCubit>(context,
                          listen: false)
                      .removeComponent(object as Component);
                  BlocProvider.of<ComponentOperationCubit>(context,
                          listen: false)
                      .addOperation(widget.component, object, widget.ancestor);
                },
                builder: (context, list1, list2) {
                  return ComponentTile(
                    component: widget.component,
                    ancestor: widget.ancestor,
                    componentSelectionCubit: widget.componentSelectionCubit,
                  );
                },
              ),
              const Spacer(),
              ComponentModificationMenu(
                component: widget.component,
                ancestor: widget.ancestor,
                componentParameter: widget.componentParameter,
                componentOperationCubit: widget.componentOperationCubit,
                componentCreationCubit: widget.componentCreationCubit,
                componentSelectionCubit: widget.componentSelectionCubit,
              )
            ],
          ),
          if ((widget.component as MultiHolder).children.isNotEmpty)
            Visibility(
              visible: widget
                      .componentOperationCubit.expandedTree[widget.component] ??
                  true,
              child: MultipleChildWidget(
                  component: widget.component,
                  ancestor: widget.ancestor,
                  componentParameter: widget.componentParameter,
                  children: (widget.component as MultiHolder).children,
                  componentOperationCubit: widget.componentOperationCubit,
                  componentSelectionCubit: widget.componentSelectionCubit,
                  componentCreationCubit: widget.componentCreationCubit),
            ),
          if (widget.component.componentParameters.isNotEmpty)
            ComponentParameterWidget(
                component: widget.component,
                ancestor: widget.ancestor,
                componentOperationCubit: widget.componentOperationCubit,
                componentSelectionCubit: widget.componentSelectionCubit,
                componentCreationCubit: widget.componentCreationCubit)
        ],
      );
    } else if (widget.component is Holder) {
      return Column(
        children: [
          Row(
            children: [
              DragTarget(onWillAccept: (object) {
                return true;
              }, onAccept: (object) {
                debugPrint('ACCEPTED $object');
                BlocProvider.of<ComponentOperationCubit>(context, listen: false)
                    .removeComponent(object as Component);
                BlocProvider.of<ComponentOperationCubit>(context, listen: false)
                    .addOperation(widget.component, object, widget.ancestor);
              }, builder: (context, list1, list2) {
                return ComponentTile(
                  component: widget.component,
                  ancestor: widget.ancestor,
                  componentSelectionCubit: widget.componentSelectionCubit,
                );
              }),
              const Spacer(),
              ComponentModificationMenu(
                component: widget.component,
                ancestor: widget.ancestor,
                componentParameter: widget.componentParameter,
                componentOperationCubit: widget.componentOperationCubit,
                componentCreationCubit: widget.componentCreationCubit,
                componentSelectionCubit: widget.componentSelectionCubit,
              )
            ],
          ),
          if ((widget.component as Holder).child != null) ...[
            SingleChildWidget(
                component: widget.component,
                ancestor: widget.ancestor,
                componentParameter: widget.componentParameter,
                child: (widget.component as Holder).child!,
                componentOperationCubit: widget.componentOperationCubit,
                componentSelectionCubit: widget.componentSelectionCubit,
                componentCreationCubit: widget.componentCreationCubit),
          ]
        ],
      );
    } else if (widget.component is CustomNamedHolder) {
      return Column(
        children: [
          Row(
            children: [
              ComponentTile(
                component: widget.component,
                ancestor: widget.ancestor,
                componentSelectionCubit: widget.componentSelectionCubit,
              ),
              const Spacer(),
              ComponentModificationMenu(
                component: widget.component,
                customNamed: null,
                componentParameter: widget.componentParameter,
                ancestor: widget.ancestor,
                componentOperationCubit: widget.componentOperationCubit,
                componentCreationCubit: widget.componentCreationCubit,
                componentSelectionCubit: widget.componentSelectionCubit,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 0),
            child: Column(children: [
              for (final child
                  in (widget.component as CustomNamedHolder).childMap.keys) ...[
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          child,
                          style: AppFontStyle.roboto(12,
                              color: const Color(0xff494949),
                              fontWeight: FontWeight.w500),
                        ),
                        ComponentModificationMenu(
                            component: widget.component,
                            customNamed: child,
                            ancestor: widget.ancestor,
                            componentSelectionCubit:
                                widget.componentSelectionCubit,
                            componentOperationCubit:
                                widget.componentOperationCubit,
                            componentCreationCubit:
                                widget.componentCreationCubit),
                      ],
                    ),
                    if ((widget.component as CustomNamedHolder)
                            .childMap[child] !=
                        null)
                      SublistWidget(
                        ancestor: widget.ancestor,
                        component: (widget.component as CustomNamedHolder)
                            .childMap[child]!,
                        componentParameter: widget.componentParameter,
                        componentSelectionCubit: widget.componentSelectionCubit,
                        componentOperationCubit: widget.componentOperationCubit,
                        componentCreationCubit: widget.componentCreationCubit,
                      ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                )
              ]
            ]),
          ),
        ],
      );
    } else if (widget.component is CustomComponent) {
      return Column(
        children: [
          Row(
            children: [
              ComponentTile(
                component: widget.component,
                ancestor: widget.ancestor,
                componentSelectionCubit: widget.componentSelectionCubit,
              ),
              const Spacer(),
              ComponentModificationMenu(
                component: widget.component,
                ancestor: widget.ancestor,
                componentParameter: widget.componentParameter,
                componentOperationCubit: widget.componentOperationCubit,
                componentCreationCubit: widget.componentCreationCubit,
                componentSelectionCubit: widget.componentSelectionCubit,
              )
            ],
          ),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            ComponentTile(
              component: widget.component,
              ancestor: widget.ancestor,
              componentSelectionCubit: widget.componentSelectionCubit,
            ),
            const Spacer(),
            ComponentModificationMenu(
              component: widget.component,
              ancestor: widget.ancestor,
              componentParameter: widget.componentParameter,
              componentOperationCubit: widget.componentOperationCubit,
              componentCreationCubit: widget.componentCreationCubit,
              componentSelectionCubit: widget.componentSelectionCubit,
            )
          ],
        ),
        if (widget.component.componentParameters.isNotEmpty)
          ComponentParameterWidget(
              component: widget.component,
              ancestor: widget.ancestor,
              componentOperationCubit: widget.componentOperationCubit,
              componentSelectionCubit: widget.componentSelectionCubit,
              componentCreationCubit: widget.componentCreationCubit)
      ],
    );
  }
}

class ComponentModificationMenu extends StatelessWidget {
  final Component component;
  final Component ancestor;
  final ComponentParameter? componentParameter;
  final String? customNamed;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentCreationCubit componentCreationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final bool menuEnable;
  final bool disableOperations;
  final bool componentParameterOperation;

  const ComponentModificationMenu(
      {Key? key,
      this.customNamed,
      this.componentParameter,
      this.menuEnable = true,
      this.disableOperations = false,
      this.componentParameterOperation = false,
      required this.component,
      required this.ancestor,
      required this.componentOperationCubit,
      required this.componentCreationCubit,
      required this.componentSelectionCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favourite = customNamed == null &&
        !componentParameterOperation &&
        componentOperationCubit.isFavourite(component);

    final components =
        componentList.map((key, value) => MapEntry(key, value()));
    return Container(
      color: const Color(0xfff2f2f2),
      child: Row(
        children: [
          if (component.type == 5 && ancestor == component) ...[
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                //rename
                showCustomWidgetRename(context, 'Rename ${component.name}',
                    (value) {
                  component.name = AppTextField.changedValue;
                  for (Component comp
                      in (component as CustomComponent).objects) {
                    comp.name = component.name;
                  }
                  Get.back();
                  componentOperationCubit.emit(ComponentUpdatedState());
                });
              },
              child: const Icon(
                Icons.edit,
                size: 15,
                color: AppColors.theme,
              ),
            ),
            const SizedBox(
              width: 3,
            ),
          ],
          if ((componentParameterOperation && !componentParameter!.isFull()) ||
              (!componentParameterOperation &&
                  componentOperationCubit.shouldAddingEnable(
                      component, ancestor, customNamed))) ...[
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                //ADDING COMPONENT
                showSelectionDialog(context, (comp) {
                  performReversibleOperation(() {
                    componentOperationCubit.addOperation(
                        component, comp, ancestor);
                    componentCreationCubit.changedComponent();
                    componentOperationCubit.addedComponent(comp, ancestor);
                    componentSelectionCubit.changeComponentSelection(
                        ComponentSelectionModel.unique(comp),
                        root: ancestor);
                  });
                },
                    possibleItems: (customNamed != null &&
                            (component as CustomNamedHolder)
                                    .selectable[customNamed!] !=
                                null)
                        ? (component as CustomNamedHolder)
                            .selectable[customNamed!]!
                        : null);
              },
              child: const Icon(
                Icons.add,
                size: 15,
                color: AppColors.theme,
              ),
            ),
            const SizedBox(
              width: 3,
            ),
          ],
          if ([1, 2, 3, 5].contains(component.type) &&
              component != ancestor &&
              !disableOperations) ...[
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                //Replacing component
                showSelectionDialog(context, (comp) {
                  componentOperationCubit.revertWork
                      .add(ReplaceOperation(component, comp), () {
                    replaceWith(component, comp);
                    componentCreationCubit.changedComponent();

                    componentOperationCubit.addedComponent(comp, ancestor);

                    componentSelectionCubit.changeComponentSelection(
                        ComponentSelectionModel.unique(comp),
                        root: ancestor);
                  }, (oldValue) {
                    final ReplaceOperation operation = oldValue;
                    replaceWith(operation.component2, operation.component1);
                    componentCreationCubit.changedComponent();

                    componentOperationCubit.addedComponent(
                        operation.component1, ancestor);

                    componentSelectionCubit.changeComponentSelection(
                        ComponentSelectionModel.unique(operation.component1),
                        root: ancestor);
                  });
                },
                    favouritesEnable: false,
                    possibleItems: getSameComponents(components, component));
              },
              child: const Icon(
                Icons.find_replace_outlined,
                size: 15,
                color: AppColors.theme,
              ),
            ),
            const SizedBox(
              width: 3,
            ),
          ],
          if (favourite)
            Icon(
              Icons.star,
              size: 20,
              color: Colors.yellow.shade600,
            ),
          if (!disableOperations &&
              menuEnable &&
              customNamed == null &&
              component !=
                  componentOperationCubit.flutterProject!.rootComponent!) ...[
            CustomPopupMenuButton(
              itemBuilder: (context) {
                final list = getTypeComponents(
                        components,
                        customNamed == null && component != ancestor
                            ? [2, 3]
                            : [])
                    .map((e) => 'wrap with $e')
                    .toList();
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

                if (!favourite) {
                  list.add('add to favourites');
                } else {
                  list.add('remove from favourites');
                }

                if (component.type != 5) {
                  list.add('create custom widget');
                }
                if (component != ancestor &&
                    customNamed == null &&
                    (component.type == 1 ||
                        (component.type == 2 &&
                            ((component.parent?.type == 4 &&
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
                        (component.type == 5))) {
                  list.add('remove');
                } else if (component.type == 5 && component == ancestor) {
                  list.add('delete');
                }
                if (component != ancestor &&
                        customNamed == null &&
                        component.type != 1 &&
                        component !=
                            componentOperationCubit.flutterProject!
                                .rootComponent! // &&   (component.type == 2 && compChildren >= 1)
                    ) {
                  list.add('remove tree');
                }
                return list
                    .map(
                      (item) => CustomPopupMenuItem<String>(
                        value: item,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item,
                            style: AppFontStyle.roboto(13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    )
                    .toList();
              },
              onSelected: (e) {
                if (e == 'add to favourites') {
                  componentOperationCubit.addToFavourites(component);
                } else if (e == 'remove from favourites') {
                  componentOperationCubit.removeFromFavourites(component);
                } else if (e == 'create custom widget') {
                  showCustomWidgetRename(context, 'Enter name of widget',
                      (value) {
                    componentOperationCubit.addCustomComponent(value,
                        root: component);
                    Get.back();
                  });
                } else if (e == 'delete') {
                  componentOperationCubit.deleteCustomComponent(
                      context, component as CustomComponent);
                } else if (e == 'remove') {
                  if (ancestor is CustomComponent) {
                    final parent = component.parent!;
                    (ancestor as CustomComponent).notifyChanged();
                    componentSelectionCubit.changeComponentSelection(
                        ComponentSelectionModel.unique(parent),
                        root: ancestor);
                    componentOperationCubit.removedComponent();
                    componentCreationCubit.changedComponent();
                  } else {
                    performReversibleOperation(() {
                      if (component.parent == null &&
                          componentParameter != null) {
                        componentOperationCubit
                            .removeRootComponentFromComponentParameter(
                                componentParameter!, component);
                        componentCreationCubit.changedComponent();
                      } else {
                        final parent = component.parent!;
                        componentOperationCubit.removeComponentAndRefresh(
                            context, component);
                        componentSelectionCubit.changeComponentSelection(
                            ComponentSelectionModel.unique(parent),
                            root: ancestor);
                        componentCreationCubit.changedComponent();
                      }
                    });
                    // componentOperationCubit.revertWork.add(
                    //     RemoveOperation(component, component.parent), () {
                    //
                    // }, (p0) {
                    //   final RemoveOperation operation = p0;
                    //   if (operation.parent != null) {
                    //     addOperation(operation.parent!, operation.component);
                    //     componentOperationCubit.addedComponent(
                    //         component, ancestor);
                    //     componentSelectionCubit.changeComponentSelection(
                    //         operation.component,
                    //         root: ancestor);
                    //     componentCreationCubit.changedComponent();
                    //   }
                    // });
                  }
                } else if (e == 'remove tree') {
                  performReversibleOperation(() {
                    if (component.parent == null &&
                        componentParameter != null) {
                      componentOperationCubit
                          .removeRootComponentFromComponentParameter(
                              componentParameter!, component,
                              removeAll: true);
                      componentCreationCubit.changedComponent();
                    } else {
                      final parent = component.parent!;
                      componentOperationCubit.removeAllComponent(component);
                      componentSelectionCubit.changeComponentSelection(
                          ComponentSelectionModel.unique(parent),
                          root: ancestor);
                      componentOperationCubit.removedComponent();
                      componentCreationCubit.changedComponent();
                    }
                  });
                } else if ((e as String).startsWith('wrap')) {
                  final compName = e.split(' ')[2];
                  final Component wrapperComp = componentList[compName]!();
                  performReversibleOperation(() {
                    wrapWithComponent(component, wrapperComp);
                    componentCreationCubit.changedComponent();

                    componentOperationCubit.addedComponent(
                        wrapperComp, ancestor);

                    componentSelectionCubit.changeComponentSelection(
                        ComponentSelectionModel.unique(wrapperComp),
                        root: ancestor);
                  });
                }
              },
              child: const Icon(
                Icons.more_vert,
                color: AppColors.theme,
                size: 15,
              ),
            ),
          ]
        ],
      ),
    );
  }

  void wrapWithComponent(
      final Component component, final Component wrapperComp) {
    if (component.parent == null && componentParameter != null) {
      final index = componentParameter!.components
          .indexWhere((element) => element == component);
      componentParameter!.components.removeAt(index);
      componentParameter!.components.insert(index, wrapperComp);
    } else {
      replaceChildOfParent(component, wrapperComp);
    }
    switch (wrapperComp.type) {
      case 2:
        //MultiHolder
        (wrapperComp as MultiHolder).addChild(component);
        break;
      case 3:
        (wrapperComp as Holder).updateChild(component);
        break;
      //Holder
    }
    if (ancestor is CustomComponent) {
      (ancestor as CustomComponent).notifyChanged();
    }
  }

  void performReversibleOperation(void Function() work) {
    final operation = Operation(
        CodeOperations.trim(componentOperationCubit
            .flutterProject!.rootComponent!
            .code(clean: false))!,
        componentSelectionCubit.currentSelected.treeSelection.first.id);
    componentOperationCubit.revertWork.add(operation, work, (p0) {
      final Operation operation = p0;
      componentOperationCubit.flutterProject!.rootComponent =
          Component.fromCode(
              operation.code, componentOperationCubit.flutterProject!);
      componentOperationCubit.emit(ComponentUpdatedState());
      componentOperationCubit.flutterProject!.rootComponent!.forEach((comp) {
        if (comp.name == 'Image.asset') {
          final imageData = (comp.parameters[0].value as ImageData);
          if (componentOperationCubit.byteCache
              .containsKey(imageData.imageName)) {
            imageData.bytes =
                componentOperationCubit.byteCache[imageData.imageName];
          }
        }
        if (comp.id == operation.selectedId) {
          componentSelectionCubit.changeComponentSelection(
              ComponentSelectionModel.unique(comp),
              root: ancestor);
        }
      });
      componentCreationCubit.changedComponent();
    });
  }

  void replaceWith(Component oldComponent, Component comp) {
    for (final source in oldComponent.parameters) {
      for (final dest in comp.parameters) {
        if (source.runtimeType == dest.runtimeType &&
            dest.displayName == source.displayName) {
          copyValueSourceToDest(source, dest);
        }
      }
    }
    switch (comp.type) {
      case 2:
        //MultiHolder
        (comp as MultiHolder).children = (oldComponent as MultiHolder).children;
        break;
      case 3:
        //Holder
        (comp as Holder).child = (oldComponent as Holder).child;
        break;
    }
    replaceChildOfParent(oldComponent, comp);
    if (ancestor is CustomComponent) {
      if (component == ancestor) {
        (ancestor as CustomComponent).root = comp;
      }
      (ancestor as CustomComponent).notifyChanged();
    }
  }

  List<String> getSameComponents(
      Map<String, Component> components, Component component) {
    final List<String> sameComponents = [];
    for (final key in components.keys) {
      if (components[key].runtimeType != component.runtimeType &&
          (components[key]!.childCount == component.childCount)) {
        sameComponents.add(key);
      }
    }
    return sameComponents;
  }

  List<String> getTypeComponents(
      Map<String, Component> components, List<int> types) {
    final List<String> sameComponents = [];
    for (final key in components.keys) {
      if (types.contains(components[key]!.type)) {
        sameComponents.add(key);
      }
    }
    return sameComponents;
  }

  void showSelectionDialog(
      BuildContext context, void Function(Component) onSelection,
      {List<String>? possibleItems, bool favouritesEnable = true}) {
    Get.dialog(
      GestureDetector(
        onTap: () {
          Get.back();
        },
        child: ComponentSelectionDialog(
          possibleItems: possibleItems,
          onSelection: onSelection,
          shouldShowFavourites: favouritesEnable,
          componentOperationCubit: componentOperationCubit,
        ),
      ),
    );
  }

  void copyValueSourceToDest(Parameter source, Parameter dest) {
    if (source is SimpleParameter) {
      (dest as SimpleParameter).val = source.val;
    } else if (source is ChoiceValueParameter) {
      (dest as ChoiceValueParameter).val = source.val;
    } else if (source is ChoiceParameter && source.val != null) {
      final sourceSelectionName = source.val?.displayName;
      for (final option in (dest as ChoiceParameter).options) {
        if (option.displayName == sourceSelectionName) {
          dest.val = option;
          copyValueSourceToDest(source.val!, dest.val!);
          break;
        }
      }
    } else if (source is ComplexParameter) {
      for (final param in source.params) {
        for (final param2 in (dest as ComplexParameter).params) {
          if ((param.displayName == param2.displayName) &&
              param.runtimeType == param2.runtimeType) {
            copyValueSourceToDest(param, param2);
          }
        }
      }
    }
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
        (component.parent as CustomComponent).root = comp;
        comp.setParent(component.parent);
        break;
    }
  }

  void showCustomWidgetRename(
      BuildContext context, String title, Function(String) onChange) {
    CustomDialog.show(
      context,
      Container(
        padding: const EdgeInsets.all(15),
        color: Colors.white,
        width: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 40,
              child: AppTextField(
                value: component.name,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            AppButton(
              height: 45,
              title: 'ok',
              onPressed: () {
                if (AppTextField.changedValue.length > 1 &&
                    !AppTextField.changedValue.contains(' ') &&
                    !AppTextField.changedValue.contains('.')) {
                  onChange.call(AppTextField.changedValue);
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

class ComponentTile extends StatelessWidget {
  final Component component;
  final Component ancestor;
  final ComponentSelectionCubit componentSelectionCubit;

  const ComponentTile(
      {Key? key,
      required this.component,
      required this.ancestor,
      required this.componentSelectionCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Draggable(
      data: component,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          // key: GlobalObjectKey(component.uniqueId),
          height: 30,
          width: 200,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xffd3d3d3), width: 2),
          ),
          child: Text(
            component.name,
            style: AppFontStyle.roboto(13,
                color: Colors.black, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      child: BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
        bloc: componentSelectionCubit,
        builder: (context, state) {
          late final bool selected;
          final selectedComponent = componentSelectionCubit.currentSelected;
          if (component is CustomComponent) {
            selected = (component as CustomComponent).cloneOf ==
                    componentSelectionCubit.currentSelectedRoot ||
                (componentSelectionCubit.currentSelected.treeSelection
                    .contains(component));
          } else {
            selected = (selectedComponent.treeSelection.contains(component));
          }

          return InkWell(
            borderRadius: BorderRadius.circular(10),
            hoverColor: const Color(0xffADD8FF),
            onTap: () {
              componentSelectionCubit.changeComponentSelection(
                  ComponentSelectionModel.unique(component),
                  root: ancestor,
                  scroll: false);
            },
            child: Container(
              key: GlobalObjectKey(component.uniqueId),
              height: 30,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              margin:
                  const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: Colors.blueAccent, width: 2)
                    : Border.all(color: const Color(0xffd3d3d3), width: 2),
              ),
              child: Text(
                component.name,
                style: AppFontStyle.roboto(13,
                    color: Colors.black, fontWeight: FontWeight.w500),
              ),
            ),
          );
        },
      ),
    );
  }
}
