
abstract class ParameterInfo {
  String code(String value);
  String fromCode(String code);
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

  @override
  String fromCode(String code) {
    return code.replaceFirst('$name:', '');
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

  @override
  String fromCode(String code) {
    final out=(namedIfHaveAny!=null?code.replaceFirst('$namedIfHaveAny:', ''):code).replaceFirst('$innerObjectName(', '');
    return out.substring(0,out.length-1);
  }
}

class SimpleParameterInfo extends ParameterInfo {
  @override
  String code(String value) {
    return value;
  }

  @override
  String fromCode(String code) {
    return code;
  }
}
