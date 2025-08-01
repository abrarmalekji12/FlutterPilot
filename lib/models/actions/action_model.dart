import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/converter/code_converter.dart';
import '../../constant/font_style.dart';
import '../../constant/string_constant.dart';
import '../../cubit/stack_action/stack_action_cubit.dart';
import '../../parameter/parameters_list.dart';
import '../fvb_ui_core/component/custom_component.dart';
import '../parameter_info_model.dart';
import '../parameter_model.dart';
import '../project_model.dart';

abstract class ActionModel {
  final List<dynamic> arguments;

  ActionModel(this.arguments);

  void perform(BuildContext context);

  String metaCode();

  String code();

  ActionModel clone();

  toJson() => {'action': arguments.map((e) => e.toString()).toList()};
  void fromJson(json) {
    arguments.clear();
    arguments.addAll(json['action']);
  }
}

class CustomAction extends ActionModel {
  CustomAction({String code = ''}) : super([code]);

  @override
  String code() {
    return FVBEngine.instance.fvbToDart(arguments[0]);
  }

  @override
  String metaCode() {
    return 'CA<${base64Encode((arguments[0] as String).codeUnits)}>';
  }

  @override
  void perform(BuildContext context) {}

  @override
  ActionModel clone() => CustomAction(code: arguments[0].toString());
}

class NewPageInStackAction extends ActionModel {
  NewPageInStackAction(final Screen? screen) : super([screen]);

  @override
  void perform(BuildContext context) {
    if ((arguments[0] as Screen?) != null) {
      BlocProvider.of<StackActionCubit>(context).stackOperation(
          StackOperation.push,
          screen: (arguments[0] as Screen));
    }
    (navigationKey?.currentState as NavigatorState).push(
      MaterialPageRoute(
        builder: (context) =>
            (arguments[0] as Screen?)?.build(context) ?? Container(),
      ),
    );
  }

  @override
  String metaCode() {
    return 'NPISA<${(arguments[0] as Screen?)?.name}>';
  }

  @override
  String code() {
    if (arguments[0] == null) {
      return '';
    }
    return 'Navigator.push(context,MaterialPageRoute(builder: (_)=> const ${(arguments[0] as Screen).getClassName}()))';
  }

  @override
  ActionModel clone() => NewPageInStackAction(arguments[0] as Screen?);
}

class ReplaceCurrentPageInStackAction extends ActionModel {
  ReplaceCurrentPageInStackAction(final Screen? screen) : super([screen]);

  @override
  void perform(BuildContext context) {
    if ((arguments[0] as Screen?) != null) {
      BlocProvider.of<StackActionCubit>(context).stackOperation(
          StackOperation.replace,
          screen: (arguments[0] as Screen));
    }
    (navigationKey?.currentState as NavigatorState).pushReplacement(
      CustomPageRoute(
        builder: (context) =>
            (arguments[0] as Screen?)?.build(context) ?? Container(),
      ),
    );
  }

  @override
  String metaCode() {
    return 'RCPISA<${(arguments[0] as Screen?)?.name}>';
  }

  @override
  String code() {
    if (arguments[0] == null) {
      return '';
    }
    return 'Navigator.pushReplacement(context,MaterialPageRoute(builder: (_)=> const ${(arguments[0] as Screen).getClassName}()))';
  }

  @override
  ActionModel clone() {
    return ReplaceCurrentPageInStackAction(arguments[0] as Screen?);
  }
}

class GoBackInStackAction extends ActionModel {
  GoBackInStackAction() : super([]);

  @override
  void perform(BuildContext context) {
    BlocProvider.of<StackActionCubit>(context)
        .stackOperation(StackOperation.pop);
    (navigationKey?.currentState as NavigatorState).pop();
  }

  @override
  String code() {
    return 'Navigator.pop(context)';
  }

  @override
  String metaCode() {
    return 'NBISA';
  }

  @override
  ActionModel clone() {
    return GoBackInStackAction();
  }
}

class ShowDialogInStackAction extends ActionModel {
  ShowDialogInStackAction({List<String?>? args})
      : super(args ?? ['This is simple dialog', null, 'OK', null]);

  @override
  void perform(BuildContext context) {
    BlocProvider.of<StackActionCubit>(context).showSimpleDialog(this);
    // (const GlobalObjectKey(navigationKey).currentState as NavigatorState).context;
  }

  @override
  String metaCode() {
    return 'SDISA<${arguments.join('-')}>';
  }

  @override
  String code() {
    return 'showDialog(context: context, builder: (_)=> MaterialSimpleAlertDialog(title:\'${arguments[0]}\'${arguments[1] != null ? ',subtitle: \'${arguments[1]}\'' : ''}, positiveButtonText: ${arguments[2]},${arguments[3] != null ? 'negativeButtonText: \'${arguments[3]}\',' : ''}))';
  }

  @override
  ActionModel clone() {
    return ShowDialogInStackAction(
        args: arguments.map((e) => e as String?).toList());
  }
}

class ShowCustomDialogInStackAction extends ActionModel {
  ShowCustomDialogInStackAction({required CustomComponent comp})
      : super([comp]);

  @override
  void perform(BuildContext context) {
    if ((arguments[0] as Screen?) != null) {
      BlocProvider.of<StackActionCubit>(context).stackOperation(
          StackOperation.addOverlay,
          screen: (arguments[0] as Screen));
    }
    BlocProvider.of<StackActionCubit>(context).showCustomSimpleDialog(this);
  }

  @override
  String metaCode() {
    return 'SCDISA<${(arguments[0] as Screen?)?.name}>';
  }

  @override
  String code() {
    if (arguments[0] == null) {
      return '';
    }
    return 'showDialog(context: context, builder: (_)=> const ${(arguments[0] as Screen).getClassName}())';
  }

  @override
  ActionModel clone() {
    return ShowCustomDialogInStackAction(comp: arguments[0] as CustomComponent);
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
  ShowBottomSheetInStackAction(Screen? uiScreen)
      : super([
          uiScreen,
          Parameters.enableParameter(true)..withDisplayName('Enable Drag')
        ]);

  @override
  void perform(BuildContext context) {
    if ((arguments[0] as Screen?) != null) {
      BlocProvider.of<StackActionCubit>(context).stackOperation(
          StackOperation.addOverlay,
          screen: (arguments[0] as Screen));
    }
    (deviceScaffoldMessenger!.currentState as ScaffoldState).showBottomSheet(
      (context) =>
          (arguments[0] as Screen?)?.build(context) ??
          Container(
            height: 100,
            color: Colors.white,
          ),
      enableDrag: arguments[1].value,
    );
  }

  @override
  String metaCode() {
    return 'SBSISA<${(arguments[0] as Screen?)?.name}>';
  }

  @override
  String code() {
    if (arguments[0] == null) {
      return '';
    }
    return 'showBottomSheet(context: context, builder: (_)=> const ${(arguments[0] as Screen).getClassName}())';
  }

  @override
  ActionModel clone() {
    return ShowBottomSheetInStackAction(arguments[0] as Screen?);
  }
}

class ShowSnackBarAction extends ActionModel {
  ShowSnackBarAction({List<dynamic>? arguments})
      : super(arguments ??
            [
              Parameters.textParameter()
                ..info = SimpleParameterInfo()
                ..withRequired(true)
                ..withDefaultValue('This is simple toast'),
              Parameters.flexParameter()
                ..info = SimpleParameterInfo()
                ..withRequired(true)
                ..withDefaultValue(3)
                ..withDisplayName('Duration (in seconds) ')
            ]);

  @override
  void perform(BuildContext context) {
    // BlocProvider.of<StackActionCubit>(context)
    //     .showSnackBar(this);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        arguments[0].value,
        style: AppFontStyle.lato(14, color: Colors.white),
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
    // BlocProvider.of<StackActionCubit>(context)
    //     .showCustomSimpleDialog(this);
  }

  @override
  String metaCode() {
    return 'SSBA<${(arguments[0] as Parameter).code(false)}-${(arguments[1] as Parameter).code(false)}>';
  }

  @override
  String code() {
    return '''ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        ${(arguments[0] as SimpleParameter).code(true)},
        style:GoogleFonts.roboto(fontSize: 14,color: Colors.white),
        textAlign: TextAlign.center,
      ),
      // backgroundColor: Colors.grey,
      duration: Duration(seconds:  ${(arguments[1] as SimpleParameter).code(true)}),
    ))''';
  }

  @override
  ActionModel clone() {
    return ShowSnackBarAction()
      ..arguments.asMap().forEach((index, element) {
        (element as Parameter).cloneOf(arguments[index], false);
      });
  }
}

class CustomPageRoute extends MaterialPageRoute {
  CustomPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => const Duration(seconds: 0);
}
