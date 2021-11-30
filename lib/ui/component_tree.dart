import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/custom_popup_menu_button.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/constant/app_colors.dart';
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
            return Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(10),
                  child: getSublist(Provider.of<ComponentOperationCubit>(
                          context,
                          listen: false)
                      .rootComponent),
                ),
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
              ComponentTile(component: component),
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
              ComponentTile(component: component),
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
            children: [ComponentTile(component: component)],
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
                          style: AppFontStyle.roboto(12,
                              color: Colors.grey.shade700),
                        ),
                        const Spacer(),
                        ComponentModificationMenu(
                          component: component,
                          customNamed: child,
                        )
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
      children: [ComponentTile(component: component)],
    );
  }
}

class ComponentModificationMenu extends StatelessWidget {
  static const operations = ['wrap with', 'remove'];
  final Component component;

  final String? customNamed;

  const ComponentModificationMenu(
      {Key? key, this.customNamed, required this.component})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final components =
        componentList.map((key, value) => MapEntry(key, value()));
    return Row(
      children: [
        if (component is MultiHolder ||
            (component is Holder && (component as Holder).child == null) ||
            (component is CustomNamedHolder &&
                (component as CustomNamedHolder).children[customNamed!] ==
                    null)) ...[
          InkWell(
            onTap: () {
              showSelectionDialog((comp) {
                if (customNamed != null) {
                  (component as CustomNamedHolder)
                      .updateChild(customNamed!, comp);
                } else {
                  if (component is Holder) {
                    (component as Holder).updateChild(comp);
                  } else if (component is MultiHolder) {
                    (component as MultiHolder).addChild(comp);
                  }
                }
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .addedComponent(context, comp);
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
                )),
          ),
        ],
        if (customNamed == null) ...[
          const SizedBox(
            width: 10,
          ),
          InkWell(
            onTap: () {
              showSelectionDialog((comp) {
                switch (comp.type) {
                  case 2:
                    //MultiHolder
                    switch (component.parent?.type) {
                      case 2:
                        //MultiHolder
                        final children = (component as MultiHolder).children;
                        (component.parent as MultiHolder)
                            .replaceChild(component, comp);
                        (comp as MultiHolder).children = children;
                        break;
                      case 3:
                        //Holder
                        final child = (component as Holder).child;
                        (component.parent as Holder).updateChild(comp);
                        (comp as Holder).child = child;
                        break;
                      case 4:
                        final children = (component as MultiHolder).children;
                        (component.parent as CustomNamedHolder)
                            .replaceChild(component, comp);
                        (comp as MultiHolder).children = children;
                        break;
                    }
                    break;
                  case 3:
                    //Holder
                    switch (component.parent?.type) {
                      case 2:
                        //MultiHolder
                        final child = (component as Holder).child;
                        (component.parent as MultiHolder)
                            .replaceChild(component, comp);
                        (comp as Holder).child = child;
                        break;
                      case 3:
                        //Holder
                        final child = (component as Holder).child;
                        (component.parent as Holder).updateChild(comp);
                        (comp as Holder).child = child;
                        break;
                      case 4:
                        //CustomNamedHolder
                        final child = (component as Holder).child;
                        (component.parent as CustomNamedHolder)
                            .replaceChild(component, comp);
                        (comp as Holder).child = child;
                        break;
                    }
                }
                Provider.of<ComponentOperationCubit>(context, listen: false)
                    .addedComponent(context, comp);
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
        ],
        CustomPopupMenuButton(
            itemBuilder: (context) {
              return operations
                  .map(
                    (e) => CustomPopupMenuItem(
                      value: e,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          e,
                          style: AppFontStyle.roboto(18,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  )
                  .toList();
            },
            onSelected: (e) {
              switch (e) {
                case 'remove':
                  final parent=component.parent;
                  switch(component.type){
                    case 1:
                      //Component

                      break;
                    case 2:
                      //MultiHolder
                      (component as MultiHolder).children.clear();
                      break;
                  }
                  switch(component.parent?.type){
                    case 2:
                      (component.parent as MultiHolder).removeChild(component);
                      break;
                    case 3 :
                      (component.parent as Holder).updateChild(null);
                      break;
                    case 4 :
                      (component.parent as CustomNamedHolder).replaceChild(component,null);
                      break;
                  }
                  Provider.of<ComponentOperationCubit>(context, listen: false)
                      .removedComponent(context, parent!);
                  break;
              }
            },
            child: const Icon(
              Icons.more_vert,
              color: Colors.black,
              size: 24,
            )),
      ],
    );
  }

  List<String> getSameComponents(
      Map<String, Component> components, Component component) {
    final List<String> sameComponents = [];
    for (final key in components.keys) {
      if (components[key] != component &&
          components[key]!.type == component.type) {
        sameComponents.add(key);
      }
    }
    return sameComponents;
  }

  void showSelectionDialog(void Function(Component) onSelection,
      {List<String>? possibleItems}) {
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
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: (possibleItems ?? componentList.keys.toList())
                    .map(
                      (e) => InkWell(
                        onTap: () {
                          onSelection(componentList[e]!());
                          Get.back();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: Container(
                              width: 130,
                              padding: const EdgeInsets.all(10),
                              alignment: Alignment.center,
                              child: Text(
                                e,
                                style: AppFontStyle.roboto(14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
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

class ComponentTile extends StatelessWidget {
  final Component component;

  const ComponentTile({Key? key, required this.component}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Provider.of<ComponentSelectionCubit>(context, listen: false)
            .changeComponentSelection(component);
      },
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: Provider.of<ComponentSelectionCubit>(context, listen: false)
                        .currentSelected ==
                    component
                ? const BorderSide(color: Colors.blueAccent, width: 2.5)
                : const BorderSide()),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          child: Text(
            component.name,
            style: AppFontStyle.roboto(14,
                color: Colors.black, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
