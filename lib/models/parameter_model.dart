import 'package:flutter/material.dart';
import 'package:flutter_builder/enums.dart';
import 'package:flutter_builder/models/parameter_info.dart';

abstract class Parameter {
  String? displayName;
  bool isRequired;
  String? Function(ComplexParameter)? validToShow;
  ParameterInfo? info;

  Parameter(this.displayName, this.info, this.isRequired);

  get value;

  get rawValue;

  String get code;

  void fromCode(String code) {}

  dynamic getValueFromCode<T>(String code) {
    if (T == int) {
      return int.tryParse(info?.fromCode(code) ?? code);
    } else if (T == double) {
      return double.tryParse(info?.fromCode(code) ?? code);
    } else if (T == String) {
      return info?.fromCode(code) ?? code;
    }
    else if (T == Color) {
      final colorString = (info?.fromCode(code) ?? code).replaceAll('Color(', '').replaceAll(')', '');
      return Color(int.parse(colorString));
    }
    return info?.fromCode(code) ?? code;
  }

  String? checkIfValidToShow(ComplexParameter complexParameter) {
    if (validToShow != null) {
      return validToShow?.call(complexParameter);
    } else {
      return null;
    }
  }

  set setValidToShow(String? Function(ComplexParameter)? validToShow) {
    this.validToShow = validToShow;
  }

  void withDisplayName(String? name) {
    displayName = name;
  }

  void withInfo(ParameterInfo? info) {
    this.info = info;
  }

  void withRequired(bool required, {String? nullParameterName = 'None'}) {
    if (isRequired == required) {
      return;
    }
    isRequired = required;
    if (this is SimpleParameter) {
      if (required) {
        (this as SimpleParameter).val = (this as SimpleParameter).defaultValue;
      } else {
        (this as SimpleParameter).val = null;
      }
    } else {
      switch (runtimeType) {
        case ChoiceParameter:
          if (required) {
            (this as ChoiceParameter).options.removeAt(0);
          } else {
            (this as ChoiceParameter).options.insert(
              0,
              NullParameter(displayName: nullParameterName),
            );
          }
          (this as ChoiceParameter).val = (this as ChoiceParameter)
              .options[(this as ChoiceParameter).defaultValue];
          break;
      }
    }
  }
}

class SimpleParameter<T> extends Parameter {
  final ParamType paramType;
  T? val;
  final ParamInputType inputType;
  T? defaultValue;

  @override
  dynamic get value {
    if (val != null) {
      return evaluate(val!);
    } else if (!isRequired) {
      return null;
    } else if (defaultValue != null) {
      return evaluate(defaultValue!);
    } else if (paramType == ParamType.double || paramType == ParamType.int) {
      return evaluate(0 as T);
    }
    return '';
  }

  late final dynamic Function(T) evaluate;

  SimpleParameter({String? name,
    required this.paramType,
    this.defaultValue,
    this.val,
    this.inputType = ParamInputType.text,
    dynamic Function(T)? evaluate,
    bool required = true,
    ParameterInfo? info})
      : super(name, info, required) {
    if (evaluate != null) {
      this.evaluate = evaluate;
    } else {
      this.evaluate = (value) => value;
    }
    if (required) {
      val = defaultValue;
    }
  }

  @override
  get rawValue {
    if (val != null) {
      return val!;
    } else if (!isRequired) {
      return null;
    } else if (defaultValue != null) {
      return defaultValue!;
    }
    if (paramType == ParamType.double || paramType == ParamType.int) {
      return 0;
    }
  }

  void withDefaultValue(T? value) {
    defaultValue = value;
    val = value;
  }

  @override
  String get code {
    if (!isRequired && val == null) {
      return '';
    }
    if (info != null) {
      if (paramType == ParamType.string) {
        return '${info!.code('\'$rawValue\'')},'.replaceAll(',,', ',');
      }
      return '${info!.code('$rawValue')},'.replaceAll(',,', ',');
    }
    if (paramType == ParamType.string) {
      return '\'$rawValue\'';
    }
    return '$rawValue';
  }

  @override
  void fromCode(String code) {
    val = getValueFromCode<T>(code);
  }
}

class ListParameter extends Parameter {
  final List<Parameter> params = [];
  final Parameter Function() parameterGenerator;

  ListParameter({required String? displayName,
    ParameterInfo? info,
    required this.parameterGenerator})
      : super(displayName, info, false);

  @override
  String get code {
    String parametersCode = '[';
    for (final parameter in params) {
      if (parameter.info is InnerObjectParameterInfo) {
        parameter.withInfo(InnerObjectParameterInfo(
            innerObjectName:
            (parameter.info as InnerObjectParameterInfo).innerObjectName));
      }
      parametersCode += '${(parameter).code},'.replaceAll(',,', ',');
    }
    parametersCode += '],'.replaceAll(',,', ',');
    if (info != null) {
      return '${info!.code(parametersCode)},'.replaceAll(',,', ',');
    }
    return parametersCode;
  }

  @override
  // TODO: implement rawValue
  get rawValue {
    return params;
  }

  @override
  // TODO: implement value
  get value {
    return params.map((e) => e.value).toList();
  }
}

class ChoiceValueParameter extends Parameter {
  final Map<String, dynamic> options;
  final dynamic defaultValue;
  dynamic val;

  @override
  get value {
    if (val != null) {
      return options[val];
    } else if (defaultValue != null) {
      return options[defaultValue];
    }
    return null;
  }

  ChoiceValueParameter({String? name,
    required this.options,
    required this.defaultValue,
    bool required = true,
    this.val,
    ParameterInfo? info})
      : super(name, info, required);

  @override
  get rawValue {
    return val ?? defaultValue;
  }

  @override
  get code {
    if (info == null || info is SimpleParameterInfo) {
      return value.toString();
    }
    return info!.code(value.toString());
  }

  @override
  void fromCode(String code) {
    final paramCode = (info?.fromCode(code) ?? code);
    val = options.entries
        .firstWhere((element) => element.value.toString() == paramCode)
        .key;
  }

}

class ChoiceParameter extends Parameter {
  final List<Parameter> options;
  late int defaultValue = 0;
  Parameter? val;
  String? nullParameterName;

  ChoiceParameter({String? name,
    required this.options,
    bool required = true,
    this.val,
    this.nullParameterName = 'none',
    ParameterInfo? info})
      : super(name, info, required) {
    if (!required) {
      options.insert(
        0,
        NullParameter(displayName: nullParameterName),
      );
    }
    val = options[defaultValue];
  }

  @override
  get value {
    return val?.value;
  }

  @override
  Parameter get rawValue => val ?? options[defaultValue];

  @override
  get code {
    final paramCode = rawValue.code;
    if (paramCode.isEmpty ||
        (info != null &&
            (info is NamedParameterInfo ||
                (info is InnerObjectParameterInfo &&
                    (info as InnerObjectParameterInfo).namedIfHaveAny !=
                        null)) &&
            paramCode == 'null')) {
      return '';
    }
    return info != null ? info!.code(paramCode) : paramCode;
  }

  @override
  void fromCode(String code) {
    final paramCode = (info?.fromCode(code) ?? code);
    val = options.firstWhere((element) =>
        paramCode.startsWith('${(element.info as InnerObjectParameterInfo?)
            ?.innerObjectName}('));
    print('VALUE $paramCode');
    val?.fromCode(paramCode);
  }
}

class ComplexParameter extends Parameter {
  final List<Parameter> params;
  final dynamic Function(List<Parameter>) evaluate;

  ComplexParameter({String? name,
    required this.params,
    required this.evaluate,
    ParameterInfo? info,
    bool required = true})
      : super(name, info, required);

  @override
  get value => evaluate.call(params);

  @override
  get rawValue => throw UnimplementedError();

  @override
  get code {
    String middle = '';
    for (final para in params) {
      final paramCode = para.code;
      if (paramCode.isNotEmpty) {
        middle += '$paramCode,'.replaceAll(',,', ',');
      }
    }
    return info?.code(middle) ?? middle;
  }

  @override
  void fromCode(String code) {
    final paramCodeList = (info?.fromCode(code) ?? code);
    int parenthesisCount = 0;
    final List<int> dividers = [-1];
    for (int i = 0; i < paramCodeList.length; i++) {
      if (paramCodeList[i] == ',' && parenthesisCount==0) {
        dividers.add(i);
      } else if (paramCodeList[i] == '(') {
        parenthesisCount++;
      } else if (paramCodeList[i] == ')') {
        parenthesisCount--;
      }
    }
    List<String> parameterCodes = [];
    for (int divideIndex = 0; divideIndex < dividers.length; divideIndex++) {
      if (divideIndex + 1 < dividers.length) {
        final subCode = paramCodeList.substring(
            dividers[divideIndex] + 1, dividers[divideIndex + 1]);
        if (subCode.isNotEmpty) {
          parameterCodes.add(subCode);
        }
      } else {
        final subCode = paramCodeList.substring(dividers[divideIndex] + 1);
        if (subCode.isNotEmpty) {
          parameterCodes.add(subCode);
        }
      }
    }

    print('subcode $parameterCodes');
    for (Parameter parameter in params) {
      if (parameter.info is NamedParameterInfo ||
          (parameter.info is InnerObjectParameterInfo &&
              (parameter.info as InnerObjectParameterInfo).namedIfHaveAny !=
                  null)) {
        for (final paramCode in parameterCodes) {
          if (paramCode.startsWith('${parameter.info is NamedParameterInfo
              ? (parameter.info as NamedParameterInfo).name
              : (parameter.info as InnerObjectParameterInfo)
              .namedIfHaveAny!}:')) {
            parameter.fromCode(paramCode);
            break;
          }
        }
      }
    }
  }
}

class ConstantValueParameter extends Parameter {
  dynamic constantValue;
  late String constantValueString;
  ParamType paramType;

  ConstantValueParameter({String? displayName,
    ParameterInfo? info,
    String? constantValueInString,
    required this.constantValue,
    required this.paramType})
      : super(displayName, info, true) {
    if (constantValueInString != null) {
      constantValueString = constantValueInString;
    } else {
      constantValueString = constantValue.toString();
    }
  }

  @override
  // TODO: implement code
  String get code {
    if (info == null || info is SimpleParameterInfo) {
      if (paramType == ParamType.string) {
        return '\'$constantValueString}\'';
      }
      return constantValueString;
    }
    return info!.code(paramType == ParamType.string
        ? '\'$constantValueString}\''
        : constantValueString);
  }

  @override
  get rawValue => constantValue;

  @override
  get value => constantValue;
}

class NullParameter extends Parameter {
  NullParameter(
      {String? displayName, ParameterInfo? info, bool required = false})
      : super(displayName, info, required);

  @override
  String get code {
    if ((info is InnerObjectParameterInfo &&
        (info as InnerObjectParameterInfo).namedIfHaveAny == null) ||
        info == null) {
      return 'null';
    }
    return '';
  }

  @override
  get rawValue => null;

  @override
  get value => null;
}

class BooleanParameter extends Parameter {
  bool val;
  late final String Function(bool) evaluate;

  BooleanParameter({required String displayName,
    ParameterInfo? info,
    required bool required,
    required this.val,
    String Function(bool)? evaluate})
      : super(displayName, info, required) {
    if (evaluate == null) {
      this.evaluate = (value) => value.toString();
    } else {
      this.evaluate = evaluate;
    }
  }

  @override
  // TODO: implement code
  String get code {
    return info?.code(evaluate(val)) ?? evaluate(val).toString();
  }

  @override
  // TODO: implement rawValue
  get rawValue => val;

  @override
  // TODO: implement value
  get value => val;
}
