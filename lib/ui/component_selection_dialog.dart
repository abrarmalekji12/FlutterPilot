import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'project/project_selection_page.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get.dart';

import '../collections/project_info_collection.dart';
import '../common/app_button.dart';
import '../common/app_switch.dart';
import '../common/common_methods.dart';
import '../common/component_search.dart';
import '../common/custom_popup_builder_menu_button.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/drag_target.dart';
import '../common/extension_util.dart';
import '../common/responsive/responsive_widget.dart';
import '../components/component_list.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../constant/image_asset.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../data/remote/firestore/firebase_bridge.dart';
import '../injector.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/fvb_ui_core/component/custom_component.dart';
import '../models/global_component.dart';
import '../models/other_model.dart';
import '../runtime_provider.dart';
import '../user_session.dart';
import '../widgets/button/app_close_button.dart';
import '../widgets/loading/app_loading.dart';
import '../widgets/message/empty_text.dart';
import '../widgets/textfield/appt_search_field.dart';
import 'controls_widget.dart';
import 'home/home_page.dart';
import 'home/landing_page.dart';
import 'navigation/animated_dialog.dart';

final UserProjectCollection _collection = sl<UserProjectCollection>();

class ComponentSelectionDialog extends StatefulWidget {
  final void Function(Component)? onSelection;
  final bool shouldShowFavourites;
  final bool sideView;
  final VoidCallback? onBack;
  final List<String>? possibleItems;

  const ComponentSelectionDialog({
    Key? key,
    this.sideView = false,
    this.possibleItems,
    this.shouldShowFavourites = true,
    this.onSelection,
    this.onBack,
  }) : super(key: key);

  @override
  State<ComponentSelectionDialog> createState() =>
      _ComponentSelectionDialogState();
}

int selectedIndex = 0;

List<BoxShadow> get dragBoxShadow => [
      BoxShadow(
        color: theme.text1Color.withOpacity(0.1),
        blurRadius: 8,
        spreadRadius: 2,
      )
    ];

class _ComponentSelectionDialogState extends State<ComponentSelectionDialog>
    with TickerProviderStateMixin {
  late final TabController tabController;
  late final OperationCubit componentOperationCubit;

  _ComponentSelectionDialogState();

  late Processor processor;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
        length: widget.shouldShowFavourites ? 2 : 1,
        initialIndex: selectedIndex,
        vsync: this);
    componentOperationCubit = context.read<OperationCubit>();
    processor = _collection.project!.processor.clone((data,
        {List<dynamic>? arguments}) {
      return null;
    }, (error, code) {}, true);
    OperationCubit.paramProcessor = processor;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: RuntimeProvider(
        runtimeMode: RuntimeMode.favorite,
        child: ProcessorProvider(
          processor: OperationCubit.paramProcessor,
          child: Card(
            elevation: 4,
            margin: EdgeInsets.zero,
            color: theme.background1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              width: widget.sideView
                  ? null
                  : (Responsive.isDesktop(context)
                      ? dw(context, 50)
                      : double.infinity),
              height: widget.sideView ? double.infinity : dh(context, 90),
              padding: widget.sideView
                  ? const EdgeInsets.symmetric(horizontal: 12)
                  : const EdgeInsets.all(20),
              child: BlocBuilder<OperationCubit, OperationState>(
                buildWhen: (prev, current) =>
                    current is CustomComponentUpdatedState ||
                    current is ComponentUpdatedState,
                builder: (context, state) {
                  return Column(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        height: 30,
                        child: Row(
                          children: [
                            const SliderBackButton(),
                            Expanded(
                              child: TabBar(
                                tabs: [
                                  const Tab(
                                    text: 'All',
                                  ),
                                  if (widget.shouldShowFavourites)
                                    const Tab(
                                      text: 'Favorites',
                                    ),
                                ],
                                onTap: (value) {
                                  selectedIndex = value;
                                },
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                splashBorderRadius: BorderRadius.circular(6),
                                indicatorPadding:
                                    const EdgeInsets.symmetric(horizontal: -2),
                                indicatorWeight: 4,
                                indicatorSize: TabBarIndicatorSize.label,
                                controller: tabController,
                                isScrollable: true,
                                indicatorColor: ColorAssets.theme,
                                labelStyle: AppFontStyle.lato(
                                  14,
                                  color: ColorAssets.theme,
                                  fontWeight: FontWeight.w900,
                                ),
                                labelColor: ColorAssets.theme,
                                unselectedLabelColor: theme.text1Color,
                                unselectedLabelStyle: AppFontStyle.lato(14,
                                    color: theme.text3Color,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: [
                            AllComponentsView(
                              onSelection: widget.onSelection,
                              sideView: widget.sideView,
                              possibleItems: widget.possibleItems,
                            ),
                            /*  Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                  height: 35,
                                  child: AppSearchField(
                                    controller: _controller,
                                    focusNode: _textFieldFocusNode,
                                    key: widget.sideView ? null : const GlobalObjectKey('search'),
                                    onChanged: (value) {
                                      filter = value.toLowerCase();
                                      selectedIndex = 0;
                                      setState2(() {});
                                    },
                                    hint: 'Search...',
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Expanded(
                                  flex: 4,
                                  child: SmartRefresher(
                                    controller: _refreshController,
                                    onRefresh: () {
                                      componentOperationCubit.loadFavourites().then((value) {
                                        _refreshController.refreshCompleted();
                                        setState2(() {});
                                      });
                                    },
                                    child: widget.sideView
                                        ? const Offstage()
                                        : GridView(
                                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                                mainAxisExtent: 50,
                                                mainAxisSpacing: 5,
                                                crossAxisSpacing: 5,
                                                maxCrossAxisExtent: tileSize),
                                            controller: _basicComponentScrollController,
                                            children: _getChildren(),
                                          ),
                                  ),
                                ),
                              ],
                            ),*/
                            if (widget.shouldShowFavourites)
                              FavouriteListingWidget(
                                dialog: widget,
                                sideView: widget.sideView,
                                processor: processor,
                              )
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FavouriteListingWidget extends StatefulWidget {
  final bool sideView;
  final Processor processor;
  final ComponentSelectionDialog dialog;

  const FavouriteListingWidget({
    Key? key,
    required this.sideView,
    required this.processor,
    required this.dialog,
  }) : super(key: key);

  @override
  State<FavouriteListingWidget> createState() => _FavouriteListingWidgetState();
}

class _FavouriteListingWidgetState extends State<FavouriteListingWidget> {
  final OperationCubit operationCubit = sl<OperationCubit>();
  String filter = '';
  List<FavouriteModel> list = [];

  @override
  void initState() {
    super.initState();
    _updated();
  }

  void _updated() {
    list = collection.favouriteList
        .where(
          (component) => ComponentSearch.search(filter, component.component),
        )
        .toList();
    list.sort((a, b) => a.createdAt == null && b.createdAt != null
        ? 1
        : (b.createdAt == null
            ? 0
            : (b.createdAt!.isAfter(a.createdAt!) ? -1 : 1)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OperationCubit, OperationState>(
        buildWhen: (_, state) =>
            state is ComponentFavouriteListUpdatedState ||
            state is ComponentFavouriteLoadedState,
        builder: (context, _) {
          return list.isEmpty
              ? const EmptyTextIconWidget(
                  text: 'No favorites',
                  icon: Icons.favorite_rounded,
                )
              : (widget.sideView
                  ? Column(
                      children: [
                        SizedBox(
                          height: 35,
                          child: Row(
                            children: [
                              Expanded(
                                child: AppSearchField(
                                  onChanged: (value) {
                                    filter = value.toLowerCase();
                                    selectedIndex = 0;
                                    _updated();
                                    setState(() {});
                                  },
                                  hint: 'Search...',
                                ),
                              ),
                              AppIconButton(
                                  icon: Icons.refresh,
                                  onPressed: () {
                                    operationCubit.loadFavourites();
                                  })
                            ],
                          ),
                        ),
                        10.hBox,
                        Expanded(
                          child: ListView.separated(
                            separatorBuilder: (_, __) {
                              return const SizedBox(
                                height: 4,
                              );
                            },
                            itemBuilder: (_, index) {
                              return _buildTile(list[index]);
                            },
                            itemCount: list.length,
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          children: list
                              .map((model) => FavouriteWidget(
                                    model,
                                    sideView: widget.sideView,
                                    onRemove: _onRemove,
                                    onTap: _onTap,
                                  ))
                              .toList(),
                        ),
                      ),
                    ));
        });
  }

  Widget _buildTile(FavouriteModel model) {
    return CustomDraggable(
      data: model,
      feedback: RuntimeProvider(
        runtimeMode: RuntimeMode.favorite,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 180,
            child: FavouriteWidget(
              model,
              sideView: widget.sideView,
            ),
          ),
        ),
      ),
      child: FavouriteWidget(
        model,
        sideView: widget.sideView,
        onRemove: _onRemove,
        onTap: _onTap,
      ),
    );
  }

  void _onRemove(FavouriteModel model) {
    operationCubit.removeModelFromFavourites(model);
    setState(() {});
  }

  void _onTap(FavouriteModel model) {
    final component =
        model.component.clone(null, deepClone: true, connect: false);
    component.forEachWithClones((p0) {
      p0.cloneOf = null;
      return false;
    });
    operationCubit.extractSameTypeComponents(model.component);

    Navigator.pop(context);
    widget.dialog.onSelection?.call(component);
  }
}

class AllComponentsView extends StatefulWidget {
  final void Function(Component)? onSelection;
  final List<String>? possibleItems;

  final bool sideView;

  const AllComponentsView({
    Key? key,
    required this.onSelection,
    required this.sideView,
    required this.possibleItems,
  }) : super(key: key);

  @override
  State<AllComponentsView> createState() => _AllComponentsViewState();
}

class _AllComponentsViewState extends State<AllComponentsView> {
  late OperationCubit componentOperationCubit;
  final UserSession _userSession = sl();
  final TextEditingController _controller = TextEditingController();
  String search = '';
  final List<GlobalComponentModel> globalList = [];
  List<String> filtered = [];
  List<CustomComponent> filteredCustomComponents = [];
  final _textFieldFocusNode = FocusNode();
  final focusNode = FocusNode();

  List<GlobalComponentModel> globalComponentsList = [];
  static const tileSize = 170.0;
  late int horizontalCount;
  final componentNames = componentList.keys.toList();

  @override
  void initState() {
    componentOperationCubit = context.read<OperationCubit>();
    _controller.value = TextEditingValue(
        text: search,
        selection: TextSelection(baseOffset: 0, extentOffset: search.length));
    _textFieldFocusNode.requestFocus();
    _updated();
    super.initState();
  }

  void replaceComponent(GlobalComponentModel model) async {
    await removeGlobalComponent(model);
    await uploadGlobalComponent(model);
  }

  Future<void> uploadGlobalComponent(GlobalComponentModel model) async {
    final response = await dataBridge.addGlobalComponent(null, model);
    if (response) {
      print('UPLOADED ${model.name} SUCCESS');
    } else {
      print('UPLOADED ${model.name} FAILED');
    }
  }

  Future<void> removeGlobalComponent(GlobalComponentModel model) async {
    final response = await dataBridge.removeGlobalComponent(model.id!);
    if (response) {
      print('DELETION ${model.name} SUCCESS');
    } else {
      print('DELETION ${model.name} FAILED');
    }
  }

  @override
  Widget build(BuildContext context) {
    horizontalCount =
        ((Responsive.isDesktop(context) ? dw(context, 50) : dw(context, 100)) ~/
                tileSize) +
            1;

    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: widget.sideView
          ? null
          : (key) {
              if (key is KeyDownEvent) {
                if (key.physicalKey == PhysicalKeyboardKey.enter) {
                  final bool custom = selectedIndex >= filtered.length;
                  onSelected(custom
                      ? MapEntry(
                          selectedIndex,
                          filteredCustomComponents[
                              selectedIndex - filtered.length])
                      : MapEntry(selectedIndex, filtered[selectedIndex]));
                  Navigator.pop(context);
                } else if (key.physicalKey == PhysicalKeyboardKey.arrowDown) {
                  if (selectedIndex + horizontalCount <
                      (filtered.length + filteredCustomComponents.length)) {
                    selectedIndex = (selectedIndex + horizontalCount);
                    setState(() {});
                  }
                } else if (key.physicalKey == PhysicalKeyboardKey.arrowUp) {
                  selectedIndex = (selectedIndex - horizontalCount < 0)
                      ? selectedIndex + horizontalCount
                      : selectedIndex - horizontalCount;
                  setState(() {});
                } else if (key.physicalKey == PhysicalKeyboardKey.arrowLeft) {
                  selectedIndex = (selectedIndex - 1 < 0)
                      ? selectedIndex + 1
                      : selectedIndex - 1;
                  setState(() {});
                } else if (key.physicalKey == PhysicalKeyboardKey.arrowRight) {
                  if (selectedIndex + 1 <
                      (filtered.length + filteredCustomComponents.length)) {
                    selectedIndex = (selectedIndex + 1);
                    setState(() {});
                  }
                }
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  final bool custom = selectedIndex >= filtered.length;
                  if (custom &&
                      selectedIndex - filtered.length >= 0 &&
                      filteredCustomComponents.length >
                          selectedIndex - filtered.length &&
                      GlobalObjectKey(filteredCustomComponents[
                                      selectedIndex - filtered.length]
                                  .name)
                              .currentContext !=
                          null) {
                    Scrollable.ensureVisible(
                        GlobalObjectKey(filteredCustomComponents[
                                    selectedIndex - filtered.length]
                                .name)
                            .currentContext!,
                        alignment: 0.5);
                  } else if (selectedIndex < filtered.length &&
                      GlobalObjectKey(filtered[selectedIndex]).currentContext !=
                          null) {
                    Scrollable.ensureVisible(
                        GlobalObjectKey(filtered[selectedIndex])
                            .currentContext!,
                        alignment: 0.5);
                  }
                });
              }
            },
      child: BlocConsumer<OperationCubit, OperationState>(
        buildWhen: (state1, state2) {
          return state2 is ComponentOperationComponentsLoadedState ||
              state2 is ComponentOperationComponentLoadingState;
        },
        listener: (context, state) {
          if (state is ComponentOperationComponentsLoadedState) {
            if (kDebugMode) {
              final newComps = globalList;
              // .where((element) =>
              // componentOperationCubit.componentList.firstWhereOrNull(
              //     (element2) => element2.name == element.name&&element2.description == element.description) ==
              // null);
              componentOperationCubit.componentList.addAll(newComps);
              if (newComps.isNotEmpty) {
                setState(() {});
              }
              for (final comp in newComps) {
                replaceComponent(comp);
              }
            }
          }
        },
        builder: (context, state) {
          if (state is ComponentOperationComponentLoadingState) {
            return const AppLoadingWidget();
          }
          return StatefulBuilder(builder: (context, setState2) {
            return Column(
              children: [
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: AppSearchField(
                          focusNode: _textFieldFocusNode,
                          controller: _controller,
                          onChanged: (value) {
                            setState2(() {
                              search = value.toLowerCase();
                              _updated();
                            });
                          },
                          hint: 'Search',
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        showGlobalComponentDialog(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
                Expanded(child: LayoutBuilder(builder: (context, constraints) {
                  return ListView(
                    padding: const EdgeInsets.only(top: 5),
                    children: [
                      if (constraints.maxWidth < 300)
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (_, i) => const SizedBox(
                            height: 5,
                          ),
                          shrinkWrap: true,
                          itemBuilder: (_, i) {
                            return _buildItem(globalComponentsList, i,
                                constraints, systemProcessor);
                          },
                          itemCount: globalComponentsList.length,
                        )
                      else
                        Wrap(
                          alignment: WrapAlignment.start,
                          runAlignment: WrapAlignment.start,
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(
                              globalComponentsList.length,
                              (index) => InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onSelection?.call(
                                          componentOperationCubit
                                              .favouriteInComponent(
                                                  FavouriteModel(
                                                      globalComponentsList[
                                                              index]
                                                          .component,
                                                      globalComponentsList[
                                                              index]
                                                          .customs,
                                                      null,
                                                      userId: _userSession
                                                          .user.userId!)));
                                    },
                                    child: IntrinsicWidth(
                                        child: _buildItem(
                                            globalComponentsList,
                                            index,
                                            constraints,
                                            systemProcessor)),
                                  ),
                              growable: false),
                        ),
                      ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) {
                          return const SizedBox(
                            height: 4,
                          );
                        },
                        itemBuilder: (_, index) {
                          if (index < filtered.length) {
                            return _buildTile(MapEntry(index, filtered[index]));
                          }

                          return _buildTile(MapEntry(
                              index - filtered.length,
                              filteredCustomComponents[
                                  index - filtered.length]));
                        },
                        itemCount:
                            filtered.length + filteredCustomComponents.length,
                      ),
                    ],
                  );
                }))
              ],
            );
          });
        },
      ),
    );
  }

  void _updated() {
    filteredCustomComponents = componentOperationCubit.project!.customComponents
        .where((element) => element.name.isCaseInsensitiveContains(search))
        .toList();
    filtered = (widget.possibleItems ?? componentNames)
        .where((element) => element.isCaseInsensitiveContains(search))
        .toList();
    filtered.sort((a, b) =>
        (componentOperationCubit.sameComponentCollection[a]?.length ?? 0) <
                (componentOperationCubit.sameComponentCollection[b]?.length ??
                    0)
            ? 1
            : -1);
    globalComponentsList = componentOperationCubit.componentList
        .where(
          (element) =>
              element.name.isCaseInsensitiveContains(search) ||
              (element.description?.isCaseInsensitiveContains(search) ??
                  false) ||
              (element.category?.isCaseInsensitiveContains(search) ?? false) ||
              ComponentSearch.search(search, element.component),
        )
        .toList(growable: false);
  }

  _buildTile(entry) {
    return widget.sideView
        ? CustomDraggable(
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: dragBoxShadow,
                ),
                width: 180,
                height: 35,
                child: BasicComponentTile(
                  selectedIndex,
                  entry,
                  componentOperationCubit,
                  onSelected: onSelected,
                  sideView: widget.sideView,
                  onSelection: widget.onSelection,
                ),
              ),
            ),
            data: entry.value is CustomComponent
                ? (entry.value as CustomComponent).name
                : entry.value,
            child: BasicComponentTile(
              selectedIndex,
              entry,
              componentOperationCubit,
              onSelected: onSelected,
              sideView: widget.sideView,
              onSelection: widget.onSelection,
            ),
          )
        : BasicComponentTile(
            selectedIndex,
            entry,
            onSelected: onSelected,
            componentOperationCubit,
            sideView: widget.sideView,
            onSelection: widget.onSelection,
          );
  }

  void onSelected(MapEntry<int, dynamic> entry) {
    if (entry.value is CustomComponent) {
      final component = entry.value as CustomComponent;
      final customComponentClone = component.createInstance(null);
      print('objects length ${component.objects.length}');
      widget.onSelection?.call(customComponentClone);
    } else {
      final component = componentList[entry.value]!();
      component.onFreshAdded();
      componentOperationCubit.addInSameComponentList(component);
      widget.onSelection?.call(component);
    }
  }

  Widget _buildItem(List<GlobalComponentModel> list, int i,
      BoxConstraints constraints, Processor processor) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(4),
          width: constraints.maxWidth > kSelectionDialogWidth
              ? kSelectionDialogWidth
              : null,
          child: CustomDraggable(
            onDragCompleted: () {
              search = '';
              _controller.clear();
            },
            data: FavouriteModel(
              list[i].component,
              list[i].customs,
              null,
              userId: list[i].publisherId,
            ),
            feedback: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Opacity(
                  opacity: 0.8,
                  child: ComponentViewer(
                    outerWidth:
                        constraints.maxWidth < 150 ? constraints.maxWidth : 150,
                    width: list[i].width,
                    height: list[i].height,
                    processor: processor,
                    child: (context) => list[i].component.build(context),
                  ),
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.background1,
                  boxShadow: kElevationToShadow[1]),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ComponentViewer(
                    width: list[i].width,
                    height: list[i].height,
                    processor: processor,
                    child: (context) => list[i].component.build(context),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list[i].name,
                        style: AppFontStyle.lato(
                          13,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (list[i].description != null) ...[
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          list[i].description!,
                          style: AppFontStyle.lato(
                            12,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: EditIconButton(
                  onPressed: () {
                    showGlobalComponentDialog(context,
                        id: list[i].id, model: list[i]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: DeleteIconButton(
                  onPressed: () {
                    showConfirmDialog(
                        title: 'Remove Component',
                        subtitle:
                            'Are you sure you want to remove this component?',
                        context: context,
                        onPositiveTap: () {
                          componentOperationCubit
                              .removeGlobalComponent(list[i].id!);
                        },
                        positive: 'Yes',
                        negative: 'No');
                  },
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

void showGlobalComponentDialog(BuildContext context,
    {String? id, GlobalComponentModel? model}) {
  String? name = model?.name ?? '',
      description = model?.description,
      category = model?.category,
      code =
          model?.component != null ? jsonEncode(model!.component.toJson()) : '';
  double? width = model?.width?.toDouble(), height = model?.height?.toDouble();
  final ValueNotifier<bool> custom = ValueNotifier(model?.isCustom ?? false);
  AnimatedDialog.show(
      context,
      Container(
        width: 400,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Global Component',
                  style: AppFontStyle.headerStyle(),
                ),
                const AppCloseButton()
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            CommonTextField(
              initial: name,
              border: true,
              onChanged: (value) {
                name = value;
              },
              hintText: 'name',
            ),
            const SizedBox(
              height: 15,
            ),
            CommonTextField(
              border: true,
              initial: description,
              onChanged: (value) {
                description = value;
              },
              hintText: 'description',
            ),
            const SizedBox(
              height: 15,
            ),
            CommonTextField(
              border: true,
              initial: category,
              onChanged: (value) {
                category = value;
              },
              hintText: 'category',
            ),
            const SizedBox(
              height: 15,
            ),
            CommonTextField(
              maxLines: 1,
              initial: code,
              border: true,
              onChanged: (value) {
                code = value;
              },
              hintText: 'code',
            ),
            const SizedBox(
              height: 15,
            ),
            CommonTextField(
              border: true,
              initial: width?.toString() ?? '',
              onChanged: (value) {
                width = double.tryParse(value);
              },
              hintText: 'width',
            ),
            const SizedBox(
              height: 15,
            ),
            CommonTextField(
              border: true,
              initial: height?.toString() ?? '',
              onChanged: (value) {
                height = double.tryParse(value);
              },
              hintText: 'height',
            ),
            const SizedBox(
              height: 15,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'custom',
                  style: AppFontStyle.lato(14),
                ),
                const SizedBox(
                  width: 10,
                ),
                ValueListenableBuilder(
                    valueListenable: custom,
                    builder: (context, bool v, _) {
                      return AppSwitch(
                          value: v,
                          onToggle: (value) {
                            custom.value = value;
                          });
                    }),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            AppButton(
              isEnabled: true,
              width: double.infinity,
              title: 'Submit',
              onPressed: () {
                if (name != null && code != null) {
                  context.read<OperationCubit>().addGlobalComponent(
                      GlobalComponentModel(
                        name: name!,
                        description: (description?.isNotEmpty ?? false)
                            ? description!
                            : null,
                        category:
                            (category?.isNotEmpty ?? false) ? category! : null,
                        code: code!,
                        customs: [],
                        publisherId: 'fvb',
                        publisherName: '',
                        width: width,
                        height: height,
                      ),
                      id: id);
                  AnimatedDialog.hide(context);
                }
              },
            )
          ],
        ),
      ));
}

class SameComponent {
  final Component component;

  SameComponent(this.component);
}

class FavouriteWidget extends StatefulWidget {
  final FavouriteModel model;
  final bool sideView;
  final void Function(FavouriteModel)? onRemove;
  final void Function(FavouriteModel)? onTap;

  const FavouriteWidget(
    this.model, {
    Key? key,
    required this.sideView,
    this.onRemove,
    this.onTap,
  }) : super(key: key);

  @override
  State<FavouriteWidget> createState() => _FavouriteWidgetState();
}

class _FavouriteWidgetState extends State<FavouriteWidget> {
  @override
  Widget build(BuildContext context) {
    final double width = (widget.model.component.boundary?.width != null &&
            widget.model.component.boundary!.width < 400 &&
            widget.model.component.boundary!.width > 10
        ? widget.model.component.boundary!.width
        : 400);
    final double height = (widget.model.component.boundary?.height != null &&
            widget.model.component.boundary!.height < 400 &&
            widget.model.component.boundary!.height > 10
        ? widget.model.component.boundary!.height
        : 400);
    return RuntimeProvider(
      runtimeMode: RuntimeMode.favorite,
      customComponents: widget.model.components,
      child: Card(
        clipBehavior: Clip.none,
        margin: EdgeInsets.zero,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: InkWell(
                onTap: widget.sideView
                    ? null
                    : () => widget.onTap?.call(widget.model),
                child: IgnorePointer(
                  ignoring: true,
                  child: ComponentViewer(
                    width: width,
                    height: height,
                    processor: systemProcessor,
                    child: (context) => widget.model.component.build(context),
                  ),
                ),
              ),
            ),
            if (widget.onRemove != null)
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => widget.onRemove?.call(widget.model),
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
                ),
              )
          ],
        ),
      ),
    );
  }
}

class BasicComponentTile extends StatelessWidget {
  final int selectedIndex;
  final MapEntry<int, dynamic> entry;
  final OperationCubit componentOperationCubit;
  final bool sideView;
  final void Function(MapEntry<int, dynamic>) onSelected;
  final void Function(Component)? onSelection;

  const BasicComponentTile(
      this.selectedIndex, this.entry, this.componentOperationCubit,
      {Key? key,
      required this.onSelected,
      required this.sideView,
      required this.onSelection})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = entry.value is String
        ? entry.value
        : (entry.value as CustomComponent).name;
    return InkWell(
      onTap: sideView
          ? null
          : () {
              onSelected.call(entry);
              Navigator.pop(context);
            },
      child: Container(
        key: sideView
            ? null
            : (GlobalObjectKey(entry.value is String
                ? entry.value
                : (entry.value as CustomComponent).name)),
        decoration: BoxDecoration(
          color: theme.background1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedIndex == entry.key
                ? ColorAssets.theme
                : ColorAssets.colorD0D5EF,
            width: selectedIndex == entry.key ? 1.5 : 1,
          ),
        ),
        padding:
            EdgeInsets.symmetric(horizontal: 8.0, vertical: sideView ? 8 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (entry.value is String &&
                componentImages.containsKey(entry.value as String)) ...[
              Image.asset(
                Images.componentImages + componentImages[entry.value]! + '.png',
                width: 18,
              ),
              const SizedBox(
                width: 10,
              ),
            ],
            Expanded(
              child: TooltipVisibility(
                visible: name.length > 20,
                child: Tooltip(
                  message: name,
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    style: AppFontStyle.lato(12,
                        color: theme.text1Color, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            // if (componentOperationCubit.sameComponentCollection.containsKey(entry.value) &&
            //     (componentOperationCubit.sameComponentCollection[entry.value]?.isNotEmpty ?? false))
            //   Container(
            //     decoration: const BoxDecoration(color: ColorAssets.theme, shape: BoxShape.circle),
            //     padding: const EdgeInsets.all(4),
            //     child: Text(
            //       componentOperationCubit.sameComponentCollection[entry.value]!.length.toString(),
            //       style: AppFontStyle.lato(11, color: Colors.white),
            //     ),
            //   ),
            if (!sideView &&
                componentOperationCubit.sameComponentCollection
                    .containsKey(entry.value) &&
                (componentOperationCubit
                        .sameComponentCollection[entry.value]?.isNotEmpty ??
                    false))
              CustomPopupMenuBuilderButton(
                title: 'Used ${entry.value} widgets',
                itemBuilder: (context, index) {
                  final int reverseIndex = componentOperationCubit
                          .sameComponentCollection[entry.value]!.length -
                      index -
                      1;
                  return CustomPopupMenuItem<Component>(
                    value: componentOperationCubit
                        .sameComponentCollection[entry.value]![reverseIndex],
                    child: RuntimeProvider(
                      runtimeMode: RuntimeMode.favorite,
                      child: Builder(builder: (context) {
                        return SameWidgetTile(entry, reverseIndex,
                            componentOperationCubit: componentOperationCubit);
                      }),
                    ),
                  );
                },
                onSelected: (final Component value) {
                  onSelection?.call(
                      value.clone(null, deepClone: true, connect: false));
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
    );
  }
}

class SameWidgetTile extends StatelessWidget {
  final OperationCubit componentOperationCubit;
  final MapEntry<int, dynamic> entry;
  final int reverseIndex;
  final bool shrink;

  const SameWidgetTile(
    this.entry,
    this.reverseIndex, {
    Key? key,
    this.shrink = false,
    required this.componentOperationCubit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = componentOperationCubit
            .sameComponentCollection[entry.value]![reverseIndex]
            .boundary
            ?.width ??
        50;
    final height = componentOperationCubit
            .sameComponentCollection[entry.value]![reverseIndex]
            .boundary
            ?.height ??
        50;

    return Container(
      width: shrink ? 100 : kSelectionDialogWidth,
      height: shrink ? 100 : kSelectionDialogWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
            colors: [Color(0xfff2f2f2), Color(0xffd3d3d3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: width > 10 && width < 300 ? width : 300,
          height: height > 10 && height < 300 ? height : 300,
          child: disabledError<Widget>(() => componentOperationCubit
              .sameComponentCollection[entry.value]![reverseIndex]
              .build(context)),
        ),
      ),
    );
  }
}

T? disabledError<T>(T? Function() computation) {
  disableError = true;
  final output = computation.call();
  disableError = false;
  return output;
}
