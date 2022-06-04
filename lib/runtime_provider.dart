import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

enum RuntimeMode { edit, viewOnly, run, preview }

class RuntimeProvider extends InheritedWidget {
  final RuntimeMode runtimeMode;

  const RuntimeProvider(
      {Key? key, required Widget child, required this.runtimeMode})
      : super(key: key, child: child);

  static RuntimeMode of(BuildContext context) {
    final RuntimeProvider? result =
        context.dependOnInheritedWidgetOfExactType<RuntimeProvider>();
    assert(result != null, 'No runtimeMode found in context');
    return result!.runtimeMode;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
