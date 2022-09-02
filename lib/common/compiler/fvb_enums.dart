import 'code_processor.dart';

class FVBEnum extends FVBObject {
  final String name;
  final Map<String, FVBEnumValue> values;

  FVBEnum(this.name, this.values);

  @override
  String get type => 'enum';
}

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
