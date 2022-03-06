import 'package:flutter/material.dart';

import '../../constant/string_constant.dart';
import '../project_model.dart';

abstract class ActionModel {
  final List<dynamic> arguments;

  ActionModel(this.arguments);

  void perform(BuildContext context);
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
}

class GoBackInStackAction extends ActionModel {
  GoBackInStackAction() : super([]);

  @override
  void perform(BuildContext context) {
    (const GlobalObjectKey(navigationKey).currentState as NavigatorState).pop();
  }
}