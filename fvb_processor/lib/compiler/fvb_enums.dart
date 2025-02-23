import 'code_processor.dart';
import 'fvb_function_variables.dart';

class FVBEnum extends FVBObject {
  final String name;
  final Map<String, FVBEnumValue> values;

  FVBEnum(this.name, this.values);

  @override
  String get type => 'enum';
}

final Map<String, FVBVariable> enumVariables = {
  'name': FVBVariable('name', DataType.string),
  'index': FVBVariable('index', DataType.fvbInt)
};

class FVBEnumValue extends FVBObject {
  final String name;
  final int index;
  final String enumName;

  FVBEnumValue(this.name, this.index, this.enumName);

  @override
  String get type => 'enum';

  @override
  String toString() {
    return '$enumName.$name';
  }
}
