import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../common/app_button.dart';
import '../common/app_text_field.dart';
import '../common/custom_animated_dialog.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/logger.dart';
import '../models/component_model.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../models/parameter_model.dart';
import 'component_selection_dialog.dart';
import 'package:get/get.dart';

import '../component_list.dart';

class ComponentTree extends StatefulWidget {
  const ComponentTree({Key? key}) : super(key: key);

  @override
  _ComponentTreeState createState() => _ComponentTreeState();
}

class _ComponentTreeState extends State<ComponentTree> {
  late final ComponentOperationCubit _componentOperationCubit;
  late final ComponentCreationCubit _componentCreationCubit;
  late final ComponentSelectionCubit _componentSelectionCubit;

  @override
  void initState() {
    super.initState();
    _componentOperationCubit =
        BlocProvider.of<ComponentOperationCubit>(context, listen: false);
    _componentCreationCubit =
        BlocProvider.of<ComponentCreationCubit>(context, listen: false);
    _componentSelectionCubit =
        BlocProvider.of<ComponentSelectionCubit>(context, listen: false);
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
              Text(
                BlocProvider
                    .of<ComponentOperationCubit>(context, listen: false)
                    .flutterProject!
                    .name,
                style: AppFontStyle.roboto(16, fontWeight: FontWeight.bold),
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
                  return const Icon(
                    Icons.cloud_done,
                    color: Colors.blueAccent,
                    size: 20,
                  );
                },
              )
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
            bloc: _componentOperationCubit,
            buildWhen: (state1, state2) {
              debugPrint(
                  '=== ComponentOperationCubit == buildWhen ${state1
                      .runtimeType} to ${state2.runtimeType}');
              if (state2 is ComponentUpdatedState) {
                return true;
              }
              return false;
            },
            builder: (context, state) {
              debugPrint(
                  '=== ComponentOperationCubit == state ${state.runtimeType}');
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.all(6),
                      child: SublistWidget(
                          component: _componentOperationCubit
                              .flutterProject!.rootComponent!,
                          ancestor: _componentOperationCubit
                              .flutterProject!.rootComponent!,
                          componentSelectionCubit: _componentSelectionCubit,
                          componentOperationCubit: _componentOperationCubit,
                          componentCreationCubit: _componentCreationCubit),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Custom Widgets',
                            style: AppFontStyle.roboto(14,
                                color: const Color(0xff494949),
                                fontWeight: FontWeight.bold),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              //ADD Custom Widgets
                              showCustomWidgetRename(
                                  context, 'Enter widget name', (name) {
                                Get.back();

                                BlocProvider.of<ComponentOperationCubit>(
                                    context,
                                    listen: false)
                                    .addCustomComponent(name);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.theme,
                              child: Icon(
                                Icons.add,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final CustomComponent comp in _componentOperationCubit
                        .flutterProject!.customComponents) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.theme, width: 1.5),
                                borderRadius: BorderRadius.circular(4)),
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Text(
                              comp.name,
                              style: AppFontStyle.roboto(15,
                                  color: AppColors.theme,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          ComponentModificationMenu(
                            component: comp,
                            ancestor: comp,
                            componentOperationCubit: _componentOperationCubit,
                            componentCreationCubit: _componentCreationCubit,
                            componentSelectionCubit: _componentSelectionCubit,
                          )
                        ],
                      ),
                      if (comp.root != null)
                        Container(
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.all(10),
                          child: SublistWidget(
                              component: comp.root!,
                              ancestor: comp,
                              componentSelectionCubit: _componentSelectionCubit,
                              componentOperationCubit: _componentOperationCubit,
                              componentCreationCubit: _componentCreationCubit),
                        ),
                    ],
                    const SizedBox(
                      height: 100,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void showCustomWidgetRename(BuildContext context, String title,
      Function(String) onSubmit) {
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
  final ComponentOperationCubit componentOperationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final ComponentCreationCubit componentCreationCubit;

  const SingleChildWidget({Key? key,
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

  const ComponentParameterWidget({Key? key,
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
        for (final child
        in component.componentParameters) ...[
          Column(
            children: [
              Row(
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
                      componentParameter: child,
                      componentSelectionCubit: componentSelectionCubit,
                      componentOperationCubit: componentOperationCubit,
                      componentCreationCubit: componentCreationCubit),
                ],
              ),
              MultipleChildWidget(component: component,
                  ancestor: ancestor,
                  children: child.components,
                  componentOperationCubit: componentOperationCubit,
                  componentSelectionCubit: componentSelectionCubit,
                  componentCreationCubit: componentCreationCubit
              ),
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
  final ComponentOperationCubit componentOperationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final ComponentCreationCubit componentCreationCubit;

  const MultipleChildWidget({Key? key,
    required this.component,
    required this.ancestor,
    required this.children,
    required this.componentOperationCubit,
    required this.componentSelectionCubit,
    required this.componentCreationCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 0),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(width: 0.4, color: Colors.grey),
          ),
        ),
        height: getCalculatedHeight(component) - 35,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          restorationId: component.toString(),
          onReorder: (int oldIndex, int newIndex) {
            logger('INDEX $oldIndex $newIndex');
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final old = children.removeAt(oldIndex);
            children.insert(newIndex, old);
            if (ancestor is CustomComponent) {
              (ancestor as CustomComponent).notifyChanged();
            }
            componentOperationCubit.arrangeComponent(context);
          },
          itemBuilder: (BuildContext _, int index) {
            return Padding(
              key: GlobalObjectKey(
                  '${children[index].id} ${children[index].parent
                      ?.id} reorder'),
              padding: const EdgeInsets.only(right: 20),
              child: SublistWidget(
                component: children[index],
                ancestor: ancestor,
                componentOperationCubit: componentOperationCubit,
                componentCreationCubit: componentCreationCubit,
                componentSelectionCubit: componentSelectionCubit,
              ),
            );
          },
          itemCount: children.length,
        ),
      ),
    );
  }

  double getCalculatedHeight(final Component component) {
    switch (component.type) {
      case 1:
        double height = 35;
        for (final compParam in component.componentParameters) {
          height += 20;
          for(final comp in compParam.components) {
            height+=getCalculatedHeight(comp);
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
          height += 35;
          for(final comp in compParam.components) {
            height+=getCalculatedHeight(comp);
          }
        }

        return height;
      case 3:
        double height=35;
        for (final compParam in component.componentParameters) {
          height += 35;
          for(final comp in compParam.components) {
            height+=getCalculatedHeight(comp);
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
        return height;
    }
    return 0;
  }
}

class SublistWidget extends StatelessWidget {
  final Component component, ancestor;
  final ComponentSelectionCubit componentSelectionCubit;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentCreationCubit componentCreationCubit;

  const SublistWidget({Key? key,
    required this.component,
    required this.ancestor,
    required this.componentSelectionCubit,
    required this.componentOperationCubit,
    required this.componentCreationCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (component is MultiHolder) {
      return Column(
        children: [
          Row(
            children: [
              ComponentTile(
                component: component,
                ancestor: ancestor,
                componentSelectionCubit: componentSelectionCubit,
              ),
              const Spacer(),
              ComponentModificationMenu(
                component: component,
                ancestor: ancestor,
                componentOperationCubit: componentOperationCubit,
                componentCreationCubit: componentCreationCubit,
                componentSelectionCubit: componentSelectionCubit,
              )
            ],
          ),
          if ((component as MultiHolder).children.isNotEmpty)
            MultipleChildWidget(
                component: component,
                ancestor: ancestor,
                children: (component as MultiHolder).children,
                componentOperationCubit: componentOperationCubit,
                componentSelectionCubit: componentSelectionCubit,
                componentCreationCubit: componentCreationCubit),
          if (component.componentParameters.isNotEmpty)
            ComponentParameterWidget(component: component, ancestor: ancestor, componentOperationCubit: componentOperationCubit, componentSelectionCubit: componentSelectionCubit, componentCreationCubit: componentCreationCubit)
        ],
      );
    } else if (component is Holder) {
      return Column(
        children: [
          Row(
            children: [
              ComponentTile(
                component: component,
                ancestor: ancestor,
                componentSelectionCubit: componentSelectionCubit,
              ),
              const Spacer(),
              ComponentModificationMenu(
                component: component,
                ancestor: ancestor,
                componentOperationCubit: componentOperationCubit,
                componentCreationCubit: componentCreationCubit,
                componentSelectionCubit: componentSelectionCubit,
              )
            ],
          ),
          if ((component as Holder).child != null) ...[
            SingleChildWidget(
                component: component,
                ancestor: ancestor,
                child: (component as Holder).child!,
                componentOperationCubit: componentOperationCubit,
                componentSelectionCubit: componentSelectionCubit,
                componentCreationCubit: componentCreationCubit),
          ]
        ],
      );
    } else if (component is CustomNamedHolder) {
      return Column(
        children: [
          Row(
            children: [
              ComponentTile(
                component: component,
                ancestor: ancestor,
                componentSelectionCubit: componentSelectionCubit,
              ),
              const Spacer(),
              ComponentModificationMenu(
                component: component,
                customNamed: null,
                ancestor: ancestor,
                componentOperationCubit: componentOperationCubit,
                componentCreationCubit: componentCreationCubit,
                componentSelectionCubit: componentSelectionCubit,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 0),
            child: Column(children: [
              for (final child
              in (component as CustomNamedHolder).childMap.keys) ...[
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
                            component: component,
                            customNamed: child,
                            ancestor: ancestor,
                            componentSelectionCubit: componentSelectionCubit,
                            componentOperationCubit: componentOperationCubit,
                            componentCreationCubit: componentCreationCubit),
                      ],
                    ),
                    if ((component as CustomNamedHolder).childMap[child] !=
                        null)
                      SublistWidget(
                        ancestor: ancestor,
                        component:
                        (component as CustomNamedHolder).childMap[child]!,
                        componentSelectionCubit: componentSelectionCubit,
                        componentOperationCubit: componentOperationCubit,
                        componentCreationCubit: componentCreationCubit,
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
    } else if (component is CustomComponent) {
      return Column(
        children: [
          Row(
            children: [
              ComponentTile(
                component: component,
                ancestor: ancestor,
                componentSelectionCubit: componentSelectionCubit,
              ),
              const Spacer(),
              ComponentModificationMenu(
                component: component,
                ancestor: ancestor,
                componentOperationCubit: componentOperationCubit,
                componentCreationCubit: componentCreationCubit,
                componentSelectionCubit: componentSelectionCubit,
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
              component: component,
              ancestor: ancestor,
              componentSelectionCubit: componentSelectionCubit,
            ),
            const Spacer(),
            ComponentModificationMenu(
              component: component,
              ancestor: ancestor,
              componentOperationCubit: componentOperationCubit,
              componentCreationCubit: componentCreationCubit,
              componentSelectionCubit: componentSelectionCubit,
            )
          ],
        ),
        if (component.componentParameters.isNotEmpty)
          ComponentParameterWidget(component: component, ancestor: ancestor, componentOperationCubit: componentOperationCubit, componentSelectionCubit: componentSelectionCubit, componentCreationCubit: componentCreationCubit)

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

  const ComponentModificationMenu({Key? key,
    this.customNamed,
    this.componentParameter,
    required this.component,
    required this.ancestor,
    required this.componentOperationCubit,
    required this.componentCreationCubit,
    required this.componentSelectionCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favourite = componentOperationCubit.isFavourite(component);
    final components =
    componentList.map((key, value) => MapEntry(key, value()));
    return Row(
      children: [
        if (component.type == 5 && ancestor == component) ...[
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              //rename
              showCustomWidgetRename(context, 'Rename ${component.name}',
                      (value) {
                    component.name = AppTextField.changedValue;
                    for (Component comp in (component as CustomComponent)
                        .objects) {
                      comp.name = component.name;
                    }
                    Get.back();
                    componentOperationCubit.emit(ComponentUpdatedState());
                  });
            },
            child: const Icon(
              Icons.edit,
              size: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(
            width: 3,
          ),
        ],
        if (componentOperationCubit.shouldAddingEnable(
            component,componentParameter, ancestor, customNamed)) ...[
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              //ADDING COMPONENT
              showSelectionDialog(context, (comp) {
                if(componentParameter!=null){
                  componentParameter!.addComponent(comp);
                }
                else if (customNamed != null) {
                  (component as CustomNamedHolder)
                      .updateChildWithKey(customNamed!, comp);
                } else {
                  if (component is Holder) {
                    (component as Holder).updateChild(comp);
                  } else if (component is MultiHolder) {
                    (component as MultiHolder).addChild(comp);
                  }
                }
                comp.setParent(component);
                if (comp is CustomComponent) {
                  comp.root?.setParent(component);
                }
                if (ancestor is CustomComponent) {
                  if (component == ancestor) {
                    (ancestor as CustomComponent).root = comp;
                  }
                  (ancestor as CustomComponent).notifyChanged();
                }
                componentCreationCubit.changedComponent();

                componentOperationCubit.addedComponent(comp, ancestor);
                componentSelectionCubit.changeComponentSelection(component,
                    root: ancestor);
              },
                  possibleItems: (customNamed != null &&
                      (component as CustomNamedHolder)
                          .selectable[customNamed!] !=
                          null)
                      ? (component as CustomNamedHolder)
                      .selectable[customNamed!]!
                      : null);
            },
            child: const CircleAvatar(
              radius: 7,
              backgroundColor: AppColors.theme,
              child: Icon(
                Icons.add,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(
            width: 3,
          ),
        ],
        if ([1, 2, 3, 5].contains(component.type) && component != ancestor&&componentParameter==null) ...[
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              //Replacing component
              showSelectionDialog(context, (comp) {
                for (final source in component.parameters) {
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
                    (comp as MultiHolder).children =
                        (component as MultiHolder).children;
                    break;
                  case 3:
                  //Holder
                    (comp as Holder).child = (component as Holder).child;
                    break;
                }
                replaceChildOfParent(comp);
                if (ancestor is CustomComponent) {
                  if (component == ancestor) {
                    (ancestor as CustomComponent).root = comp;
                  }
                  (ancestor as CustomComponent).notifyChanged();
                }
                componentCreationCubit.changedComponent();

                componentOperationCubit.addedComponent(comp, ancestor);

                componentSelectionCubit.changeComponentSelection(component,
                    root: ancestor);
              }, possibleItems: getSameComponents(components, component));
            },
            child: const CircleAvatar(
              radius: 7,
              backgroundColor: Colors.purple,
              child: Icon(
                Icons.find_replace_outlined,
                size: 10,
                color: Colors.white,
              ),
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
        if (customNamed == null &&
            component !=
                componentOperationCubit.flutterProject!.rootComponent!) ...[
          CustomPopupMenuButton(
            itemBuilder: (context2) {
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
                  compChildren = ((component as Holder).child == null ? 0 : 1);
                  break;
                default:
                  compChildren = 0;
              }

              if (component != ancestor &&
                  customNamed == null &&
                  component.parent != null &&
                  (component.type == 1 ||
                      (component.type == 2 &&
                          ((component.parent?.type == 4 && compChildren <= 1) ||
                              component.parent?.type == 2 ||
                              ((component.parent?.type == 3 ||
                                  component.parent?.type == 5) &&
                                  compChildren < 2))) ||
                      (component.type == 3 &&
                          ([2, 3, 4, 5].contains(component.parent?.type))) ||
                      (component.type == 4) ||
                      (component.type == 5))) {
                list.add('remove');
              } else if (component.type == 5 && component == ancestor) {
                list.add('delete');
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
                  component.type != 1 &&
                  component !=
                      componentOperationCubit.flutterProject!
                          .rootComponent! // &&   (component.type == 2 && compChildren >= 1)
              ) {
                list.add('remove tree');
              }
              return list
                  .map(
                    (e) =>
                    CustomPopupMenuItem(
                      value: e,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          e,
                          style: AppFontStyle.roboto(14,
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
                final parent = component.parent!;
                if (ancestor is CustomComponent) {
                  (ancestor as CustomComponent).notifyChanged();
                  componentSelectionCubit.changeComponentSelection(parent,
                      root: ancestor);
                  componentOperationCubit.removedComponent();
                  componentCreationCubit.changedComponent();
                } else {
                  componentSelectionCubit.changeComponentSelection(parent,
                      root: ancestor);
                  componentOperationCubit.removeComponent(context, component);
                  componentCreationCubit.changedComponent();
                }
              } else if (e == 'remove tree') {
                final parent = component.parent!;
                componentSelectionCubit.changeComponentSelection(parent,
                    root: ancestor);
                if (component.type == 2) {
                  (component as MultiHolder).children.clear();
                } else if (component.type == 4) {
                  (component as CustomNamedHolder).childMap.clear();
                  (component as CustomNamedHolder).childrenMap.clear();
                }
                switch (parent.type) {
                  case 2:
                    (parent as MultiHolder).removeChild(component);
                    break;
                  case 3:
                    (parent as Holder).updateChild(null);
                    break;
                  case 4:
                    (parent as CustomNamedHolder).replaceChild(component, null);
                    break;
                  case 5:
                    (parent as CustomComponent).updateRoot(component);
                    break;
                }
                componentSelectionCubit.changeComponentSelection(parent,
                    root: ancestor);
                componentOperationCubit.removedComponent();
                componentCreationCubit.changedComponent();
              } else if ((e as String).startsWith('wrap')) {
                final compName = e.split(' ')[2];
                final Component wrapperComp = componentList[compName]!();
                replaceChildOfParent(wrapperComp);

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
                componentCreationCubit.changedComponent();

                componentOperationCubit.addedComponent(wrapperComp, ancestor);

                componentSelectionCubit.changeComponentSelection(wrapperComp,
                    root: ancestor);
              }
            },
            child: const Icon(
              Icons.more_vert,
              color: Colors.black,
              size: 20,
            ),
          ),
        ]
      ],
    );
  }

  List<String> getSameComponents(Map<String, Component> components,
      Component component) {
    final List<String> sameComponents = [];
    for (final key in components.keys) {
      if (components[key].runtimeType != component.runtimeType &&
          (components[key]!.childCount == component.childCount)) {
        sameComponents.add(key);
      }
    }
    return sameComponents;
  }

  List<String> getTypeComponents(Map<String, Component> components,
      List<int> types) {
    final List<String> sameComponents = [];
    for (final key in components.keys) {
      if (types.contains(components[key]!.type)) {
        sameComponents.add(key);
      }
    }
    return sameComponents;
  }

  void showSelectionDialog(BuildContext context,
      void Function(Component) onSelection,
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

  void replaceChildOfParent(Component comp) {
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

  void showCustomWidgetRename(BuildContext context, String title,
      Function(String) onChange) {
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

  const ComponentTile({Key? key,
    required this.component,
    required this.ancestor,
    required this.componentSelectionCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
      bloc: componentSelectionCubit,
      builder: (context, state) {
        late final bool selected;
        final selectedComponent = componentSelectionCubit.currentSelected;
        if (component is CustomComponent) {
          selected = (component as CustomComponent).cloneOf ==
              componentSelectionCubit.currentSelectedRoot ||
              (component == componentSelectionCubit.currentSelected);
        } else {
          selected = (selectedComponent == component);
        }

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0xffADD8FF),
          onTap: () {
            componentSelectionCubit.changeComponentSelection(component,
                root: ancestor);
          },
          child: Container(
            height: 30,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2.5),
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
    );
  }
}
