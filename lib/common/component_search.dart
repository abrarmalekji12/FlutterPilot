import 'package:get/get.dart';

import '../models/fvb_ui_core/component/component_model.dart';
import '../models/parameter_model.dart';

abstract class ComponentSearch {
  static bool search(String filter, Component component) {
    if (filter.isEmpty) {
      return true;
    }
    if (component.name.toLowerCase().contains(filter)) {
      return true;
    }
    return component.forEach((p0) {
      return p0.parameters.any(
        (element) =>
            element is SimpleParameter &&
            element.compiler.code.isCaseInsensitiveContains(filter),
      );
    });
  }
}
