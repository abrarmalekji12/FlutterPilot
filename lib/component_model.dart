import 'package:flutter/material.dart';
import 'package:flutter_builder/data_type.dart';

abstract class Component {
  final List<Parameter> parameters;
  final String name;

  Component(this.name, this.parameters);

  Widget create();

  String code();
}

abstract class Parameter {
  final String name;
  dynamic value;

  Parameter(this.name);

  get getValue => value;
}

class SimpleParameter extends Parameter {
  final ParamType paramType;
  final bool nullable;

  late final dynamic Function(Parameter) evaluate;

  SimpleParameter(
      {required String name,
      required this.paramType,
      required this.nullable,
      dynamic Function(Parameter)? evaluate})
      : super(name){
    if(evaluate!=null){
      this.evaluate=evaluate;
    }
    else{
      this.evaluate=(param)=>param.value;
    }
  }
}

class ChoiceValueParameter extends Parameter {
  final Map<String, dynamic> options;

  ChoiceValueParameter({
    required String name,
    required this.options,
  }) : super(name);
}

class ChoiceParameter extends Parameter {
  final List<Parameter> options;

  ChoiceParameter({
    required String name,
    required this.options,
  }) : super(name);
}

class MultiComponentParameter extends Parameter {
  List<Component>? components;

  MultiComponentParameter({
    required String name,
  }) : super(name);
}
class SingleComponentParameter extends Parameter {
  Component? component;

  SingleComponentParameter({
    required String name,
  }) : super(name);
}
class ComplexParameter extends Parameter {
  final List<Parameter> params;
  final dynamic Function(List<Parameter>) evaluate;

  ComplexParameter({
    required this.params,
    required String name,
    required this.evaluate,
  }) : super(name);
}
