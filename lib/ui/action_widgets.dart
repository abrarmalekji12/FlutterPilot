import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../common/custom_drop_down.dart';
import '../common/custom_popup_menu_button.dart';
import '../constant/font_style.dart';
import '../cubit/click_action/click_action_cubit.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../models/actions/action_model.dart';
import '../models/component_model.dart';
import '../models/project_model.dart';

class ActionModelWidget extends StatefulWidget {
  final ClickableHolder component;

  const ActionModelWidget({Key? key, required this.component})
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
                  itemBuilder: (context) =>
                      ['NewPageInStackAction', 'GoBackInStackAction']
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
                      case 'NewPageInStackAction':
                        widget.component.actionList
                            .add(NewPageInStackAction(null));
                        _clickActionCubit.changedState();
                        break;
                      case 'GoBackInStackAction':
                        widget.component.actionList
                            .add(GoBackInStackAction());
                        _clickActionCubit.changedState();
                    }
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
                    for (final action in widget.component.actionList)
                      Row(
                        children: [
                          Expanded(
                            child: ActionModelUIWidget(
                                clickableHolder: widget.component,
                                actionModel: action),
                          ),
                          InkWell(
                            onTap:(){
                              widget.component.actionList.remove(action);
                              _clickActionCubit.changedState();
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
  final ClickableHolder clickableHolder;
  final ActionModel actionModel;

  const ActionModelUIWidget(
      {Key? key, required this.clickableHolder, required this.actionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (actionModel.runtimeType) {
      case NewPageInStackAction:
        return NewPageInStackActionWidget(
            clickableHolder: clickableHolder,
            action: actionModel as NewPageInStackAction);
      case GoBackInStackAction:
        return GoBackInStackActionWidget(
            clickableHolder: clickableHolder,
            action: actionModel as GoBackInStackAction);
      default:
        return Container();
    }
  }
}

class NewPageInStackActionWidget extends StatelessWidget {
  final ClickableHolder clickableHolder;
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
                                .flutterProject!
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
  final ClickableHolder clickableHolder;
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
