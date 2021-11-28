import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/custom_popup_menu_button.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/ui/component_selection.dart';
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
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(10),
                child: getSublist(
                    Provider.of<ComponentOperationCubit>(context, listen: false)
                        .rootComponent),
              ),
            );
          },
        );
      },
    );
  }

  Widget getSublist(Component component) {
    if (component is MultiHolder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  Provider.of<ComponentSelectionCubit>(context, listen: false)
                      .changeComponentSelection(component);
                },
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      component.name,
                      style: AppFontStyle.roboto(14,
                          color: Provider.of<ComponentSelectionCubit>(context,
                                          listen: false)
                                      .currentSelected ==
                                  component
                              ? Colors.blue
                              : Colors.black,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ComponentModificationMenu(component: component)
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 5),
            child: Column(
              children: [
                for (final comp in component.children) getSublist(comp)
              ],
            ),
          ),
        ],
      );
    } else if (component is Holder) {
      return Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  Provider.of<ComponentSelectionCubit>(context, listen: false)
                      .changeComponentSelection(component);
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      component.name,
                      style: AppFontStyle.roboto(14,
                          color: Provider.of<ComponentSelectionCubit>(context,
                                          listen: false)
                                      .currentSelected ==
                                  component
                              ? Colors.blue
                              : Colors.black,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ComponentModificationMenu(component: component)
            ],
          ),
          if (component.child != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 5),
              child: getSublist(component.child!),
            ),
          ]
        ],
      );
    } else if (component is CustomNamedHolder) {
      return Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  Provider.of<ComponentSelectionCubit>(context, listen: false)
                      .changeComponentSelection(component);
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      component.name,
                      style: AppFontStyle.roboto(14,
                          color: Provider.of<ComponentSelectionCubit>(context,
                                          listen: false)
                                      .currentSelected ==
                                  component
                              ? Colors.blue
                              : Colors.black,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 5),
            child: Column(children: [
              for (final child in component.children.keys) ...[
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          child,
                          style: AppFontStyle.roboto(12, color: Colors.grey),
                        ),
                        const Spacer(),
                        ComponentModificationMenu(component: component,customNamed: child,)
                      ],
                    ),
                    if (component.children[child] != null)
                      getSublist(component.children[child]!),
                  ],
                ),
                const SizedBox(
                  height: 10,
                )
              ]
            ]),
          ),
        ],
      );
    }
    return Column(
      children: [
        InkWell(
          onTap: () {
            Provider.of<ComponentSelectionCubit>(context, listen: false)
                .changeComponentSelection(component);
          },
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Text(
                component.name,
                style: AppFontStyle.roboto(14,
                    color: Provider.of<ComponentSelectionCubit>(context,
                                    listen: false)
                                .currentSelected ==
                            component
                        ? Colors.blue
                        : Colors.black,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ComponentModificationMenu extends StatelessWidget {
  static const operations = ['add', 'remove', 'replace', 'wrap with'];
  final Component component;

  final String? customNamed;
  const ComponentModificationMenu({Key? key, this.customNamed,required this.component})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenuButton(
        itemBuilder: (context) {
          return operations
              .map(
                (e) => CustomPopupMenuItem(
                  value: e,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      e,
                      style:
                          AppFontStyle.roboto(18, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              )
              .toList();
        },
        onSelected: (e) {
          switch (e) {
            case 'add':
              showSelectionDialog((comp) {
                if(customNamed!=null){
                  (component as CustomNamedHolder).updateChild(customNamed!, comp);
                }
                else {
                  if (component is Holder) {
                    (component as Holder).updateChild(comp);
                  } else if (component is MultiHolder) {
                    (component as MultiHolder).addChild(comp);
                  }
                }
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .addedComponent(context,comp);
              },possibleItems: (customNamed!=null&&(component as CustomNamedHolder).selectable[customNamed!]!=null)?(component as CustomNamedHolder).selectable[customNamed!]!:null);
              break;
            case 'remove':
              if (component.parent != null) {
                if (component.parent is Holder) {
                  (component.parent as Holder).updateChild(null);
                } else if (component.parent is MultiHolder) {
                  (component.parent as MultiHolder).removeChild(component);
                }
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .addedComponent(context,component);
              }
              break;
            case 'replace':
              showSelectionDialog((comp) {
                if (component is Holder) {
                  if (comp is Holder) {
                    comp.updateChild((component as Holder).child);
                    Provider.of<ComponentOperationCubit>(context, listen: false)
                        .addedComponent(context,comp);
                  } else if (comp is MultiHolder &&
                      (component as Holder).child != null) {
                    comp.addChild((component as Holder).child!);
                    Provider.of<ComponentOperationCubit>(context, listen: false)
                        .addedComponent(context,comp);
                  }
                } else if (component is MultiHolder) {
                  if (comp is MultiHolder) {
                    comp.children.clear();
                    comp.addChildren((component as MultiHolder).children);
                    (component as MultiHolder).children.clear();
                    Provider.of<ComponentOperationCubit>(context, listen: false)
                        .addedComponent(context,comp);
                  }
                }
              });
          }
        },
        child: const Icon(
          Icons.more_vert,
          color: Colors.black,
          size: 24,
        ));
  }

  void showSelectionDialog(void Function(Component) onSelection,{List<String>? possibleItems}) {
    Get.dialog(
      GestureDetector(
        onTap: () {
          Get.back();
        },
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 300,
              height: 500,
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: ListView(
                children:(possibleItems ?? componentList.keys.toList())
                    .map(
                      (e) => InkWell(
                        onTap: () {
                          onSelection(componentList[e]!());
                          Get.back();
                        },
                        child: Container(
                          width: 130,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Center(
                            child: Text(
                              e,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 14),
                            ),
                          ),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 2),
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
