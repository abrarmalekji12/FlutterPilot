abstract class ParameterInfo {
  String code(String value, {bool allowEmpty});
  String fromCode(String code);
  bool isNamed();
  String? getName();
  bool get optional;
}

class NamedParameterInfo extends ParameterInfo {
  String name;
  bool isOptional;
  NamedParameterInfo(this.name, {this.isOptional = false});

  @override
  String code(String value, {bool allowEmpty = false}) {
    if (value.isEmpty && !allowEmpty) {
      return '';
    }
    return '$name:${value.isNotEmpty ? value : 'null'}';
  }

  @override
  String fromCode(String code) {
    return code.replaceFirst('$name:', '');
  }

  @override
  String? getName() {
    return name;
  }

  @override
  bool isNamed() => true;

  @override
  bool get optional => isOptional;
}

class InnerObjectParameterInfo extends ParameterInfo {
  final String innerObjectName;
  String? namedIfHaveAny;
  bool isOptional;

  InnerObjectParameterInfo(
      {required this.innerObjectName,
      this.namedIfHaveAny,
      this.isOptional = false});

  @override
  String code(String value, {bool allowEmpty = false}) {
    if (namedIfHaveAny != null) {
      if (value.isEmpty && !allowEmpty) {
        return '';
      }
      return '$namedIfHaveAny:$innerObjectName(${value.isNotEmpty ? value : 'null'})';
    }
    return '$innerObjectName(${value.isNotEmpty ? value : 'null'})';
  }

  @override
  bool isNamed() => namedIfHaveAny != null;

  @override
  String? getName() => namedIfHaveAny;
  @override
  String fromCode(String code) {
    final out = (namedIfHaveAny != null
            ? code.replaceFirst('$namedIfHaveAny:', '')
            : code)
        .replaceFirst('$innerObjectName(', '');
    return out.substring(0, out.length - 1);
  }

  @override
  bool get optional => isOptional;
}

class SimpleParameterInfo extends ParameterInfo {
  @override
  String code(String value, {bool allowEmpty = false}) {
    return value;
  }

  @override
  String fromCode(String code) {
    return code;
  }

  @override
  bool isNamed() => false;

  @override
  String? getName() => null;

  @override
  bool get optional => false;
}
