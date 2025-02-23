import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'project/project_selection_page.dart';
import 'package:fvb_processor/compiler/code_processor.dart';

import '../bloc/action_code/action_code_bloc.dart';
import '../common/custom_drop_down.dart';
import '../common/custom_extension_tile.dart';
import '../common/custom_text_field.dart';
import '../common/dynamic_value_editing_controller.dart';
import '../common/extension_util.dart';
import '../common/responsive/responsive_widget.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/action_edit/action_edit_cubit.dart';
import '../cubit/click_action/click_action_cubit.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../injector.dart';
import '../models/actions/action_model.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/project_model.dart';
import '../widgets/button/app_close_button.dart';
import 'component_tree/component_tree.dart';
import 'fvb_code_editor.dart';
import 'navigation/animated_dialog.dart';
import 'parameter_ui.dart';

final Map<String, ActionSetting> _map = {};

class ActionSetting {
  bool expanded = true;
}

class ActionModelWidget extends StatefulWidget {
  final Clickable clickable;

  const ActionModelWidget({Key? key, required this.clickable})
      : super(key: key);

  @override
  State<ActionModelWidget> createState() => _ActionModelWidgetState();
}

class _ActionModelWidgetState extends State<ActionModelWidget> {
  final _clickActionCubit = ClickActionCubit();
  late ActionSetting setting;

  @override
  void initState() {
    final id = (widget.clickable as Component).id;
    if (_map.containsKey(id)) {
      setting = _map[id]!;
    } else {
      setting = ActionSetting();
      _map[id] = setting;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: BlocProvider<ClickActionCubit>(
        create: (context) => _clickActionCubit,
        child: CustomExpansionTile(
          backgroundColor: ColorAssets.shimmerColor,
          initiallyExpanded: setting.expanded,
          onExpansionChanged: (value) {
            setting.expanded = value;
          },
          collapsedBackgroundColor: ColorAssets.shimmerColor,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(
              'Code',
              style: AppFontStyle.lato(16, fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            ColoredBox(
              color: theme.background1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  8.hBox,
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.end,
                  //   crossAxisAlignment: CrossAxisAlignment.center,
                  //   children: [
                  //
                  //     // const SizedBox(
                  //     //   width: 10,
                  //     // ),
                  //     // CustomPopupMenuButton(
                  //     //   itemBuilder: (context) => [
                  //     //     'CustomAction',
                  //     //     'NewPageInStackAction',
                  //     //     'ReplaceCurrentPageInStackAction',
                  //     //     'GoBackInStackAction',
                  //     //     'ShowDialogInStackAction',
                  //     //     'ShowCustomDialogInStackAction',
                  //     //     'ShowBottomSheetInStackAction',
                  //     //     // 'HideBottomSheetInStackAction',
                  //     //     'ShowSnackBarAction'
                  //     //   ]
                  //     //       .map(
                  //     //         (e) => CustomPopupMenuItem<String>(
                  //     //           value: e,
                  //     //           child: Text(
                  //     //             e,
                  //     //             style: AppFontStyle.roboto(13,
                  //     //                 fontWeight: FontWeight.w600),
                  //     //           ),
                  //     //         ),
                  //     //       )
                  //     //       .toList(growable: false),
                  //     //   onSelected: (value) {
                  //     //     switch (value) {
                  //     //       case 'CustomAction':
                  //     //         widget.clickable.actionList.add(CustomAction(
                  //     //             code: widget.clickable.defaultCode));
                  //     //
                  //     //         break;
                  //     //       case 'NewPageInStackAction':
                  //     //         widget.clickable.actionList
                  //     //             .add(NewPageInStackAction(null));
                  //     //
                  //     //         break;
                  //     //       case 'ReplaceCurrentPageInStackAction':
                  //     //         widget.clickable.actionList
                  //     //             .add(ReplaceCurrentPageInStackAction(null));
                  //     //
                  //     //         break;
                  //     //       case 'GoBackInStackAction':
                  //     //         widget.clickable.actionList.add(GoBackInStackAction());
                  //     //
                  //     //         break;
                  //     //       case 'ShowDialogInStackAction':
                  //     //         widget.clickable.actionList
                  //     //             .add(ShowDialogInStackAction());
                  //     //         break;
                  //     //       case 'ShowCustomDialogInStackAction':
                  //     //         widget.clickable.actionList
                  //     //             .add(ShowCustomDialogInStackAction());
                  //     //         break;
                  //     //       case 'ShowBottomSheetInStackAction':
                  //     //         widget.clickable.actionList
                  //     //             .add(ShowBottomSheetInStackAction(null));
                  //     //         break;
                  //     //       case 'ShowSnackBarAction':
                  //     //         widget.clickable.actionList.add(ShowSnackBarAction());
                  //     //         break;
                  //     //       // case 'HideBottomSheetInStackAction':
                  //     //       //   widget.component.actionList
                  //     //       //       .add(HideBottomSheetInStackAction());
                  //     //       //   break;
                  //     //     }
                  //     //
                  //     //     _clickActionCubit.changedState();
                  //     //     BlocProvider.of<ActionEditCubit>(context).change();
                  //     //   },
                  //     //   child: const Padding(
                  //     //     padding: EdgeInsets.all(10),
                  //     //     child: Icon(
                  //     //       Icons.add,
                  //     //       color: Colors.blueAccent,
                  //     //     ),
                  //     //   ),
                  //     // )
                  //   ],
                  // ),
                  if (widget.clickable.actionList.isEmpty) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      'No actions',
                      style: AppFontStyle.lato(
                        14,
                        color: theme.text3Color,
                      ),
                    ),
                  ],
                  BlocConsumer<ClickActionCubit, ClickActionState>(
                    bloc: _clickActionCubit,
                    listener: (context, state) {},
                    builder: (context, state) {
                      return Column(
                        children: [
                          for (final action in widget.clickable.actionList) ...[
                            ActionModelUIWidget(
                                clickableHolder: widget.clickable,
                                actionModel: action),
                            const SizedBox(
                              height: 10,
                            ),
                          ]
                        ],
                      );
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ActionModelUIWidget extends StatelessWidget {
  final Clickable clickableHolder;
  final ActionModel actionModel;
  final bool dialog;
  final int? selection;

  const ActionModelUIWidget(
      {Key? key,
      required this.clickableHolder,
      required this.actionModel,
      this.dialog = false,
      this.selection})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (actionModel.runtimeType) {
      case CustomAction:
        return CustomActionWidget(
          clickableHolder: clickableHolder,
          action: actionModel as CustomAction,
          dialog: dialog,
          key: ValueKey(actionModel.arguments[0]),
        );
      case NewPageInStackAction:
        return NewPageInStackActionWidget(
            clickableHolder: clickableHolder,
            action: actionModel as NewPageInStackAction);
      case ReplaceCurrentPageInStackAction:
        return ReplaceCurrentPageInStackActionWidget(
            clickableHolder: clickableHolder,
            action: actionModel as ReplaceCurrentPageInStackAction);
      case GoBackInStackAction:
        return GoBackInStackActionWidget(
            clickableHolder: clickableHolder,
            action: actionModel as GoBackInStackAction);
      // case HideBottomSheetInStackAction:
      //   return HideBottomSheetInStackActionWidget(
      //       clickableHolder: clickableHolder,
      //       action: actionModel as HideBottomSheetInStackAction);
      case ShowDialogInStackAction:
        return ShowDialogInStackActionWidget(
          action: actionModel as ShowDialogInStackAction,
          clickableHolder: clickableHolder,
        );
      case ShowCustomDialogInStackAction:
        return ShowCustomDialogInStackActionWidget(
          action: actionModel as ShowCustomDialogInStackAction,
          clickableHolder: clickableHolder,
        );
      case ShowBottomSheetInStackAction:
        return ShowBottomSheetInStackActionWidget(
            clickableHolder: clickableHolder,
            action: actionModel as ShowBottomSheetInStackAction);
      case ShowSnackBarAction:
        return ShowSnackBarActionWidget(
            clickableHolder: clickableHolder,
            action: actionModel as ShowSnackBarAction);
      default:
        return Container();
    }
  }
}

class NewPageInStackActionWidget extends StatelessWidget {
  final Clickable clickableHolder;
  final NewPageInStackAction action;

  const NewPageInStackActionWidget(
      {Key? key, required this.clickableHolder, required this.action})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Text(
            'New Screen',
            style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(child: BlocBuilder<OperationCubit, OperationState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: CustomDropdownButton<Screen>(
                            style: AppFontStyle.lato(13),
                            value: (action.arguments[0] as Screen?),
                            hint: Text(
                              'Choose Screen',
                              style: AppFontStyle.lato(14,
                                  fontWeight: FontWeight.w500),
                            ),
                            items: BlocProvider.of<OperationCubit>(context,
                                    listen: false)
                                .project!
                                .screens
                                .map<CustomDropdownMenuItem<Screen>>(
                                  (e) => CustomDropdownMenuItem<Screen>(
                                    value: e,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        height: 25,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Text(
                                            e.name,
                                            style: AppFontStyle.lato(13,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != (action.arguments[0] as Screen?)) {
                                action.arguments[0] = value;
                                BlocProvider.of<ClickActionCubit>(context,
                                        listen: false)
                                    .changedState();

                                BlocProvider.of<ActionEditCubit>(context,
                                        listen: false)
                                    .change();
                              }
                            },
                            selectedItemBuilder: (context, config) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  config.name,
                                  style: AppFontStyle.lato(13,
                                      fontWeight: FontWeight.w500),
                                ),
                              );
                            }),
                      ),
                    ),
                  ],
                ),
              );
            },
          )),
        ],
      ),
    );
  }
}

class CustomActionWidget extends StatefulWidget {
  final Clickable clickableHolder;
  final CustomAction action;
  final bool dialog;
  final int? selection;

  const CustomActionWidget({
    Key? key,
    required this.clickableHolder,
    required this.action,
    required this.dialog,
    this.selection,
  }) : super(key: key);

  @override
  State<CustomActionWidget> createState() => _CustomActionWidgetState();
}

class _CustomActionWidgetState extends State<CustomActionWidget>
    with GetProcessor {
  final DynamicValueEditingController _controller =
      DynamicValueEditingController();
  late Component root;
  bool error = false;
  late Processor processor;
  final Debounce _debounce = Debounce(const Duration(milliseconds: 500));
  late ActionEditCubit _actionEditCubit;

  @override
  void initState() {
    super.initState();
    _actionEditCubit = context.read<ActionEditCubit>();
    _controller.text = widget.action.arguments[0];
    final _cubit = context.read<SelectionCubit>();
    root = _cubit.currentSelectedRoot;
    processor = needfulProcessor(_cubit);
  }

  @override
  void dispose() {
    _debounce.timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomActionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction:
          Responsive.isDesktop(context) ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   'Custom Action',
        //   style: AppFontStyle.roboto(14, fontWeight: FontWeighconst t.w500),
        // ),
        if (widget.dialog)
          const SizedBox(
            height: 10,
          ),
        Wrap(
          children: [
            for (final function in widget.clickableHolder.functions
                .where((element) => element.arguments.isEmpty))
              Container(
                decoration: BoxDecoration(
                  color: theme.background3,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      function.name,
                      style: AppFontStyle.lato(13,
                          color: theme.text3Color, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    RoundedAppIconButton(
                      iconSize: 14,
                      buttonSize: 22,
                      icon: Icons.play_arrow_rounded,
                      onPressed: () {
                        widget.clickableHolder.performCustomAction(
                          context,
                          widget.action,
                          [],
                          name: function.name,
                          processor: processor,
                        );
                      },
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (Responsive.isDesktop(context)) ...[
          const SizedBox(
            height: 10,
          ),
          Expanded(
            flex: widget.dialog ? 1 : 0,
            child: SizedBox(
              height: widget.dialog ? null : 300,
              child: BlocBuilder<ActionCodeBloc, ActionCodeState>(
                builder: (context, state) {
                  return FVBCodeEditor(
                    processor: processor,
                    headerEnd: widget.dialog
                        ? null
                        : InkWell(
                            onTap: () {
                              if (!widget.dialog) {
                                AnimatedDialog.show(
                                  context,
                                  Dialog(
                                    child: MultiBlocProvider(
                                      providers: [
                                        BlocProvider.value(
                                          value:
                                              context.read<ClickActionCubit>(),
                                        ),
                                        BlocProvider.value(
                                          value: _actionEditCubit,
                                        ),
                                        BlocProvider.value(
                                          value: sl<ActionCodeBloc>(),
                                        ),
                                      ],
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Code',
                                                  style: AppFontStyle
                                                      .headerStyle(),
                                                ),
                                                const AppCloseButton(),
                                              ],
                                            ),
                                            Expanded(
                                              child: ActionModelUIWidget(
                                                clickableHolder:
                                                    widget.clickableHolder,
                                                actionModel: widget.action,
                                                dialog: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ).then((value) {
                                  _actionEditCubit.change();
                                });
                              } else {
                                AnimatedDialog.hide(context);
                              }
                            },
                            child: const Icon(Icons.fullscreen),
                          ),

                    code: widget.action.arguments[0],
                    onCodeChange: (String value, refresh) {
                      widget.action.arguments[0] = value;
                      _debounce.run(() {
                        _actionEditCubit.change();
                      });
                      //   context.read<ClickActionCubit>()
                      //       .changedState();
                      // }
                    },
                    //ComponentOperationCubit
                    //                       .currentProject!.variables.values
                    //                       .toList()
                    onErrorUpdate: (message, bool error) {
                      context.read<SelectionCubit>().updateError(
                            widget.clickableHolder as Component,
                            message,
                            AnalysisErrorType.code,
                            action: widget.action,
                          );
                    },
                    config: FVBEditorConfig(
                        parentProcessorGiven: true,
                        shrink: true,
                        smallBottomBar: true,
                        onReset: () => (widget.clickableHolder.defaultCode)),
                  );
                },
              ),
            ),
          )
        ] else ...[
          const Spacer(),
          CustomActionCodeButton(
              size: 14,
              margin: 5,
              code: () => widget.action.arguments[0],
              title: (widget.clickableHolder as Component).name,
              onChanged: (String value, refresh) {
                widget.action.arguments[0] = value;
                BlocProvider.of<ClickActionCubit>(context).changedState();
                _actionEditCubit.change();
              },
              processor: processor,
              onDismiss: () {},
              config: FVBEditorConfig(parentProcessorGiven: true))
        ]
      ],
    );
  }
}

class ReplaceCurrentPageInStackActionWidget extends StatelessWidget {
  final Clickable clickableHolder;
  final ReplaceCurrentPageInStackAction action;

  const ReplaceCurrentPageInStackActionWidget(
      {Key? key, required this.clickableHolder, required this.action})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _actionEditCubit = context.read<ActionEditCubit>();
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Text(
            'Replacement Screen',
            style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(child: BlocBuilder<OperationCubit, OperationState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: CustomDropdownButton<Screen>(
                            style: AppFontStyle.lato(13),
                            value: (action.arguments[0] as Screen?),
                            hint: Text(
                              'Choose Screen',
                              style: AppFontStyle.lato(14,
                                  fontWeight: FontWeight.w500),
                            ),
                            items: BlocProvider.of<OperationCubit>(context,
                                    listen: false)
                                .project!
                                .screens
                                .map<CustomDropdownMenuItem<Screen>>(
                                  (e) => CustomDropdownMenuItem<Screen>(
                                    value: e,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          e.name,
                                          style: AppFontStyle.lato(13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != (action.arguments[0] as Screen?)) {
                                action.arguments[0] = value;
                                BlocProvider.of<ClickActionCubit>(context,
                                        listen: false)
                                    .changedState();

                                _actionEditCubit.change();
                              }
                            },
                            selectedItemBuilder: (context, config) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  config.name,
                                  style: AppFontStyle.lato(13,
                                      fontWeight: FontWeight.w500),
                                ),
                              );
                            }),
                      ),
                    ),
                  ],
                ),
              );
            },
          )),
        ],
      ),
    );
  }
}

class GoBackInStackActionWidget extends StatelessWidget {
  final Clickable clickableHolder;
  final GoBackInStackAction action;

  const GoBackInStackActionWidget(
      {Key? key, required this.clickableHolder, required this.action})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Text(
            'Go Back',
            style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 20,
          ),
        ],
      ),
    );
  }
}
//
// class HideBottomSheetInStackActionWidget extends StatelessWidget {
//   final Clickable clickableHolder;
//   final HideBottomSheetInStackAction action;
//
//   const HideBottomSheetInStackActionWidget(
//       {Key? key, required this.clickableHolder, required this.action})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(10),
//       child: Row(
//         children: [
//           Text(
//             'Hide BottomSheet',
//             style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
//           ),
//           const SizedBox(
//             width: 20,
//           ),
//         ],
//       ),
//     );
//   }
// }

class ShowDialogInStackActionWidget extends StatelessWidget {
  final Clickable clickableHolder;
  final ShowDialogInStackAction action;

  const ShowDialogInStackActionWidget(
      {Key? key, required this.clickableHolder, required this.action})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _actionEditCubit = context.read<ActionEditCubit>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dialog Properties',
              style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Title',
                  style: AppFontStyle.lato(13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: CustomTextField(
                  controller: TextEditingController.fromValue(
                      TextEditingValue(text: action.arguments[0] ?? '')),
                  onChange: (data) {
                    action.arguments[0] = data;
                    _actionEditCubit.change();
                  },
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Subtitle',
                  style: AppFontStyle.lato(13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: CustomTextField(
                  controller: TextEditingController.fromValue(
                      TextEditingValue(text: action.arguments[1] ?? '')),
                  onChange: (data) {
                    action.arguments[1] = data;
                    _actionEditCubit.change();
                  },
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Positive Button Text',
                  style: AppFontStyle.lato(13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: CustomTextField(
                  controller: TextEditingController.fromValue(
                      TextEditingValue(text: action.arguments[2] ?? '')),
                  onChange: (data) {
                    action.arguments[2] = data;
                    _actionEditCubit.change();
                  },
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Negative Button Text',
                  style: AppFontStyle.lato(13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: CustomTextField(
                  controller: TextEditingController.fromValue(
                      TextEditingValue(text: action.arguments[3] ?? '')),
                  onChange: (data) {
                    action.arguments[3] = data;
                    _actionEditCubit.change();
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class ShowCustomDialogInStackActionWidget extends StatelessWidget {
  final Clickable clickableHolder;
  final ShowCustomDialogInStackAction action;

  const ShowCustomDialogInStackActionWidget(
      {Key? key, required this.clickableHolder, required this.action})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _actionEditCubit = context.read<ActionEditCubit>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dialog',
              style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text(
                'Screen',
                style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(child: BlocBuilder<OperationCubit, OperationState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: CustomDropdownButton<Screen>(
                                style: AppFontStyle.lato(13),
                                value: (action.arguments[0] as Screen?),
                                hint: Text(
                                  'Choose Screen',
                                  style: AppFontStyle.lato(14,
                                      fontWeight: FontWeight.w500),
                                ),
                                items: BlocProvider.of<OperationCubit>(context,
                                        listen: false)
                                    .project!
                                    .screens
                                    .map<CustomDropdownMenuItem<Screen>>(
                                      (e) => CustomDropdownMenuItem<Screen>(
                                        value: e,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                            height: 25,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Text(
                                                e.name,
                                                style: AppFontStyle.lato(13,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value !=
                                      (action.arguments[0] as Screen?)) {
                                    action.arguments[0] = value;
                                    BlocProvider.of<ClickActionCubit>(context,
                                            listen: false)
                                        .changedState();

                                    _actionEditCubit.change();
                                  }
                                },
                                selectedItemBuilder: (context, config) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      config.name,
                                      style: AppFontStyle.lato(13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )),
            ],
          )
        ],
      ),
    );
  }
}

class ShowBottomSheetInStackActionWidget extends StatelessWidget {
  final Clickable clickableHolder;
  final ShowBottomSheetInStackAction action;

  const ShowBottomSheetInStackActionWidget(
      {Key? key, required this.clickableHolder, required this.action})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _actionEditCubit = context.read<ActionEditCubit>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Bottom Sheet',
              style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text(
                'Screen',
                style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(child: BlocBuilder<OperationCubit, OperationState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: CustomDropdownButton<Screen>(
                                style: AppFontStyle.lato(13),
                                value: (action.arguments[0] as Screen?),
                                hint: Text(
                                  'Choose Screen',
                                  style: AppFontStyle.lato(14,
                                      fontWeight: FontWeight.w500),
                                ),
                                items: BlocProvider.of<OperationCubit>(context,
                                        listen: false)
                                    .project!
                                    .screens
                                    .map<CustomDropdownMenuItem<Screen>>(
                                      (e) => CustomDropdownMenuItem<Screen>(
                                        value: e,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                            height: 25,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Text(
                                                e.name,
                                                style: AppFontStyle.lato(13,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value !=
                                      (action.arguments[0] as Screen?)) {
                                    action.arguments[0] = value;
                                    BlocProvider.of<ClickActionCubit>(context,
                                            listen: false)
                                        .changedState();

                                    _actionEditCubit.change();
                                  }
                                },
                                selectedItemBuilder: (context, config) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      config.name,
                                      style: AppFontStyle.lato(13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )),
            ],
          ),
          ParameterWidget(
            parameter: action.arguments[1],
          )
        ],
      ),
    );
  }
}

class ShowSnackBarActionWidget extends StatelessWidget {
  final Clickable clickableHolder;
  final ShowSnackBarAction action;

  const ShowSnackBarActionWidget(
      {Key? key, required this.clickableHolder, required this.action})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SnackBar',
              style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          ParameterWidget(
            parameter: action.arguments[0],
          ),
          const SizedBox(
            height: 10,
          ),
          ParameterWidget(
            parameter: action.arguments[1],
          )
        ],
      ),
    );
  }
}
