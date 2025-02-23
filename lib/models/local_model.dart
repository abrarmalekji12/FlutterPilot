import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';

import 'variable_model.dart';

class LocalModel {
  String name;
  List<DynamicVariableModel> variables = [];
  List<List<dynamic>> values = [];

  LocalModel(this.name);

  factory LocalModel.fromJson(Map<String, dynamic> json) {
    final valueList = List.from(json['values']).map((e) {
      final entries = Map.from(e);
      final List<dynamic> list = [];
      for (int i = 0; i < entries.length; i++) {
        list.add(entries[i.toString()]);
      }
      return list;
    }).toList();
    return LocalModel(json['name'])
      ..variables = List.from(json['variables'])
          .map((e) => DynamicVariableModel.fromJson(e))
          .toList()
      ..values = valueList;
  }

  get listVariableName => '${name.toLowerCase()}List';

  String get implementationCode {
    return '''
    class $name{${variables.map((e) => 'final ${DataType.dataTypeToCode(e.dataType)} ${e.name};').join(' ')} $name( ${variables.map((e) => 'this.${e.name}').join(',')});
    }
    ''';
  }

  String get declarationCode {
    return '''
    List<$name> $listVariableName = [
    ${values.map((e) => '$name(${e.map((value) => valueToCode(value)).join(',')})').join(',')}
    ];
    ''';
  }

  static dynamic codeToValue(String code, DataType dataType,
      {bool stringQuote = true}) {
    if (dataType.equals(DataType.string)) {
      return stringQuote ? code.substring(1, code.length - 1) : code;
    } else if (dataType.equals(DataType.fvbInt)) {
      return int.tryParse(code);
    } else if (dataType.equals(DataType.fvbDouble)) {
      return double.tryParse(code);
    } else if (dataType.equals(DataType.fvbBool)) {
      return code == 'true' ? true : (code == 'false' ? false : null);
    }
    return null;
  }

  static String valueToCode(dynamic value) {
    if (value is FVBInstance) {
      return value.defineCode();
    } else if (value is FVBCode) {
      return value.code;
    }
    switch (value.runtimeType) {
      case double:
      case int:
        return '$value';
      case String:
        return '\'$value\'';
      case Color:
        return 'const Color(0x${(value as Color).value.toRadixString(16)})';
    }
    if (value is List) {
      if (value.isEmpty) {
        return 'const []';
      }
      return '[${(value).map((value) => valueToCode(value)).join(',')}]';
    }
    if (value is Map) {
      if (value.isEmpty) {
        return 'const {}';
      }
      return '{${(value).entries.map((e) => '${valueToCode(e.key)}:${valueToCode(e.value)}').join(',')}}';
    }
    return '$value';
  }

  toJson() {
    final valueList = [];
    for (final value in values) {
      final valuesMap = {};
      for (int i = 0; i < value.length; i++) {
        valuesMap['$i'] = value[i];
      }
      valueList.add(valuesMap);
    }
    return {
      'name': name,
      'variables': variables.map((e) => e.toJson()).toList(growable: false),
      'values': valueList
    };
  }

  void addVariable(DynamicVariableModel dynamicVariableModel) {
    variables.add(dynamicVariableModel);
    for (final value in values) {
      value.add(null);
    }
  }

  void removeVariable(int index) {
    variables.removeAt(index);
    for (final value in values) {
      value.removeAt(index);
    }
  }

  void removeValues(int index) {
    values.removeAt(index);
  }
}
