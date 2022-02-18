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
        deletable: map['deletable']??true);
  }
}

class DynamicVariableModel {
  String name;
  dynamic value;
  String? description;
  String? assignmentCode;
  final bool deletable;

  DynamicVariableModel(this.name, this.value, this.description,
      {this.assignmentCode, this.deletable = true});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'deletable': deletable,
      'description': description,
    };
  }
}
