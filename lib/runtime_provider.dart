import 'package:flutter/cupertino.dart';

import 'models/fvb_ui_core/component/custom_component.dart';

enum RuntimeMode { edit, viewOnly, run, debug, preview, favorite }

class RuntimeProvider extends InheritedWidget {
  final RuntimeMode runtimeMode;
  static RuntimeMode global = RuntimeMode.edit;
  final List<CustomComponent>? customComponents;

  RuntimeProvider({
    Key? key,
    required Widget child,
    required this.runtimeMode,
    this.customComponents,
  }) : super(key: key, child: child) {
    global = runtimeMode;
  }

  static RuntimeMode of(BuildContext context) {
    final RuntimeProvider? result =
        context.dependOnInheritedWidgetOfExactType<RuntimeProvider>();
    // assert(result != null, 'No runtimeMode found in context');
    return result?.runtimeMode??RuntimeMode.viewOnly;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
