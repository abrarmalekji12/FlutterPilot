import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/custom_popup_menu_button.dart';
import 'package:shimmer/shimmer.dart';
import '../common/app_text_field.dart';
import '../common/logger.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import 'package:get/get.dart';
import '../component_list.dart';
import '../models/component_model.dart';

class ComponentSelectionDialog extends StatefulWidget {
  final List<String>? possibleItems;
  final void Function(Component) onSelection;
  final ComponentOperationCubit componentOperationCubit;

  const ComponentSelectionDialog(
      {Key? key, this.possibleItems, required this.onSelection,required this.componentOperationCubit})
      : super(key: key);

  @override
  State<ComponentSelectionDialog> createState() =>
      _ComponentSelectionDialogState();
}

class _ComponentSelectionDialogState extends State<ComponentSelectionDialog> {
  String filter = '';
  int selectedIndex = 0;
  List<String> filtered = [];
  List<CustomComponent> filteredCustomComponents = [];
  final focusNode = FocusNode();
  final componentNames = componentList.keys.toList();
  final TextEditingController controller = TextEditingController();

  _ComponentSelectionDialogState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
       widget. componentOperationCubit
            .loadFavourites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final componentOperationCubit=widget.componentOperationCubit;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: RawKeyboardListener(
          focusNode: focusNode,
          onKey: (key) {
            if (key is RawKeyDownEvent) {
              logger('pressed ${key.physicalKey} ${key.logicalKey}');
              if (key.physicalKey == PhysicalKeyboardKey.enter) {
                widget.onSelection(componentList[filtered[selectedIndex]]!());
                Get.back();
              } else if (key.physicalKey == PhysicalKeyboardKey.arrowDown) {
                selectedIndex = (selectedIndex + 4) % filtered.length;
                setState(() {});
              } else if (key.physicalKey == PhysicalKeyboardKey.arrowUp) {
                selectedIndex = (selectedIndex - 4 < 0)
                    ? selectedIndex + 4
                    : selectedIndex - 4;
                setState(() {});
              } else if (key.physicalKey == PhysicalKeyboardKey.arrowLeft) {
                selectedIndex = (selectedIndex - 1 < 0)
                    ? selectedIndex + 1
                    : selectedIndex - 1;
                setState(() {});
              } else if (key.physicalKey == PhysicalKeyboardKey.arrowRight) {
                selectedIndex = (selectedIndex + 1) % filtered.length;
                setState(() {});
              }
            }
          },
          child: GestureDetector(
            onTap: (){},
            child: Container(
              width: dw(context,50),
              height: dh(context, 80),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(builder: (context, setState2) {
                filteredCustomComponents =
                  componentOperationCubit
                        .flutterProject!
                        .customComponents
                        .where((element) =>
                            element.name.isCaseInsensitiveContains(filter))
                        .toList();
                filtered = (widget.possibleItems ?? componentNames)
                    .where((element) => element.isCaseInsensitiveContains(filter))
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Basic widgets',
                        style: AppFontStyle.roboto(14,
                            color: const Color(0xff494949),fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: GridView(
                        controller: ScrollController(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4, childAspectRatio: 3.5),
                        children: filtered
                            .asMap()
                            .entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
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
                                  child: InkWell(
                                    onTap: () {
                                      widget.onSelection(componentList[e.value]!());
                                      Get.back();
                                    },
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
                    // Padding(
                    //   padding: const EdgeInsets.all(10),
                    //   child: Text(
                    //     'custom widgets',
                    //     style: AppFontStyle.roboto(14,
                    //         color: const Color(0xff494949)),
                    //   ),
                    // ),
                    // Expanded(
                    //   flex: 4,
                    //   child: GridView.builder(
                    //     gridDelegate:
                    //         const SliverGridDelegateWithFixedCrossAxisCount(
                    //             crossAxisCount: 2, childAspectRatio: 3.5),
                    //     controller: ScrollController(),
                    //     itemBuilder: (context, i) {
                    //       return InkWell(
                    //         onTap: () {
                    //           final customComponentClone =
                    //               filteredCustomComponents[i]
                    //                   .createInstance(null);
                    //           widget.onSelection(customComponentClone);
                    //           Get.back();
                    //         },
                    //         child: Padding(
                    //           padding: const EdgeInsets.only(bottom: 10),
                    //           child: Card(
                    //             elevation: 2,
                    //             shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(10)),
                    //             child: Center(
                    //               child: Text(
                    //                 filteredCustomComponents[i].name,
                    //                 style: AppFontStyle.roboto(12,
                    //                     color: Colors.black,
                    //                     fontWeight: FontWeight.w500),
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //     itemCount: filteredCustomComponents.length,
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Favourites',
                        style: AppFontStyle.roboto(14,
                            color: const Color(0xff494949),fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: BlocBuilder<ComponentOperationCubit,
                          ComponentOperationState>(
                        bloc: componentOperationCubit,
                        builder: (context, state) {
                          if (state is ComponentOperationLoadingState) {
                            return Shimmer.fromColors(
                              baseColor: const Color(0xfff2f2f2),
                              highlightColor: Colors.white,
                              child: ListView.builder(
                                itemBuilder: (BuildContext context, int index) {
                                  return Container(
                                    height: 100,
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                        color: const Color(0xfff2f2f2),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  );
                                },
                                itemCount: 10,
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            child: Wrap(
                              children: componentOperationCubit
                                  .favouriteList.map((model) =>Card(
                                elevation: 2,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        widget.onSelection(model
                                            .component
                                            .clone(null, cloneParam: true));
                                        Get.back();
                                      },
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: model
                                              .component
                                              .boundary!
                                              .width,
                                          height: model
                                              .component
                                              .boundary!
                                              .height,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                              gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xfff2f2f2),
                                                    Color(0xffd3d3d3)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end:
                                                  Alignment.bottomRight)),
                                          child: model
                                              .component
                                              .build(context),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        componentOperationCubit
                                            .removeModelFromFavourites(model);
                                        setState2(() {});
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(5),
                                        child: CircleAvatar(
                                          child: Center(
                                            child: Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                          radius: 10,
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ) ).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
