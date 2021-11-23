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

  SimpleParameter(
      {required String name, required this.paramType, required this.nullable})
      : super(name);
}

class ChoiceParameter extends Parameter {
  final Map<String, dynamic> options;

  ChoiceParameter({
    required String name,
    required this.options,
  }) : super(name);
}

class MultiComponentParameter extends Parameter {
  List<Component>? components;

  MultiComponentParameter({required String name}) : super(name);
}

class ComplexParameter extends Parameter {
  final List<Parameter> params;

  ComplexParameter(String name, this.params) : super(name);
}
