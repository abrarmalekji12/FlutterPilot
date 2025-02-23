import 'variable_model.dart';

class Model {
  String name;
  final List<VariableModel> variables = [];

  Model(this.name);

  void addVariable(final VariableModel variable) {
    variables.add(variable);
  }
}
