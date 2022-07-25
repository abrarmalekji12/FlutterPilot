import '../common/compiler/code_processor.dart';

class VariableModel extends FVBVariable {
  String? description;
  final bool deletable;
  final bool uiAttached;

  VariableModel(super.name, super.dataType,
      {this.description,
      super.value,
      this.deletable = true,
      super.isFinal = false,
      this.uiAttached = false,
      super.nullable = false});

  @override
  VariableModel clone() {
    return VariableModel(name, dataType,
        deletable: deletable,
        isFinal: isFinal,
        value: value,
        uiAttached: uiAttached,
        nullable: nullable);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'deletable': deletable,
      'description': description,
      'dataType': dataType.name,
      'uiAttached': uiAttached,
      'isFinal': isFinal,
      'nullable': nullable,
    };
  }

  factory VariableModel.fromJson(Map<String, dynamic> map, String screen) {
    return VariableModel(
        map['name'],
        map['dataType'] != null
            ? DataType.values
                .firstWhere((element) => element.name == map['dataType'])
            : DataType.fvbDouble,
        value: map['value'],
        deletable: map['deletable'] ?? true,
        uiAttached: map['uiAttached'] ?? false,
        isFinal: map['isFinal'] ?? false,
        nullable: map['nullable'] ?? false,
        description: map['description']);
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
