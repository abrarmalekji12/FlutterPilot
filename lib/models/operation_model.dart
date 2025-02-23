import '../ui/boundary_widget.dart';
import 'fvb_ui_core/component/component_model.dart';

class ReplaceOperation {
  final Component component1, component2;
  final Viewable? screen;

  ReplaceOperation(
    this.component1,
    this.component2,
    this.screen,
  );
}

class AddOperation {
  final Component component, newComponent;

  AddOperation(this.component, this.newComponent);
}

class RemoveOperation {
  final Component component;
  final Component? parent;

  RemoveOperation(this.component, this.parent);
}

class Operation {
  final Map<String, dynamic>? data;
  final String selectedId;

  Operation(this.data, this.selectedId);
}

class Operation2 {
  final Component component;
  final String selectedId;

  Operation2(this.component, this.selectedId);
}

class CompilerEnable {
  String code = '';
}
