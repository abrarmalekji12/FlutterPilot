import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../bloc/state_management/state_management_bloc.dart';
import '../constant/font_style.dart';
import '../constant/string_constant.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/stack_action/stack_action_cubit.dart';
import '../models/actions/action_model.dart';
import '../models/project_model.dart';

void showToast(final String message,{bool error=false}) {
  Fluttertoast.showToast(
      msg: message, timeInSecForIosWeb: 9, webBgColor:error? '#ff0000':'#00ff00');
}


void doAPIOperation(BuildContext context,String message,{StackActionCubit? stackActionCubit,StateManagementBloc? stateManagementBloc}){
  if (message.startsWith('api:')) {
    final value = message.replaceAll('api:', '');
    final split = value.split('|');
    final action = split[0];
    switch (action) {
      case 'snackbar':

        (const GlobalObjectKey(deviceScaffoldMessenger).currentState
        as ScaffoldState)
            .showSnackBar(SnackBar(
          content: Text(
            split[1],
            style: AppFontStyle.roboto(14, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          // backgroundColor: Colors.grey,
          duration: Duration(
              milliseconds: (1000 * double.parse(split[2])).toInt()),
        ));
        break;
      case 'newpage':
        final UIScreen? screen = ComponentOperationCubit
            .currentFlutterProject!.uiScreens
            .firstWhereOrNull((screen) => screen.name == split[1]);
        if (screen != null) {
          (stackActionCubit ?? BlocProvider.of<StackActionCubit>(context, listen: false))
              .stackOperation(StackOperation.push, uiScreen: screen);
        }
        (const GlobalObjectKey(navigationKey).currentState
        as NavigatorState)
            .push(
          MaterialPageRoute(
            builder: (context) => screen?.build(context) ?? Container(),
          ),
        );
        break;
      case 'goback':
        (stackActionCubit ?? BlocProvider.of<StackActionCubit>(context, listen: false))
            .stackOperation(StackOperation.pop);
        Navigator.pop(context);
        break;
      case 'refresh':
        (stateManagementBloc??context
            .read<StateManagementBloc>())
            .add(StateManagementUpdateEvent(split[1]));
        break;
      case 'replacepage':
        final UIScreen? screen = ComponentOperationCubit
            .currentFlutterProject!.uiScreens
            .firstWhereOrNull((screen) => screen.name == split[1]);

        if (screen != null) {
          (stackActionCubit ?? BlocProvider.of<StackActionCubit>(context, listen: false))
              .stackOperation(StackOperation.replace, uiScreen: screen);
        }

        (const GlobalObjectKey(navigationKey).currentState
        as NavigatorState)
            .pushReplacement(
          CustomPageRoute(
            builder: (context) => screen?.build(context) ?? Container(),
          ),
        );
        break;
      case 'lookup':
      // return out;
    }
  } else {
    Fluttertoast.showToast(
        msg: message, timeInSecForIosWeb: 9, webBgColor: '#00ff00');
  }
}