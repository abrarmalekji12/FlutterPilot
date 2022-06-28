import 'package:flutter/material.dart';

import 'code_processor.dart';

class ProcessorProvider extends InheritedWidget {
  final CodeProcessor processor;

  const ProcessorProvider(this.processor, Widget child, {Key? key})
      : super(child: child, key: key);

  static CodeProcessor? maybeOf(BuildContext context) {
    final ProcessorProvider? result =
        context.dependOnInheritedWidgetOfExactType<ProcessorProvider>();
    return result?.processor;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}
