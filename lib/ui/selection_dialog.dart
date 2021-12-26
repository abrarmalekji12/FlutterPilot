import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_builder/common/app_text_field.dart';
import 'package:flutter_builder/constant/app_colors.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/string_extensions.dart';
import 'package:provider/provider.dart';

import '../component_list.dart';
import '../models/component_model.dart';

class SelectionDialog extends StatefulWidget {
  final List<String>? possibleItems;
  final void Function(Component) onSelection;

  const SelectionDialog(
      {Key? key, this.possibleItems, required this.onSelection})
      : super(key: key);

  @override
  State<SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  String filter = '';
  int selectedIndex = 0;
  List<String> filtered=[];
  List<CustomComponent> filteredCustomComponents=[];
  final focusNode = FocusNode();
  final componentNames = componentList.keys.toList();
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Colors.transparent,
      child: Center(
        child: RawKeyboardListener(
          focusNode: focusNode,
          onKey: (key) {
            if(key is RawKeyDownEvent) {
              debugPrint('pressed ${key.physicalKey} ${key.logicalKey}');
              if (key.physicalKey == PhysicalKeyboardKey.enter) {
                widget.onSelection(componentList[filtered[selectedIndex]]!());
                Get.back();
              }
              else if (key.physicalKey == PhysicalKeyboardKey.arrowDown) {
                selectedIndex =(selectedIndex+ 2)%filtered.length;
                setState(() {

                });
              }
              else if (key.physicalKey == PhysicalKeyboardKey.arrowUp) {
                selectedIndex =(selectedIndex- 2<0)?selectedIndex+2:selectedIndex-2;
                setState(() {

                });
              }
              else if (key.physicalKey == PhysicalKeyboardKey.arrowLeft) {

                selectedIndex =(selectedIndex- 1<0)?selectedIndex+1:selectedIndex-1;
                setState(() {

                });
              }
              else if (key.physicalKey == PhysicalKeyboardKey.arrowRight) {
                selectedIndex =(selectedIndex+ 1)%filtered.length;
                setState(() {

                });
              }
            }
          },
          child: Container(
            width: 400,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context,setState2) {
                filteredCustomComponents =
                    Provider.of<ComponentOperationCubit>(context, listen: false)
                        .mainExecution
                        .customComponents
                        .where((element) => element.name.isCaseInsensitiveContains(filter))
                        .toList();
                filtered=(widget.possibleItems ?? componentNames)
                    .where((element) =>
                    element.isCaseInsensitiveContains(filter))
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: controller,
                      key: const GlobalObjectKey('search'),
                      onChange: (value) {
                        filter = value.toLowerCase();
                        selectedIndex = 0;
                        setState2(() {});
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'basic widgets',
                        style:
                            AppFontStyle.roboto(14, color: const Color(0xff494949)),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: GridView(
                        controller: ScrollController(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 3.5),
                        children:
                            filtered.asMap()
                            .entries
                            .map(
                              (e) => InkWell(
                                onTap: () {
                                  widget.onSelection(componentList[e.value]!());
                                  Get.back();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                          color: selectedIndex == e.key
                                              ? AppColors.theme
                                              : Colors.transparent,
                                          width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        e.value,
                                        style: AppFontStyle.roboto(12,
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
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'custom widgets',
                        style:
                            AppFontStyle.roboto(14, color: const Color(0xff494949)),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 3.5),
                        controller: ScrollController(),
                        itemBuilder: (context, i) {
                          return InkWell(
                            onTap: () {
                              final customComponentClone =
                                  filteredCustomComponents[i].clone(null);
                              filteredCustomComponents[i]
                                  .objects
                                  .add(customComponentClone as CustomComponent);
                              widget.onSelection(customComponentClone);
                              Get.back();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Center(
                                  child: Text(
                                    filteredCustomComponents[i].name,
                                    style: AppFontStyle.roboto(12,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        itemCount: filteredCustomComponents.length,
                      ),
                    )
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }
}
