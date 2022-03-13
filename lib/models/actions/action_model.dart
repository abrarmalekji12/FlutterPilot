import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constant/string_constant.dart';
import '../../cubit/stack_action/stack_action_cubit.dart';
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
    (const GlobalObjectKey(navigationKey).currentState as NavigatorState).pushReplacement(
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
    (const GlobalObjectKey(navigationKey).currentState as NavigatorState).pop();
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
  ShowCustomDialogInStackAction({UIScreen? uiScreen})
      : super([uiScreen]);

  @override
  void perform(BuildContext context) {
    BlocProvider.of<StackActionCubit>(context, listen: false)
        .showCustomSimpleDialog(this);
  }

  @override
  String metaCode() {
    return 'SCDISA<${(arguments[0] as UIScreen?)?.name}>';
  }
}
class CustomPageRoute extends MaterialPageRoute {
  CustomPageRoute({required WidgetBuilder builder}) : super(builder: builder);
  @override
  Duration get transitionDuration => const Duration(seconds: 0);
}