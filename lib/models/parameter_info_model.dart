import 'package:equatable/equatable.dart';

sealed class ParameterInfo extends Equatable {
  String code(String value, {bool allowEmpty});

  String fromCode(String code);

  bool isNamed();

  String? getName();

  bool get optional;
}

const kNull = 'null';

class NamedParameterInfo extends ParameterInfo {
  final String name;
  final bool isOptional;
  final String? defaultValue;

  NamedParameterInfo(this.name, {this.isOptional = true, this.defaultValue});

  @override
  String code(String value, {bool allowEmpty = false}) {
    if (isOptional && (value.isEmpty || value == defaultValue) ||
        value == kNull) {
      return '';
    }
    if (value.isEmpty && !allowEmpty) {
      return '';
    }
    return '$name:${value.isNotEmpty ? value : kNull}';
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

  @override
  List<Object?> get props => [name, optional];

  NamedParameterInfo copyWith({String? name, bool? isOptional}) {
    return NamedParameterInfo(name ?? this.name,
        isOptional: isOptional ?? this.isOptional);
  }
}

class InnerObjectParameterInfo extends ParameterInfo {
  final String innerObjectName;
  final String? namedIfHaveAny;
  final bool isOptional;

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
    if (out.isEmpty) {
      return '';
    }
    return out.substring(0, out.length - 1);
  }

  @override
  bool get optional => isOptional;

  @override
  List<Object?> get props => [innerObjectName, namedIfHaveAny, optional];

  InnerObjectParameterInfo copyWith(
      {String? innerObjectName,
      bool removeName = false,
      String? namedIfHaveAny,
      bool? isOptional}) {
    return InnerObjectParameterInfo(
        innerObjectName: innerObjectName ?? this.innerObjectName,
        namedIfHaveAny:
            removeName ? null : (namedIfHaveAny ?? this.namedIfHaveAny),
        isOptional: isOptional ?? this.isOptional);
  }
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

  @override
  List<Object?> get props => [];
}
