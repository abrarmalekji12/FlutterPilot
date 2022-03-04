import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/custom_popup_builder_menu_button.dart';
import '../common/custom_popup_menu_button.dart';
import 'package:shimmer/shimmer.dart';
import '../common/app_text_field.dart';
import '../common/logger.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import 'package:get/get.dart';
import '../component_list.dart';
import '../models/component_model.dart';
import '../models/other_model.dart';
import '../runtime_provider.dart';

class ComponentSelectionDialog extends StatefulWidget {
  final List<String>? possibleItems;
  final void Function(Component) onSelection;
  final bool shouldShowFavourites;
  final ComponentOperationCubit componentOperationCubit;

  const ComponentSelectionDialog(
      {Key? key,
      this.possibleItems,
      this.shouldShowFavourites = true,
      required this.onSelection,
      required this.componentOperationCubit})
      : super(key: key);

  @override
  State<ComponentSelectionDialog> createState() =>
      _ComponentSelectionDialogState();
}

class _ComponentSelectionDialogState extends State<ComponentSelectionDialog> {
  String filter = '';
  int selectedIndex = 0;
  List<String> filtered = [];
  final ScrollController _favouriteScrollController = ScrollController();
  List<CustomComponent> filteredCustomComponents = [];
  final focusNode = FocusNode();
  final componentNames = componentList.keys.toList();
  final TextEditingController controller = TextEditingController();

  _ComponentSelectionDialogState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final componentOperationCubit = widget.componentOperationCubit;
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
            onTap: () {},
            child: Container(
              width: dw(context, 50),
              height: dh(context, 80),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(builder: (context, setState2) {
                filteredCustomComponents = componentOperationCubit
                    .flutterProject!.customComponents
                    .where((element) =>
                        element.name.isCaseInsensitiveContains(filter))
                    .toList();
                filtered = (widget.possibleItems ?? componentNames)
                    .where(
                        (element) => element.isCaseInsensitiveContains(filter))
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
                            color: const Color(0xff494949),
                            fontWeight: FontWeight.bold),
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
                              (entry) => BasicComponentTile(selectedIndex,
                                  entry, componentOperationCubit, widget),
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
                    if (widget.shouldShowFavourites) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              'Favourites',
                              style: AppFontStyle.roboto(14,
                                  color: const Color(0xff494949),
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            InkWell(
                              onTap: () {
                                componentOperationCubit.loadFavourites();
                              },
                              child: const Icon(
                                Icons.refresh,
                                size: 20,
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: RuntimeProvider(
                          runtimeMode: RuntimeMode.viewOnly,
                          child: LayoutBuilder(builder: (context, constraints) {
                            return BlocBuilder<ComponentOperationCubit,
                                ComponentOperationState>(
                              bloc: componentOperationCubit,
                              builder: (context, state) {
                                if (state is ComponentOperationLoadingState) {
                                  return Shimmer.fromColors(
                                    baseColor: const Color(0xfff2f2f2),
                                    highlightColor: Colors.white,
                                    child: ListView.builder(
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return Container(
                                          height: 100,
                                          padding: const EdgeInsets.all(10),
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
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
                                  controller: _favouriteScrollController,
                                  child: Wrap(
                                    children: componentOperationCubit
                                        .favouriteList
                                        .where((element) => element.projectName
                                            .toLowerCase()
                                            .contains(filter))
                                        .map((model) => FavouriteWidget(
                                            model, constraints, setState2,
                                            componentOperationCubit:
                                                componentOperationCubit,
                                            widget: widget))
                                        .toList(),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    ]
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

class FavouriteWidget extends StatelessWidget {
  final FavouriteModel model;
  final BoxConstraints constraints;

  final StateSetter setState2;

  const FavouriteWidget(
    this.model,
    this.constraints,
    this.setState2, {
    Key? key,
    required this.componentOperationCubit,
    required this.widget,
  }) : super(key: key);

  final ComponentOperationCubit componentOperationCubit;
  final ComponentSelectionDialog widget;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              final component = model.component.clone(null, cloneParam: true);
              componentOperationCubit
                  .extractSameTypeComponents(model.component);
              widget.onSelection(component);
              Get.back();
            },
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: IgnorePointer(
                  ignoring: true,
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Container(
                        width: constraints.maxWidth - 70 >
                                model.component.boundary!.width
                            ? model.component.boundary!.width
                            : constraints.maxWidth - 70,
                        height: model.component.boundary!.height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                              colors: [Color(0xfff2f2f2), Color(0xffd3d3d3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                        ),
                        child: model.component.build(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              componentOperationCubit.removeModelFromFavourites(model);
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
    );
  }
}

class BasicComponentTile extends StatelessWidget {
  final int selectedIndex;
  final MapEntry<int, String> entry;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentSelectionDialog widget;

  const BasicComponentTile(
      this.selectedIndex, this.entry, this.componentOperationCubit, this.widget,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: selectedIndex == entry.key
                  ? AppColors.theme
                  : Colors.transparent,
              width: 2),
        ),
        child: InkWell(
          onTap: () {
            final component = componentList[entry.value]!();
            componentOperationCubit.addInSameComponentList(component);
            widget.onSelection(component);
            Get.back();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      entry.value,
                      overflow: TextOverflow.fade,
                      style: AppFontStyle.roboto(12,
                          color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                if (componentOperationCubit.sameComponentCollection
                        .containsKey(entry.value) &&
                    (componentOperationCubit
                            .sameComponentCollection[entry.value]?.isNotEmpty ??
                        false))
                  CustomPopupMenuBuilderButton(
                    itemBuilder: (context, index) {
                      return CustomPopupMenuItem<Component>(
                        value: componentOperationCubit
                            .sameComponentCollection[entry.value]![index],
                        child: SizedBox(
                          height: 130,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: RuntimeProvider(
                                    runtimeMode: RuntimeMode.viewOnly,
                                    child: Builder(builder: (context) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          gradient: const LinearGradient(
                                              colors: [
                                                Color(0xfff2f2f2),
                                                Color(0xffd3d3d3)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: SizedBox(
                                            width: componentOperationCubit
                                                    .sameComponentCollection[
                                                        entry.value]![index]
                                                    .boundary
                                                    ?.width ??
                                                50,
                                            height: componentOperationCubit
                                                    .sameComponentCollection[
                                                        entry.value]![index]
                                                    .boundary
                                                    ?.height ??
                                                50,
                                            child: componentOperationCubit
                                                .sameComponentCollection[
                                                    entry.value]![index]
                                                .build(context),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Text(
                                    componentOperationCubit
                                        .sameComponentCollection[entry.value]![
                                            index]
                                        .code(),
                                    style: AppFontStyle.roboto(
                                      10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onSelected: (final Component value) {
                      widget.onSelection(value.clone(null, cloneParam: true));
                      Get.back();
                    },
                    itemCount: componentOperationCubit
                        .sameComponentCollection[entry.value]!.length,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
