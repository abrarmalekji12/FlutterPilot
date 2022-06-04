import 'parameter_model.dart';

class ParameterRuleModel {
  final Parameter changedParameter;
  final Parameter anotherParameter;
  String? errorText;
  final String? Function(Parameter, Parameter) onChange;
  ParameterRuleModel(
      {required this.changedParameter,
      required this.anotherParameter,
      required this.onChange});

  bool hold() {
    return (errorText = onChange.call(changedParameter, anotherParameter)) !=
        null;
  }
}
