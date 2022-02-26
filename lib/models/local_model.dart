import 'package:flutter/cupertino.dart';

import 'variable_model.dart';

class LocalModel {
  final String name;
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
    for(final value in values){
      value.add(null);
    }
  }

  void removeVariable(int index) {
    variables.removeAt(index);
    for(final value in values){
      value.removeAt(index);
    }
  }
  void removeValues(int index) {
    values.removeAt(index);
  }
}
