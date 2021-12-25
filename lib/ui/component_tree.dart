import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/app_button.dart';
import 'package:flutter_builder/common/app_text_field.dart';
import 'package:flutter_builder/common/custom_animated_dialog.dart';
import 'package:flutter_builder/common/custom_popup_menu_button.dart';
import 'package:flutter_builder/models/component_model.dart';
import 'package:flutter_builder/constant/app_colors.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/models/parameter_model.dart';
import 'package:flutter_builder/ui/selection_dialog.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../component_list.dart';

class ComponentTree extends StatefulWidget {
  const ComponentTree({Key? key}) : super(key: key);

  @override
  _ComponentTreeState createState() => _ComponentTreeState();
}

class _ComponentTreeState extends State<ComponentTree> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
      builder: (context, state) {
        return BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
          builder: (context, state) {
            return Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.all(10),
                      child: getSublist(
                          Provider.of<ComponentOperationCubit>(context,
                                  listen: false)
                              .mainExecution
                              .rootComponent!,
                          Provider.of<ComponentOperationCubit>(context,
                                  listen: false)
                              .mainExecution
                              .rootComponent!),
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
                              //ADD Custom Widgtes
                              showCustomWidgetRename(
                                  context, 'Enter widget name', (name) {
                                Provider.of<ComponentOperationCubit>(context,
                                        listen: false)
                                    .addCustomComponent(name);
                                Get.back();
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
                    for (final CustomComponent comp
                        in Provider.of<ComponentOperationCubit>(context,
                                listen: false)
                            .mainExecution
                            .customComponents) ...[
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
                              component: comp, ancestor: comp)
                        ],
                      ),
                      if (comp.root != null)
                        Container(
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.all(10),
                          child: getSublist(comp.root!, comp),
                        ),
                    ],
                    const SizedBox(
                      height: 100,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showCustomWidgetRename(
      BuildContext context, String title, Function(String) onSubmit) {
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
        ));
  }

  Widget getSublist(Component component, Component ancestor) {
    if (component is MultiHolder) {
      return Column(
        children: [
          Row(
            children: [
              ComponentTile(
                component: component,
                ancestor: ancestor,
              ),
              const Spacer(),
              ComponentModificationMenu(
                component: component,
                ancestor: ancestor,
              )
            ],
          ),
          if (component.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 5, top: 0),
              child: SizedBox(
                height: getCalculatedHeight(component),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  restorationId: component.toString(),
                  onReorder: (int oldIndex, int newIndex) {
                    print('INDEX $oldIndex $newIndex');
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    // final old = component.children[oldIndex];
                    // component.children[oldIndex] = component.children[newIndex];
                    // component.children[newIndex] = old;
                    final old = component.children.removeAt(oldIndex);
                    component.children.insert(newIndex, old);
                    if (ancestor is CustomComponent) {
                      ancestor.notifyChanged();
                    }
                    Provider.of<ComponentOperationCubit>(context, listen: false)
                        .arrangeComponent(context);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 30),
                      key: GlobalObjectKey(
                          '${component.children[index].hashCode} reorder'),
                      child: getSublist(component.children[index], ancestor),
                    );
                  },
                  itemCount: component.children.length,
                ),
              ),
            ),
        ],
      );
    } else if (component is Holder) {
      return Column(
        children: [
          Row(
            children: [
              ComponentTile(component: component, ancestor: ancestor),
              const Spacer(),
              ComponentModificationMenu(
                  component: component, ancestor: ancestor)
            ],
          ),
          if (component.child != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 5, top: 0),
              child: getSublist(component.child!, ancestor),
            ),
          ]
        ],
      );
    } else if (component is CustomNamedHolder) {
      return Column(
        children: [
          Row(
            children: [
              ComponentTile(component: component, ancestor: ancestor),
              const Spacer(),
              ComponentModificationMenu(
                  component: component, customNamed: null, ancestor: ancestor),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 0),
            child: Column(children: [
              for (final child in component.childMap.keys) ...[
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
                            ancestor: ancestor)
                      ],
                    ),
                    if (component.childMap[child] != null)
                      getSublist(component.childMap[child]!, ancestor),
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
              ),
              const Spacer(),
              ComponentModificationMenu(
                  component: component, ancestor: ancestor)
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        ComponentTile(component: component, ancestor: ancestor),
        const Spacer(),
        ComponentModificationMenu(component: component, ancestor: ancestor)
      ],
    );
  }

  double getCalculatedHeight(Component component) {
    switch (component.type) {
      case 1:
      case 5:
        return 35;
      case 2:
        double height = 35;
        for (Component comp in (component as MultiHolder).children) {
          height += getCalculatedHeight(comp);
        }
        return height;
      case 3:
        return (component as Holder).child != null
            ? 35 + getCalculatedHeight(component.child!)
            : 35;
      case 4:
        double height = 0;
        for (Component? comp
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

class ComponentModificationMenu extends StatelessWidget {
  final Component component;
  final Component ancestor;

  final String? customNamed;

  const ComponentModificationMenu(
      {Key? key,
      this.customNamed,
      required this.component,
      required this.ancestor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                for (Component comp in (component as CustomComponent).objects) {
                  comp.name = component.name;
                }
                Get.back();
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .emit(ComponentUpdatedState());
              });
            },
            child: const Icon(
              Icons.edit,
              size: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
        ],
        if (component is MultiHolder ||
            (component is Holder && (component as Holder).child == null) ||
            (component.type == 5 &&
                component == ancestor &&
                (component as CustomComponent).root == null) ||
            (customNamed != null &&
                (component as CustomNamedHolder).childMap[customNamed!] ==
                    null)) ...[
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              //ADDING COMPONENT
              showSelectionDialog(context, (comp) {
                if (customNamed != null) {
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
                if (ancestor is CustomComponent) {
                  if (component == ancestor) {
                    (ancestor as CustomComponent).root = comp;
                  }
                  (ancestor as CustomComponent).notifyChanged();
                }
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .addedComponent(context, comp, ancestor);
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
              radius: 10,
              backgroundColor: AppColors.theme,
              child: Icon(
                Icons.add,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(
            width: 5,
          ),
        ],
        if ([1, 2, 3, 5].contains(component.type) && component != ancestor) ...[
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
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .addedComponent(context, comp, ancestor);
              }, possibleItems: getSameComponents(components, component));
            },
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.purple,
              child: Icon(
                Icons.find_replace_outlined,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(
            width: 5,
          ),
        ],
        if (customNamed == null &&
            component !=
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .mainExecution
                    .rootComponent!) ...[
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
                      (component.type == 4
                      // &&(component as CustomNamedHolder).childrenMap.isEmpty
                      // &&(component as CustomNamedHolder).childMap.isEmpty
                      ) ||
                      (component.type == 5))) {
                list.add('remove');
              } else if (component.type == 5 && component == ancestor) {
                list.add('delete');
              }
              if (component.type != 5) {
                list.add('create custom widget');
              }
              if (component != ancestor &&
                  customNamed == null &&
                  component.type != 1 &&
                  component !=
                      Provider.of<ComponentOperationCubit>(context,
                              listen: false)
                          .mainExecution
                          .rootComponent! &&
                  (component.type == 2 && compChildren >= 1)) {
                list.add('remove tree');
              }
              return list
                  .map(
                    (e) => CustomPopupMenuItem(
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
              if (e == 'create custom widget') {
                showCustomWidgetRename(context, 'Enter name of widget',
                    (value) {
                  Provider.of<ComponentOperationCubit>(context, listen: false)
                      .addCustomComponent(value, root: component);
                  Get.back();
                });
              } else if (e == 'delete') {
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .deleteCustomComponent(component as CustomComponent);
              } else if (e == 'remove') {
                final parent = component.parent!;
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .removeComponent(component);
                if (ancestor is CustomComponent) {
                  (ancestor as CustomComponent).notifyChanged();
                }
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .removedComponent(context, parent, ancestor);
              } else if (e == 'remove tree') {
                final parent = component.parent!;
                if (component.type == 2) {
                  (component as MultiHolder).children.clear();
                } else if (component.type == 3) {
                  (component as CustomNamedHolder).childMap.clear();
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
                    (parent as CustomNamedHolder).updateChild(component, null);
                    break;
                }
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .removedComponent(context, parent, ancestor);
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
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .addedComponent(context, wrapperComp, ancestor);
              }
            },
            child: const Icon(
              Icons.more_vert,
              color: Colors.black,
              size: 24,
            ),
          ),
        ]
      ],
    );
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
      {List<String>? possibleItems}) {
    Get.dialog(
      GestureDetector(
        onTap: () {
          Get.back();
        },
        child: BlocProvider<ComponentOperationCubit>(
          create: (context2) =>
              Provider.of<ComponentOperationCubit>(context, listen: false),
          child: SelectionDialog(
            possibleItems: possibleItems,
            onSelection: onSelection,
          ),
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

  const ComponentTile(
      {Key? key, required this.component, required this.ancestor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    late final bool selected;
    final selectedComponent =
        BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
            .currentSelected;
    // final comp = rootComp.findSameLevelComponent(
    //     customComponent,
    //     (BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
    //         .currentSelectedRoot as CustomComponent),
    //     BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
    //         .currentSelected);
    if (selectedComponent is CustomComponent) {
      selected = selectedComponent.objects.contains(component);
    }
    // else if(BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
    //         .currentSelectedRoot is CustomComponent){
    //   selected =
    // }
    else {
      selected = (selectedComponent == component);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
            .changeComponentSelection(component, root: ancestor);
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: selected
              ? const BorderSide(color: Colors.blueAccent, width: 2)
              : const BorderSide(),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            component.name,
            style: AppFontStyle.roboto(13,
                color: Colors.black, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
