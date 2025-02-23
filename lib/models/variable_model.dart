import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';

import '../injector.dart';

class VariableModel extends FVBVariable {
  String? description;
  final bool deletable;
  final bool uiAttached;
  final bool isDynamic;

  VariableModel(super.name, super.dataType,
      {this.description,
      super.value,
      this.deletable = true,
      super.isFinal = false,
      this.uiAttached = false,
      this.isDynamic = false,
      super.nullable = false,
      super.getCall,
      super.setCall});

  @override
  VariableModel clone() {
    return VariableModel(name, dataType,
        deletable: deletable,
        isFinal: isFinal,
        value: value,
        uiAttached: uiAttached,
        nullable: nullable,
        isDynamic: isDynamic,
        setCall: setCall,
        getCall: getCall);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value is FVBInstance ? value.toString() : value,
      'deletable': deletable,
      'description': description,
      'dataType': dataType.name,
      'uiAttached': uiAttached,
      'isFinal': isFinal,
      'nullable': nullable,
    };
  }

  factory VariableModel.fromJson(Map<String, dynamic> map) {
    final type = map['dataType'] != null
        ? DataType.values.firstWhere((element) =>
            element.name.toLowerCase() == map['dataType'].toLowerCase())
        : DataType.fvbDouble;
    dynamic value;
    if (type.name == 'fvbInstance' && map['value'] is String) {
      value = systemProcessor
          .process(map['value'], config: const ProcessorConfig())
          .value;
    } else {
      value = map['value'];
    }
    return VariableModel(map['name'], type,
        value: value,
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

  VariableModel get toVar =>
      VariableModel(name, dataType, description: description);

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
