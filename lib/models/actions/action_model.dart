import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/route_manager.dart';

import '../../constant/font_style.dart';
import '../../constant/string_constant.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../cubit/stack_action/stack_action_cubit.dart';
import '../../parameters_list.dart';
import '../parameter_model.dart';
import '../project_model.dart';

abstract class ActionModel {
  final List<dynamic> arguments;

  ActionModel(this.arguments);

  void perform(BuildContext context);

  String metaCode();
}

class NewPageInStackAction extends ActionModel {
  NewPageInStackAction(final UIScreen? screen) : super([screen]);

  @override
  void perform(BuildContext context) {
    if ((arguments[0] as UIScreen?) != null) {
      BlocProvider.of<StackActionCubit>(context, listen: false).stackOperation(
          StackOperation.push,
          uiScreen: (arguments[0] as UIScreen));
    }
    (const GlobalObjectKey(navigationKey).currentState as NavigatorState).push(
      MaterialPageRoute(
        builder: (context) =>
            (arguments[0] as UIScreen?)?.build(context) ?? Container(),
      ),
    );
  }

  @override
  String metaCode() {
    return 'NPISA<${(arguments[0] as UIScreen?)?.name}>';
  }
}

class ReplaceCurrentPageInStackAction extends ActionModel {
  ReplaceCurrentPageInStackAction(final UIScreen? screen) : super([screen]);

  @override
  void perform(BuildContext context) {
    if ((arguments[0] as UIScreen?) != null) {
      BlocProvider.of<StackActionCubit>(context, listen: false).stackOperation(
          StackOperation.replace,
          uiScreen: (arguments[0] as UIScreen));
    }
    (const GlobalObjectKey(navigationKey).currentState as NavigatorState)
        .pushReplacement(
      CustomPageRoute(
        builder: (context) =>
            (arguments[0] as UIScreen?)?.build(context) ?? Container(),
      ),
    );
  }

  @override
  String metaCode() {
    return 'RCPISA<${(arguments[0] as UIScreen?)?.name}>';
  }
}

class GoBackInStackAction extends ActionModel {
  GoBackInStackAction() : super([]);

  @override
  void perform(BuildContext context) {

    BlocProvider.of<StackActionCubit>(context, listen: false)
        .stackOperation(StackOperation.pop);
    Navigator.pop(context);
  }

  String code() {
    return '';
  }

  @override
  String metaCode() {
    return 'NBISA';
  }
}

class ShowDialogInStackAction extends ActionModel {
  ShowDialogInStackAction({List<String>? args})
      : super(args ?? ['This is simple dialog', null, 'OK', null]);

  @override
  void perform(BuildContext context) {
    BlocProvider.of<StackActionCubit>(context, listen: false)
        .showSimpleDialog(this);
    // (const GlobalObjectKey(navigationKey).currentState as NavigatorState).context;
  }

  @override
  String metaCode() {
    return 'SDISA<${arguments.join('-')}>';
  }
}

class ShowCustomDialogInStackAction extends ActionModel {
  ShowCustomDialogInStackAction({UIScreen? uiScreen}) : super([uiScreen]);

  @override
  void perform(BuildContext context) {
    if ((arguments[0] as UIScreen?) != null) {
      BlocProvider.of<StackActionCubit>(context, listen: false).stackOperation(
          StackOperation.addOverlay,
          uiScreen: (arguments[0] as UIScreen));
    }
    BlocProvider.of<StackActionCubit>(context, listen: false)
        .showCustomSimpleDialog(this);
  }

  @override
  String metaCode() {
    return 'SCDISA<${(arguments[0] as UIScreen?)?.name}>';
  }
}

// class HideBottomSheetInStackAction extends ActionModel {
//   HideBottomSheetInStackAction() : super([]);
//
//   @override
//   void perform(BuildContext context) {
//     Navigator.pop(context);
//   }
//
//   @override
//   String metaCode() {
//     return 'HBSISA';
//   }
// }

class ShowBottomSheetInStackAction extends ActionModel {
  ShowBottomSheetInStackAction(UIScreen? uiScreen)
      : super([
          uiScreen,
          Parameters.enableParameter()
            ..val = true
            ..withDisplayName('Enable Drag')
        ]);

  @override
  void perform(BuildContext context) {
    if ((arguments[0] as UIScreen?) != null) {
      BlocProvider.of<StackActionCubit>(context, listen: false).stackOperation(
          StackOperation.addOverlay,
          uiScreen: (arguments[0] as UIScreen));
    }
    (const GlobalObjectKey(deviceScaffoldMessenger).currentState
            as ScaffoldState)
        .showBottomSheet(
      (context) =>
          (arguments[0] as UIScreen?)?.build(context) ??
          Container(
            height: 100,
            color: Colors.white,
          ),
      enableDrag: arguments[1].value,
    );
  }

  @override
  String metaCode() {
    return 'SBSISA<${(arguments[0] as UIScreen?)?.name}>';
  }
}

class ShowSnackBarAction extends ActionModel {
  ShowSnackBarAction()
      : super([
          Parameters.textParameter()
            ..info = null
            ..withRequired(true)
            ..withDefaultValue('This is simple toast'),
          Parameters.flexParameter()
            ..info = null
            ..withRequired(true)
            ..withDefaultValue(3)
            ..withDisplayName('Duration (in seconds) ')
        ]);

  @override
  void perform(BuildContext context) {
    // BlocProvider.of<StackActionCubit>(context, listen: false)
    //     .showSnackBar(this);
    (const GlobalObjectKey(deviceScaffoldMessenger).currentState
            as ScaffoldState)
        .showSnackBar(SnackBar(
      content: Text(
        arguments[0].value,
        style: AppFontStyle.roboto(14, color: Colors.white),
        textAlign: TextAlign.center,
      ),
      // backgroundColor: Colors.grey,
      duration: Duration(seconds: arguments[1].value),
    ));

    // Fluttertoast.showToast(
    //     msg: arguments[0].value,
    //     toastLength: arguments[1].value,
    //     gravity: ToastGravity.CENTER,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.grey,
    //     textColor: Colors.white,
    //     fontSize: 16.0
    // );
    // BlocProvider.of<StackActionCubit>(context, listen: false)
    //     .showCustomSimpleDialog(this);
  }

  @override
  String metaCode() {
    return 'SSBA<${(arguments[0] as Parameter).code(false)}-${(arguments[1] as Parameter).code(false)}>';
  }
}

class CustomPageRoute extends MaterialPageRoute {
  CustomPageRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Duration get transitionDuration => const Duration(seconds: 0);
}
