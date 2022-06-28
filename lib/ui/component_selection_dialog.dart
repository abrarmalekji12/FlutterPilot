import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../common/custom_popup_builder_menu_button.dart';
import '../common/custom_popup_menu_button.dart';
import 'package:shimmer/shimmer.dart';
import '../common/app_text_field.dart';
import '../common/custom_text_field.dart';
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

class _ComponentSelectionDialogState extends State<ComponentSelectionDialog>
    with SingleTickerProviderStateMixin {
  static String filter = '';
  int selectedIndex = 0;
  List<String> filtered = [];
  final ScrollController _favouriteScrollController = ScrollController();
  final ScrollController _basicComponentScrollController = ScrollController();
  List<CustomComponent> filteredCustomComponents = [];
  final focusNode = FocusNode();
  final _textFieldFocusNode = FocusNode();
  final componentNames = componentList.keys.toList();
  late final TabController _tabController;
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _controller = TextEditingController();

  _ComponentSelectionDialogState();

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.shouldShowFavourites ? 3 : 2, vsync: this);
    _controller.text = filter;
    _controller.selection =
        TextSelection(baseOffset: 0, extentOffset: filter.length);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _textFieldFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final componentOperationCubit = widget.componentOperationCubit;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: RawKeyboardListener(
          focusNode: focusNode,
          onKey: (key) {
            if (key is RawKeyDownEvent) {
              logger('pressed ${key.physicalKey} ${key.logicalKey}');
              if (key.physicalKey == PhysicalKeyboardKey.enter) {
                widget.onSelection(componentList[filtered[selectedIndex]]!());

                Navigator.pop(context);
              } else if (key.physicalKey == PhysicalKeyboardKey.arrowDown) {
                if (selectedIndex + 4 < filtered.length) {
                  selectedIndex = (selectedIndex + 4);
                  setState(() {});
                }
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
                if (selectedIndex + 1 < filtered.length) {
                  selectedIndex = (selectedIndex + 1);
                  setState(() {});
                }
              }
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                if (GlobalObjectKey(filtered[selectedIndex]).currentContext !=
                    null) {
                  Scrollable.ensureVisible(
                      GlobalObjectKey(filtered[selectedIndex]).currentContext!,
                      alignment: 0.5);
                }
              });
            }
          },
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
                    controller: _controller,
                    node: _textFieldFocusNode,
                    key: const GlobalObjectKey('search'),
                    onChange: (value) {
                      filter = value.toLowerCase();
                      selectedIndex = 0;
                      setState2(() {});
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TabBar(
                    tabs: [
                      Tab(
                        child: Text(
                          'Basic widgets',
                          style: AppFontStyle.roboto(14,
                              color: const Color(0xff494949),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Custom widgets',
                          style: AppFontStyle.roboto(14,
                              color: const Color(0xff494949),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (widget.shouldShowFavourites)
                        Tab(
                          child: Text(
                            'Favourites',
                            style: AppFontStyle.roboto(14,
                                color: const Color(0xff494949),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                    controller: _tabController,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    flex: 4,
                    child: TabBarView(controller: _tabController, children: [
                      GridView(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4, childAspectRatio: 3.5),
                        controller: _basicComponentScrollController,
                        children: filtered
                            .asMap()
                            .entries
                            .map(
                              (entry) => BasicComponentTile(selectedIndex,
                                  entry, componentOperationCubit, widget),
                            )
                            .toList(),
                      ),
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 3.5),
                        controller: ScrollController(),
                        itemBuilder: (context, i) {
                          return InkWell(
                            onTap: () {
                              final customComponentClone =
                                  filteredCustomComponents[i]
                                      .createInstance(null);
                              print(
                                  'objects length ${filteredCustomComponents[i].objects.length}');
                              widget.onSelection(customComponentClone);

                              Navigator.pop(context);
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
                      if (widget.shouldShowFavourites)
                        OverflowBox(
                          child: RuntimeProvider(
                            runtimeMode: RuntimeMode.viewOnly,
                            child: LayoutBuilder(
                                builder: (context, constraints) {
                              return BlocBuilder<ComponentOperationCubit,
                                  ComponentOperationState>(
                                buildWhen: (context, state) {
                                  return state is ComponentUpdatedState;
                                },
                                bloc: componentOperationCubit,
                                builder: (context, state) {
                                  if (state
                                      is ComponentOperationLoadingState) {
                                    return Shimmer.fromColors(
                                      baseColor: const Color(0xfff2f2f2),
                                      highlightColor: Colors.white,
                                      child: ListView.builder(
                                        itemBuilder: (BuildContext context,
                                            int index) {
                                          return Container(
                                            height: 100,
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            decoration: BoxDecoration(
                                                color:
                                                    const Color(0xfff2f2f2),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10)),
                                          );
                                        },
                                        itemCount: 10,
                                      ),
                                    );
                                  }

                                  return SmartRefresher(
                                    controller: _refreshController,
                                    onRefresh: () {
                                      componentOperationCubit
                                          .loadFavourites()
                                          .then((value) {
                                        _refreshController.refreshCompleted();
                                        setState2(() {});
                                      });
                                    },
                                    child: SingleChildScrollView(
                                      controller: _favouriteScrollController,
                                      child: Wrap(
                                        children: componentOperationCubit
                                            .favouriteList
                                            .where((element) => element
                                                .projectName
                                                .toLowerCase()
                                                .contains(filter))
                                            .map((model) => FavouriteWidget(
                                                model, constraints, setState2,
                                                componentOperationCubit:
                                                    componentOperationCubit,
                                                widget: widget))
                                            .toList(),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        )
                    ]),
                  ),
                ],
              );
            }),
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
    if (model.component.boundary == null) {
      throw Exception('Boundary is null');
    }
    return Card(
      elevation: 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              final component = model.component.clone(null, deepClone: true);
              component.forEach((p0) {
                p0.cloneOf = null;
              });
              componentOperationCubit
                  .extractSameTypeComponents(model.component);
              widget.onSelection(component);

              Navigator.pop(context);
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
      key: GlobalObjectKey(entry.value),
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

            Navigator.pop(context);
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
                    title: 'Used ${entry.value} widgets',
                    itemBuilder: (context, index) {
                      return CustomPopupMenuItem<Component>(
                        value: componentOperationCubit
                            .sameComponentCollection[entry.value]![index],
                        child:
                        RuntimeProvider(
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
                      );
                    },
                    onSelected: (final Component value) {
                      widget.onSelection(value.clone(null, deepClone: true));

                      Navigator.pop(context);
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
