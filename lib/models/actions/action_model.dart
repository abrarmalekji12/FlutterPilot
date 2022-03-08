import 'package:flutter/material.dart';

import '../../constant/string_constant.dart';
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

class GoBackInStackAction extends ActionModel {
  GoBackInStackAction() : super([]);

  @override
  void perform(BuildContext context) {
    (const GlobalObjectKey(navigationKey).currentState as NavigatorState).pop();
  }


  String code(){
    return '';
  }
  @override
  String metaCode() {
    return 'NBISA';
  }

}

class ShowDialogInStackAction extends ActionModel {
  ShowDialogInStackAction() : super([]);

  @override
  void perform(BuildContext context) {

    // (const GlobalObjectKey(navigationKey).currentState as NavigatorState).context;
  }
  @override
  String metaCode() {
    return 'SDISA';
  }

  @override
  void fromMetaCode(String code) {

  }

}