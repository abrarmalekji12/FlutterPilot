import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../common/in_use_common/material_alert_dialog.dart';
import '../cubit/stack_action/stack_action_cubit.dart';
import '../models/actions/action_model.dart';
import '../models/fvb_ui_core/component/custom_component.dart';

class StackActionWidget extends StatelessWidget {
  final ActionModel actionModel;

  const StackActionWidget({Key? key, required this.actionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (actionModel is ShowDialogInStackAction) {
      return ShowDialogActionWidget(
          actionModel: actionModel as ShowDialogInStackAction);
    } else if (actionModel is ShowCustomDialogInStackAction) {
      return ShowCustomDialogActionWidget(
          actionModel: actionModel as ShowCustomDialogInStackAction);
    }

    return Container();
  }
}

class ShowDialogActionWidget extends StatelessWidget {
  final ShowDialogInStackAction actionModel;

  const ShowDialogActionWidget({Key? key, required this.actionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        BlocProvider.of<StackActionCubit>(context).back();
      },
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: MaterialSimpleAlertDialog(
          title: actionModel.arguments[0],
          subtitle: actionModel.arguments[1],
          positiveButtonText: actionModel.arguments[2],
          negativeButtonText: actionModel.arguments[3],
        ),
      ),
    );
  }
}

class ShowCustomDialogActionWidget extends StatelessWidget {
  final ShowCustomDialogInStackAction actionModel;

  const ShowCustomDialogActionWidget({Key? key, required this.actionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        BlocProvider.of<StackActionCubit>(context).back();
      },
      child: Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: (actionModel.arguments[0] as CustomComponent).build(context),
        ),
      ),
    );
  }
}
