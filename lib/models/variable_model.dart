import '../ui/models_view.dart';

class VariableModel {
  String name;
  double value;
  bool runtimeAssigned;
  String? description;
  String? assignmentCode;
  final bool deletable;

  VariableModel(this.name, this.value, this.runtimeAssigned, this.description,
      {this.assignmentCode, this.deletable = true});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'deletable': deletable,
      'description': description,
    };
  }

  factory VariableModel.fromJson(Map<String, dynamic> map) {
    return VariableModel(map['name'], map['value'], false, map['description'],
        deletable: map['deletable'] ?? true);
  }
}

class DynamicVariableModel {
  String name;
  DataType dataType;
  String? description;

  DynamicVariableModel(this.name, this.dataType, {this.description = ''});

  factory DynamicVariableModel.fromJson(Map<String, dynamic> json) {
    return DynamicVariableModel(
        json['name'],
        DataType.values
            .firstWhere((element) => element.name == json['dataType']),
        description: json['description']);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dataType': dataType.name,
      'description': description,
    };
  }
}
