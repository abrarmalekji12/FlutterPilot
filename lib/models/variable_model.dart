import '../ui/models_view.dart';

class VariableModel {
  String name;
  dynamic value;
  final DataType dataType;
  bool runtimeAssigned;
  String? description;
  String? assignmentCode;
  final bool deletable;
  final bool isFinal;
  final bool uiAttached;
  final String parentName;

  VariableModel(this.name, this.value, this.runtimeAssigned, this.description,
      this.dataType, this.parentName,
      {this.assignmentCode, this.deletable = true,this.isFinal=false,this.uiAttached=false});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'deletable': deletable,
      'description': description,
      'dataType': dataType.name,
      'uiAttached': uiAttached,
    };
  }

  factory VariableModel.fromJson(Map<String, dynamic> map, String screen) {
    return VariableModel(
        map['name'],
        map['value'],
        false,
        map['description'],
        map['dataType'] != null
            ? DataType.values
                .firstWhere((element) => element.name == map['dataType'])
            : DataType.double,
        screen,
        deletable: map['deletable'] ?? true,uiAttached: map['uiAttached']??false);
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
