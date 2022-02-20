import 'package:flutter/cupertino.dart';

import 'variable_model.dart';

class LocalModel {
  final String name;
  List<DynamicVariableModel> variables = [];
  List<List<dynamic>> values = [];

  LocalModel(this.name);

  factory LocalModel.fromJson(Map<String, dynamic> json) {
    debugPrint('SEEEEE ${json['values']} ${List.from(json['values']).map((e) => Map.from(e).values.toList()).toList()}');
    return LocalModel(json['name'])
      ..variables = List.from(json['variables'])
          .map((e) => DynamicVariableModel.fromJson(e))
          .toList()
      ..values = List.from(json['values']).map((e) => Map.from(e).values.toList()).toList();
  }
  toJson ()=> {
    'name':name,
    'variables':variables.map((e) => e.toJson()).toList(growable: false),
    'values':values.asMap().entries.map((e) => {'${e.key}':e.value})
  };
}
