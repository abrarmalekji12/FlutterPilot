import 'package:flutter/material.dart';
import 'package:flutter_builder/ui/boundary_widget.dart';

import 'code_processor.dart';

class ProcessorProvider extends InheritedWidget {
  final Processor processor;

  const ProcessorProvider({
    required this.processor,
    required super.child,
    Key? key,
  }) : super(key: key);

  static Processor? maybeOf(BuildContext context) {
    final ProcessorProvider? result =
        context.dependOnInheritedWidgetOfExactType<ProcessorProvider>();
    return result?.processor;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class ViewableProvider extends InheritedWidget {
  final Viewable screen;

  const ViewableProvider(
      {required this.screen, required Widget child, Key? key})
      : super(child: child, key: key);

  static Viewable? maybeOf(BuildContext context) {
    final ViewableProvider? result =
        context.dependOnInheritedWidgetOfExactType<ViewableProvider>();
    return result?.screen;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}
