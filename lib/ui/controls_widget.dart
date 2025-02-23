import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/processor_component.dart';

import '../common/app_button.dart';
import '../common/custom_drop_down.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/drag_target.dart';
import '../common/extension_util.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../models/builder_component.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/global_component.dart';
import '../models/other_model.dart';
import '../riverpod/clipboard.dart';
import '../runtime_provider.dart';
import '../widgets/message/empty_text.dart';
import 'component_selection_dialog.dart';
import 'navigation/animated_dialog.dart';
import 'navigation/animated_slider.dart';

class ClipboardComponentWidget extends StatefulWidget {
  const ClipboardComponentWidget({Key? key}) : super(key: key);

  @override
  State<ClipboardComponentWidget> createState() =>
      _ClipboardComponentWidgetState();
}

class _ClipboardComponentWidgetState extends State<ClipboardComponentWidget> {
  final _controller = ScrollController();
  late final OperationCubit _operationCubit;

  @override
  void initState() {
    _operationCubit = context.read<OperationCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: kElevationToShadow[6],
      ),
      width: 180,
      padding: const EdgeInsets.all(12),
      child: RuntimeProvider(
        runtimeMode: RuntimeMode.favorite,
        child: LayoutBuilder(builder: (context, constraints) {
          return AnimatedBuilder(
              animation: clipboardProvider,
              builder: (context, _) {
                final list = clipboardProvider.data;
                if (list.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    _controller.jumpTo(0);
                  });
                }
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SliderBackButton(),
                        20.wBox,
                        Text(
                          'Clipboard',
                          style: AppFontStyle.titleStyle(),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (list.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.separated(
                          separatorBuilder: (_, i) => const SizedBox(
                            height: 8,
                          ),
                          controller: _controller,
                          shrinkWrap: true,
                          itemBuilder: (_, i) {
                            return Stack(
                              children: [
                                CustomDraggable(
                                    data: FavouriteModel(
                                      list[i].component,
                                      [],
                                      null,
                                      userId: '',
                                    ),
                                    child: AbsorbPointer(
                                      child: ComponentViewer(
                                        width:
                                            list[i].component.boundary?.width,
                                        height:
                                            list[i].component.boundary?.height,
                                        processor: list[i].processor,
                                        child: (context) =>
                                            list[i].component.build(context),
                                      ),
                                    ),
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: ComponentViewer(
                                        outerWidth: constraints.maxWidth - 10,
                                        width:
                                            list[i].component.boundary?.width,
                                        height:
                                            list[i].component.boundary?.height,
                                        processor: list[i].processor,
                                        child: (context) =>
                                            list[i].component.build(context),
                                      ),
                                    )),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: CustomPopupMenuButton(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 0:
                                          list.removeAt(i);
                                          setState(() {});
                                        case 1:
                                          showGlobalComponentDialog(context,
                                              model: GlobalComponentModel(
                                                  name: '',
                                                  customs: [],
                                                  publisherId: _operationCubit
                                                      .project!.userId,
                                                  publisherName: '',
                                                  width: list[i]
                                                      .component
                                                      .boundary
                                                      ?.width,
                                                  height: list[i]
                                                      .component
                                                      .boundary
                                                      ?.height,
                                                  code: jsonEncode(list[i]
                                                      .component
                                                      .toJson())));
                                      }
                                    },
                                    itemBuilder: (BuildContext) => [
                                      const CustomPopupMenuItem(
                                        value: 0,
                                        child: Text('Remove'),
                                      ),
                                      const CustomPopupMenuItem(
                                        value: 1,
                                        child: Text('Make Global Component'),
                                      ),
                                    ],
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: kElevationToShadow[1]),
                                      child: const Icon(
                                        Icons.more_vert_outlined,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                          itemCount: list.length,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: EmptyTextIconWidget(
                          text: 'No copied widgets!',
                          icon: Icons.file_copy,
                        ),
                      ),
                  ],
                );
              });
        }),
      ),
    );
  }
}

class SliderBackButton extends StatelessWidget {
  const SliderBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (AnimatedSliderProvider.of(context) != null) {
          AnimatedSliderProvider.of(context)?.hide();
        } else {
          AnimatedDialog.hide(context);
        }
      },
      child: const Icon(
        Icons.arrow_back,
        size: 20,
      ),
    );
  }
}

class ControlsWidget extends StatefulWidget {
  const ControlsWidget({Key? key}) : super(key: key);

  @override
  State<ControlsWidget> createState() => _ControlsWidgetState();
}

class _ControlsWidgetState extends State<ControlsWidget> {
  final ValueNotifier<bool> expand = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: expand,
        builder: (context, value, _) {
          return Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: () {
                    expand.value = !expand.value;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: kElevationToShadow[1]),
                    child: Icon(
                      value ? Icons.arrow_back_ios : Icons.tune,
                      size: 20,
                    ),
                  ),
                ),
              )
            ],
          );
        });
  }
}

class ControlsView extends StatefulWidget {
  const ControlsView({Key? key}) : super(key: key);

  @override
  State<ControlsView> createState() => _ControlsViewState();
}

class _ControlsViewState extends State<ControlsView> {
  late SelectionCubit _selectionCubit;

  @override
  void initState() {
    _selectionCubit = context.read<SelectionCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreationCubit, CreationState>(builder: (context, state) {
      final List<Controller> list = [];
      _selectionCubit.selected.viewable?.rootComponent?.forEach((p0) {
        if (p0 is Controller) {
          list.add(p0 as Controller);
        }
        return false;
      });
      return DropdownButtonHideUnderline(
        child: ListView.separated(
          itemBuilder: (context, i) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (list[i] as Component).name,
                  style: AppFontStyle.lato(13,
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                ControllerListingWidget(controller: list[i]),
              ],
            );
          },
          itemCount: list.length,
          separatorBuilder: (BuildContext context, int index) => const SizedBox(
            height: 15,
          ),
        ),
      );
    });
  }
}

class ControllerListingWidget extends StatefulWidget {
  final Controller controller;

  const ControllerListingWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<ControllerListingWidget> createState() =>
      _ControllerListingWidgetState();
}

class _ControllerListingWidgetState extends State<ControllerListingWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, j) {
        return Container(
            height: 30,
            child: Row(
              children: [
                Text(
                  widget.controller.list[j].name,
                  style: AppFontStyle.lato(13,
                      color: Colors.black, fontWeight: FontWeight.w500),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Builder(builder: (context) {
                    final model = widget.controller.list[j];
                    if (model is SelectionControl) {
                      final values = model.values();
                      return CustomDropdownButton<String>(
                        hint: Text(
                          'page',
                          style: AppFontStyle.lato(13),
                        ),
                        style: AppFontStyle.lato(13),
                        value: model.value.call(),
                        selectedItemBuilder: (context, e) => Text(
                          e,
                          style: AppFontStyle.lato(13,
                              fontWeight: FontWeight.w600),
                        ),
                        items: values
                            .map((e) => CustomDropdownMenuItem<String>(
                                value: e,
                                child: Text(
                                  e,
                                  style: AppFontStyle.lato(
                                    13,
                                  ),
                                )))
                            .toList(growable: false),
                        onChanged: (String? value) {
                          if (value != null) {
                            model.onSelection.call(value);
                          }
                          setState(() {});
                        },
                      );
                    } else if (model is ButtonControl) {
                      return AppButton(
                        fontSize: 13,
                        title: model.buttonName.call(model.value),
                        onPressed: () {
                          model.value = model.onTap.call(model.value);
                          setState(() {});
                        },
                      );
                    }
                    return const Offstage();
                  }),
                )
              ],
            ));
      },
      separatorBuilder: (context, _) {
        return const Divider();
      },
      itemCount: widget.controller.list.length,
      shrinkWrap: true,
    );
  }
}

class ComponentViewer extends StatelessWidget {
  final Widget Function(BuildContext) child;
  final num? width;
  final double? outerWidth;
  final num? height;
  final Processor processor;

  const ComponentViewer(
      {Key? key,
      required this.child,
      required this.width,
      required this.height,
      required this.processor,
      this.outerWidth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ProcessorProvider(
        processor: processor,
        child: RuntimeProvider(
          runtimeMode: RuntimeMode.favorite,
          child: Container(
            width: outerWidth ?? double.infinity,
            height: height == null ? 200 : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: kElevationToShadow[5],
              color: Colors.grey.shade100,
            ),
            padding: const EdgeInsets.all(8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width == 0 ? 50 : (width?.toDouble() ?? 200),
                height: height == 0 ? 50 : (height?.toDouble() ?? 200),
                child: Builder(builder: (context) {
                  return child.call(context);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
