import 'package:flutter/material.dart';
import 'package:flutter_builder/data_type.dart';

abstract class Component {
  final List<Parameter> parameters;
  final String name;

  Component(this.name, this.parameters);

  Widget create();

  String code();
}

abstract class MultiHolder extends Component {
  List<Component> children = [];

  MultiHolder(String name, List<Parameter> parameters)
      : super(name, parameters);
}

abstract class Holder extends Component {
  Component? child;

  Holder(String name, List<Parameter> parameters) : super(name, parameters);
}

abstract class Parameter {
  final String name;

  Parameter(this.name);

  get value;
  get rawValue;
}

class SimpleParameter extends Parameter {
  final ParamType paramType;
  dynamic val;
  final bool nullable;
  final dynamic defaultValue;

  @override
  get value => evaluate(val ?? defaultValue);
  late final dynamic Function(Parameter) evaluate;

  SimpleParameter(
      {required String name,
      required this.paramType,
      required this.nullable,
      this.defaultValue,
      dynamic Function(Parameter)? evaluate})
      : super(name) {
    if (evaluate != null) {
      this.evaluate = evaluate;
    } else {
      this.evaluate = (param) => param.value;
    }
  }

  @override
  get rawValue => val??defaultValue;
}

class ChoiceValueParameter extends Parameter {
  final Map<String, dynamic> options;
  final dynamic defaultValue;
  dynamic val;

  @override
  get value => val ?? options[defaultValue];

  ChoiceValueParameter({
    required String name,
    required this.options,
    required this.defaultValue,
  }) : super(name);

  @override
  // TODO: implement rawValue
  get rawValue => throw UnimplementedError();
}

class ChoiceParameter extends Parameter {
  final List<Parameter> options;
  final int defaultValue;
  Parameter? val;

  ChoiceParameter({
    required String name,
    required this.options,
    required this.defaultValue,
  }) : super(name);

  @override
  get value => val?.value ?? options[defaultValue].value;

  @override
  // TODO: implement rawValue
  get rawValue => throw UnimplementedError();
}

class ComplexParameter extends Parameter {
  final List<Parameter> params;

  final dynamic Function(List<Parameter>) evaluate;

  ComplexParameter({
    required this.params,
    required String name,
    required this.evaluate,
  }) : super(name);

  @override
  get value => evaluate.call(params);

  @override
  // TODO: implement rawValue
  get rawValue => throw UnimplementedError();
}
