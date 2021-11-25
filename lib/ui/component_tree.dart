import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            return Container(
              padding: const EdgeInsets.all(10),
              child: getSublist(
                  Provider.of<ComponentOperationCubit>(context, listen: false)
                      .rootComponent),
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
              IconButton(
                onPressed: () {
                  showSelectionDialog((comp) {
                    component.addChild(comp);
                    Provider.of<ComponentOperationCubit>(context, listen: false)
                        .changedComponent();
                  });
                },
                icon: const Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 24,
                ),
              )
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
              IconButton(
                onPressed: () {
                  showSelectionDialog((comp) {
                    component.updateChild(comp);
                    Provider.of<ComponentOperationCubit>(context, listen: false)
                        .changedComponent();
                  });
                },
                icon: const Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 24,
                ),
              )
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
    }
    return InkWell(
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
                color:
                    Provider.of<ComponentSelectionCubit>(context, listen: false)
                                .currentSelected ==
                            component
                        ? Colors.blue
                        : Colors.black,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  void showSelectionDialog(void Function(Component) onSelection) {
    Get.dialog(
      GestureDetector(
        onTap: (){
          Get.back();
        },
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 300,
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: componentList.keys
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
