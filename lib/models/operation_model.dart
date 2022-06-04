import 'component_model.dart';

class ReplaceOperation {
  final Component component1, component2;

  ReplaceOperation(this.component1, this.component2);
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
  final String code;
  final String selectedId;

  Operation(this.code, this.selectedId);
}

class Operation2 {
  final Component component;
  final String selectedId;

  Operation2(this.component, this.selectedId);
}

class CompilerEnable {
  String code = '';
}
