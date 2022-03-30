import 'package:flutter/cupertino.dart';

import '../ui/models_view.dart';
import 'variable_model.dart';

class LocalModel {
  String name;
  List<DynamicVariableModel> variables = [];
  List<List<dynamic>> values = [];

  LocalModel(this.name);

  factory LocalModel.fromJson(Map<String, dynamic> json) {
    final valueList = List.from(json['values'])
        .map((e) => Map.from(e).values.toList())
        .toList();
    debugPrint('SEE ${json['values']} $valueList');
    return LocalModel(json['name'])
      ..variables = List.from(json['variables'])
          .map((e) => DynamicVariableModel.fromJson(e))
          .toList()
      ..values = valueList;
  }

  get listVariableName => '${name.toLowerCase()}List';

  String get implementationCode {
    return '''
    class $name{${variables.map((e) => 'final ${getDartDataType(e.dataType)} ${e.name};').join(' ')} $name( ${variables.map((e) => 'this.${e.name}').join(',')});
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

  static String valueToCode(dynamic value) {
    switch (value.runtimeType) {
      case double:
      case int:
        return '$value';
      case String:
        return '\'$value\'';
    }
    return '$value';
  }

  static String getDartDataType(final DataType dataType) {
    switch (dataType) {
      case DataType.int:
        return 'int';
      case DataType.double:
        return 'double';
      case DataType.string:
        return 'String';
      case DataType.dynamic:
        return 'dynamic';
      case DataType.bool:
        return 'bool';
    }
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
