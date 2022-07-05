import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/action_code/action_code_bloc.dart';
import '../bloc/error/error_bloc.dart';
import '../common/app_text_field.dart';
import '../common/custom_drop_down.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/custom_text_field.dart';
import '../common/dynamic_value_editing_controller.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/action_edit/action_edit_cubit.dart';
import '../cubit/click_action/click_action_cubit.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../models/actions/action_model.dart';
import '../models/component_model.dart';
import '../models/project_model.dart';
import 'action_code_editor.dart';
import 'common/badge_widget.dart';
import 'parameter_ui.dart';

class ActionModelWidget extends StatefulWidget {
  final Clickable clickable;

  const ActionModelWidget({Key? key, required this.clickable})
      : super(key: key);

  @override
  State<ActionModelWidget> createState() => _ActionModelWidgetState();
}

class _ActionModelWidgetState extends State<ActionModelWidget> {
  final _clickActionCubit = ClickActionCubit();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClickActionCubit>(
      create: (context) => _clickActionCubit,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Actions',
                  style: AppFontStyle.roboto(16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  width: 10,
                ),
                CustomPopupMenuButton(
                  itemBuilder: (context) => [
                    'CustomAction',
                    'NewPageInStackAction',
                    'ReplaceCurrentPageInStackAction',
                    'GoBackInStackAction',
                    'ShowDialogInStackAction',
                    'ShowCustomDialogInStackAction',
                    'ShowBottomSheetInStackAction',
                    // 'HideBottomSheetInStackAction',
                    'ShowSnackBarAction'
                  ]
                      .map(
                        (e) => CustomPopupMenuItem<String>(
                          value: e,
                          child: Text(
                            e,
                            style: AppFontStyle.roboto(13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onSelected: (value) {
                    switch (value) {
                      case 'CustomAction':
                        widget.clickable.actionList.add(CustomAction(
                            code: widget.clickable.getDefaultCode()));

                        break;
                      case 'NewPageInStackAction':
                        widget.clickable.actionList
                            .add(NewPageInStackAction(null));

                        break;
                      case 'ReplaceCurrentPageInStackAction':
                        widget.clickable.actionList
                            .add(ReplaceCurrentPageInStackAction(null));

                        break;
                      case 'GoBackInStackAction':
                        widget.clickable.actionList.add(GoBackInStackAction());

                        break;
                      case 'ShowDialogInStackAction':
                        widget.clickable.actionList
                            .add(ShowDialogInStackAction());
                        break;
                      case 'ShowCustomDialogInStackAction':
                        widget.clickable.actionList
                            .add(ShowCustomDialogInStackAction());
                        break;
                      case 'ShowBottomSheetInStackAction':
                        widget.clickable.actionList
                            .add(ShowBottomSheetInStackAction(null));
                        break;
                      case 'ShowSnackBarAction':
                        widget.clickable.actionList.add(ShowSnackBarAction());
                        break;
                      // case 'HideBottomSheetInStackAction':
                      //   widget.component.actionList
                      //       .add(HideBottomSheetInStackAction());
                      //   break;
                    }

                    _clickActionCubit.changedState();
                    BlocProvider.of<ActionEditCubit>(context).change();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.add,
                      color: Colors.blueAccent,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            BlocConsumer<ClickActionCubit, ClickActionState>(
              bloc: _clickActionCubit,
              listener: (context, state) {},
              builder: (context, state) {
                return Column(
                  children: [
                    for (final action in widget.clickable.actionList)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              child: ActionModelUIWidget(
                                  clickableHolder: widget.clickable,
                                  actionModel: action),
                              decoration: BoxDecoration(
                                  color: AppColors.msgColor,
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              widget.clickable.actionList.remove(action);
                              _clickActionCubit.changedState();

                              BlocProvider.of<ActionEditCubit>(context,
                                      listen: false)
                                  .change();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ),
                          )
                        ],
                      ),
                  ],
                );
              },
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

  const ActionModelUIWidget(
      {Key? key, required this.clickableHolder, required this.actionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (actionModel.runtimeType) {
      case CustomAction:
        return CustomActionWidget(
            clickableHolder: clickableHolder,
            action: actionModel as CustomAction);
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
            style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(child:
              BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: CustomDropdownButton<UIScreen>(
                            style: AppFontStyle.roboto(13),
                            value: (action.arguments[0] as UIScreen?),
                            hint: Text(
                              'Choose Screen',
                              style: AppFontStyle.roboto(14,
                                  fontWeight: FontWeight.w500),
                            ),
                            items: BlocProvider.of<ComponentOperationCubit>(
                                    context,
                                    listen: false)
                                .project!
                                .uiScreens
                                .map<CustomDropdownMenuItem<UIScreen>>(
                                  (e) => CustomDropdownMenuItem<UIScreen>(
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
                                            style: AppFontStyle.roboto(13,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != (action.arguments[0] as UIScreen?)) {
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
                                  style: AppFontStyle.roboto(13,
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

  const CustomActionWidget(
      {Key? key, required this.clickableHolder, required this.action})
      : super(key: key);

  @override
  State<CustomActionWidget> createState() => _CustomActionWidgetState();
}

class _CustomActionWidgetState extends State<CustomActionWidget> {
  final DynamicValueEditingController _controller =
      DynamicValueEditingController();
  late Component root;
  bool error = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.action.arguments[0];
    root = context.read<ComponentSelectionCubit>().currentSelectedRoot;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            'Custom Action',
            style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 400,
            child: oiBlocBuilder<ActionCodeBloc, ActionCodeState>(
              builder: (context, state) {
                final extraCodeBase = (root is CustomComponent)
                    ? CodeBase((root as CustomComponent).actionCode,
                        (root as CustomComponent).processor.scopeName)
                    : CodeBase(
                        ComponentOperationCubit
                            .currentProject!.currentScreen.actionCode,
                        ComponentOperationCubit
                            .currentProject!.currentScreen.processor.scopeName);
                return ActionCodeEditor(
                  functions: (root is! StatelessComponent)?[setStateFunction]:[],
                  prerequisites: [
                    CodeBase(
                        ComponentOperationCubit.currentProject!.actionCode,
                        ComponentOperationCubit
                            .currentProject!.processor.scopeName),
                    extraCodeBase
                  ],
                  code: widget.action.arguments[0],
                  onCodeChange: (String value) {
                    widget.action.arguments[0] = value;
                    BlocProvider.of<ClickActionCubit>(context).changedState();

                    BlocProvider.of<ActionEditCubit>(context).change();
                  },
                  //ComponentOperationCubit
                  //                       .currentProject!.variables.values
                  //                       .toList()
                  variables: [],
                  onError: (bool error) {},
                  scopeName: extraCodeBase.scopeName,
                );
              },
            ),
          )
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Text(
            'Replacement Screen',
            style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(child:
              BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: CustomDropdownButton<UIScreen>(
                            style: AppFontStyle.roboto(13),
                            value: (action.arguments[0] as UIScreen?),
                            hint: Text(
                              'Choose Screen',
                              style: AppFontStyle.roboto(14,
                                  fontWeight: FontWeight.w500),
                            ),
                            items: BlocProvider.of<ComponentOperationCubit>(
                                    context,
                                    listen: false)
                                .project!
                                .uiScreens
                                .map<CustomDropdownMenuItem<UIScreen>>(
                                  (e) => CustomDropdownMenuItem<UIScreen>(
                                    value: e,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          e.name,
                                          style: AppFontStyle.roboto(13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != (action.arguments[0] as UIScreen?)) {
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
                                  style: AppFontStyle.roboto(13,
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
            style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dialog Properties',
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
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
                  style: AppFontStyle.roboto(13, fontWeight: FontWeight.bold),
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
                    BlocProvider.of<ActionEditCubit>(context).change();
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
                  style: AppFontStyle.roboto(13, fontWeight: FontWeight.bold),
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
                    BlocProvider.of<ActionEditCubit>(context).change();
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
                  style: AppFontStyle.roboto(13, fontWeight: FontWeight.bold),
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
                    BlocProvider.of<ActionEditCubit>(context).change();
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
                  style: AppFontStyle.roboto(13, fontWeight: FontWeight.bold),
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
                    BlocProvider.of<ActionEditCubit>(context).change();
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dialog',
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text(
                'Screen',
                style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(child:
                  BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: CustomDropdownButton<UIScreen>(
                                style: AppFontStyle.roboto(13),
                                value: (action.arguments[0] as UIScreen?),
                                hint: Text(
                                  'Choose Screen',
                                  style: AppFontStyle.roboto(14,
                                      fontWeight: FontWeight.w500),
                                ),
                                items: BlocProvider.of<ComponentOperationCubit>(
                                        context,
                                        listen: false)
                                    .project!
                                    .uiScreens
                                    .map<CustomDropdownMenuItem<UIScreen>>(
                                      (e) => CustomDropdownMenuItem<UIScreen>(
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
                                                style: AppFontStyle.roboto(13,
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
                                      (action.arguments[0] as UIScreen?)) {
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
                                      style: AppFontStyle.roboto(13,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Bottom Sheet',
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text(
                'Screen',
                style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(child:
                  BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: CustomDropdownButton<UIScreen>(
                                style: AppFontStyle.roboto(13),
                                value: (action.arguments[0] as UIScreen?),
                                hint: Text(
                                  'Choose Screen',
                                  style: AppFontStyle.roboto(14,
                                      fontWeight: FontWeight.w500),
                                ),
                                items: BlocProvider.of<ComponentOperationCubit>(
                                        context,
                                        listen: false)
                                    .project!
                                    .uiScreens
                                    .map<CustomDropdownMenuItem<UIScreen>>(
                                      (e) => CustomDropdownMenuItem<UIScreen>(
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
                                                style: AppFontStyle.roboto(13,
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
                                      (action.arguments[0] as UIScreen?)) {
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
                                      style: AppFontStyle.roboto(13,
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
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
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
