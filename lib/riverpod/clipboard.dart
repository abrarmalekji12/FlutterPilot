import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fvb_processor/compiler/code_processor.dart';
import '../models/fvb_ui_core/component/component_model.dart';

class ComponentWithProcessor {
  final Component component;
  final Processor processor;

  ComponentWithProcessor(this.component, this.processor);
}

class ClipboardUpdateProvider extends ChangeNotifier {
  final List<ComponentWithProcessor> data = [];

  void addData(ComponentWithProcessor code) {
    if (data.firstWhereOrNull((e) => e.component == code.component) == null) {
      data.insert(0, code);
      notifyListeners();
    } else {
      data.removeWhere((element) => element.component == code.component);
      data.insert(0, code);
      notifyListeners();
    }
  }
}

final clipboardProvider = ClipboardUpdateProvider();
