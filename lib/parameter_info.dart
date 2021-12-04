
abstract class ParameterInfo {
  String code(String value);
}

class NamedParameterInfo extends ParameterInfo  {
  final String name;

  NamedParameterInfo(this.name);

  @override
  String code(String value) {
    if(value.isEmpty) {
      return '';
    }
    return '$name:$value';
  }
}

class InnerObjectParameterInfo extends ParameterInfo {
  final String innerObjectName;
  final String? namedIfHaveAny;

  InnerObjectParameterInfo(
      {required this.innerObjectName, this.namedIfHaveAny});

  @override
  String code(String value) {
    if (namedIfHaveAny != null) {
      if(value.isEmpty){
        return '';
      }
      return '$namedIfHaveAny:$innerObjectName($value)';
    }
    return '$innerObjectName($value)';
  }
}

class SimpleParameterInfo extends ParameterInfo {
  @override
  String code(String value) {
    return value;
  }
}
