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

  void addChild(Component component){
    children.add(component);
  }
  void addChildren(List<Component> components){
    children.addAll(components);
  }
}

abstract class Holder extends Component {
  Component? child;

  Holder(String name, List<Parameter> parameters) : super(name, parameters);

  void updateChild(Component child){
    this.child=child;
  }
}

abstract class Parameter {
  String name;

  Parameter(this.name);

  get value;

  get rawValue;

  void removeParametersWithName(List<String> parameterNames);

  Parameter copyWith(String name);
}

class SimpleParameter<T> extends Parameter {
  final ParamType paramType;
  T? val;
  final T? defaultValue;

  @override
  dynamic get value {
    if (val != null) {
      return evaluate(val!);
    } else if (defaultValue != null) {
      return evaluate(defaultValue!);
    } else if (paramType == ParamType.double || paramType == ParamType.int) {
      return evaluate(0 as T);
    }
    return null;
  }

  late final dynamic Function(T) evaluate;

  SimpleParameter(
      {required String name,
      required this.paramType,
      this.defaultValue,
        this.val,
      dynamic Function(T)? evaluate})
      : super(name) {
    if (evaluate != null) {
      this.evaluate = evaluate;
    } else {
      this.evaluate = (value) => value;
    }
  }

  @override
  get rawValue {
    if (val != null) {
      return val!;
    } else if (defaultValue != null) {
      return defaultValue!;
    }
    if (paramType == ParamType.double || paramType == ParamType.int) {
      return 0;
    }
  }

  @override
  void removeParametersWithName(List<String> parameterNames) {
    // TODO: implement removeParametersWithName
    throw UnimplementedError('Please implement this method');
  }

  @override
  Parameter copyWith(String name) {
    return SimpleParameter(name: name, paramType: paramType,defaultValue: defaultValue,evaluate: evaluate,val: val);
  }
}

class ChoiceValueParameter extends Parameter {
  final Map<String, dynamic> options;
  final dynamic defaultValue;
  dynamic val;

  @override
  get value {
    if (val != null) {
      return options[val];
    } else if (defaultValue != null) {
      return options[defaultValue];
    }
    return null;
  }

  ChoiceValueParameter({
    required String name,
    required this.options,
    required this.defaultValue,
    this.val
  }) : super(name);

  @override
  get rawValue {
    return val ?? defaultValue;
  }

  @override
  void removeParametersWithName(List<String> parameterNames) {
    // TODO: implement removeParametersWithName
    throw UnimplementedError('Please implement this method');
  }

  @override
  Parameter copyWith(String name) {
    return ChoiceValueParameter(name: name, options: options.map((key, value) => MapEntry(key, value)), defaultValue: defaultValue,val: val);
  }
}

class ChoiceParameter extends Parameter {
  final List<Parameter> options;
  final int defaultValue;
  Parameter? val;

  ChoiceParameter({
    required String name,
    required this.options,
    required this.defaultValue,
    this.val
  }) : super(name);

  @override
  get value => val?.value ?? options[defaultValue].value;

  @override
  Parameter get rawValue => val ?? options[defaultValue];

  @override
  void removeParametersWithName(List<String> parameterNames) {
    List<Parameter> removeList=[];
    for (final param in parameterNames) {
      for (final optionValue in options) {
        if (optionValue.name == param) {
          removeList.add(optionValue);
        }
      }
    }
    for(final value in removeList){
      options.remove(value);
    }
    removeList.clear();
  }

  @override
  Parameter copyWith(String name) {
    return ChoiceParameter(name: name, options: options.map((e) => e.copyWith(e.name)).toList(), defaultValue: defaultValue,val: val);
  }
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

  @override
  void removeParametersWithName(List<String> parameterNames) {
    List<Parameter> removeList=[];
    for (final param in parameterNames) {
      for (final optionValue in params) {
        if (optionValue.name == param) {
          removeList.add(optionValue);
        }
      }
    }
    for(final value in removeList){
      params.remove(value);
    }
    removeList.clear();
  }

  @override
  Parameter copyWith(String name) {
    return ComplexParameter(name: name, params: params.map((e) => e.copyWith(e.name)).toList(), evaluate: evaluate);
  }
}
