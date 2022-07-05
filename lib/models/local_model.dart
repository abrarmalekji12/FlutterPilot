import 'package:flutter/cupertino.dart';

import '../common/compiler/code_processor.dart';
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
    class $name{${variables.map((e) => 'final ${dataTypeToCode(e.dataType)} ${e.name};').join(' ')} $name( ${variables.map((e) => 'this.${e.name}').join(',')});
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

  static DataType codeToDatatype(
      final String dataType, Map<String, FVBClass> classes) {
    switch (dataType) {
      case 'int':
        return DataType.int;
      case 'double':
        return DataType.double;
      case 'String':
        return DataType.string;
      case 'bool':
        return DataType.bool;
      case 'List':
        return DataType.list;
      case 'Map':
        return DataType.map;
      case 'Object':
        return DataType.fvbInstance;
      case 'Function':
        return DataType.fvbFunction;
      case 'Iterable':
        return DataType.iterable;
      case 'dynamic':
        return DataType.dynamic;
      case 'void':
        return DataType.fvbVoid;
      default:
        if (classes.containsKey(dataType)) {
          return DataType.fvbInstance;
        }
        return DataType.unknown;
    }
  }

  static String dataTypeToCode(final DataType dataType) {
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
      case DataType.list:
        return 'List';
      case DataType.map:
        return 'Map';
      case DataType.fvbInstance:
        return 'Object';
      case DataType.fvbFunction:
        return 'Function';
      case DataType.iterable:
        return 'Iterable';
      case DataType.unknown:
        return 'UNKNOWN';
      case DataType.fvbVoid:
        return 'void';
    }
    return 'UNKNOWN';
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
