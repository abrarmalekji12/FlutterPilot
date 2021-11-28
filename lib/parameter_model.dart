import 'enums.dart';

abstract class ParameterInfo {
  String code(String value);
}

class NamedParameterInfo extends ParameterInfo {
  final String name;

  NamedParameterInfo(this.name);

  @override
  String code(String value) {
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

abstract class Parameter {
  String? displayName;
  bool required;
  ParameterInfo? info;

  Parameter(this.displayName, this.info, this.required);

  get value;

  get rawValue;

  String get code;

  void removeParametersWithName(List<String> parameterNames);

  void withDisplayName(String? name) {
    displayName = name;
  }

  void withInfo(ParameterInfo? info) {
    this.info = info;
  }

  void withRequired(bool required) {
    this.required = required;
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
    } else if(!required){
      return null;
    }else if (defaultValue != null) {
      return evaluate(defaultValue!);
    } else if (paramType == ParamType.double || paramType == ParamType.int) {
      return evaluate(0 as T);
    }
    return '';
  }

  late final dynamic Function(T) evaluate;

  SimpleParameter(
      {String? name,
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
    val=defaultValue;
  }

  @override
  get rawValue {
    if (val != null) {
      return val!;
    }  else if(!required){
      return null;
    }
    else if (defaultValue != null) {
      return defaultValue!;
    }
    if (paramType == ParamType.double || paramType == ParamType.int) {
      return 0;
    }
  }

  void withDefaultValue(T? value) {
    defaultValue = value;
    val=value;
  }

  @override
  void removeParametersWithName(List<String> parameterNames) {
    // TODO: implement removeParametersWithName
    throw UnimplementedError('Please implement this method');
  }

  @override
  // TODO: implement code
  String get code {
    if(!required&&val==null){
      return '';
    }
    if (info != null) {
      if(paramType==ParamType.string){
        return '${info!.code('\'$rawValue\'')},'.replaceAll(',,', ',');
      }
      return '${info!.code('$rawValue')},'.replaceAll(',,', ',');
    }
    if(paramType==ParamType.string) {
      return '\'$rawValue\'';
    }
    return '$rawValue';
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

  ChoiceValueParameter(
      {String? name,
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
  void removeParametersWithName(List<String> parameterNames) {
    // TODO: implement removeParametersWithName
    throw UnimplementedError('Please implement this method');
  }

  @override
  get code => '$displayName:${value.toString()}';
}

class ChoiceParameter extends Parameter {
  final List<Parameter> options;
  final int defaultValue;
  Parameter? val;

  ChoiceParameter(
      {String? name,
      required this.options,
      required this.defaultValue,
      bool required = true,
      this.val,
      ParameterInfo? info})
      : super(name, info, required){
    val=options[defaultValue];
  }

  @override
  get value => val?.value;

  @override
  Parameter get rawValue => val??options[defaultValue];

  @override
  void removeParametersWithName(List<String> parameterNames) {
    List<Parameter> removeList = [];
    for (final param in parameterNames) {
      for (final optionValue in options) {
        if (optionValue.displayName == param) {
          removeList.add(optionValue);
        }
      }
    }
    for (final value in removeList) {
      options.remove(value);
    }
    removeList.clear();
  }

  @override
  get code {
    final paramCode=rawValue.code;
    if(paramCode.isEmpty) {
      return '';
    }
    return info != null ? info!.code(paramCode) : paramCode;
  }
}

class ComplexParameter extends Parameter {
  final List<Parameter> params;
  final dynamic Function(List<Parameter>) evaluate;

  ComplexParameter(
      {String? name,
      required this.params,
      required this.evaluate,
      ParameterInfo? info,
      bool required = true})
      : super(name, info, required);

  @override
  get value => evaluate.call(params);

  @override
  // TODO: implement rawValue
  get rawValue => throw UnimplementedError();

  @override
  void removeParametersWithName(List<String> parameterNames) {
    List<Parameter> removeList = [];
    for (final param in parameterNames) {
      for (final optionValue in params) {
        if (optionValue.displayName == param) {
          removeList.add(optionValue);
        }
      }
    }
    for (final value in removeList) {
      params.remove(value);
    }
    removeList.clear();
  }

  @override
  // TODO: implement code
  get code {
    String middle = '';
    for (final para in params) {
      final paramCode=para.code;
      if(paramCode.isNotEmpty) {
        middle += '$paramCode,'.replaceAll(',,', ',');
      }
    }
    return info?.code(middle) ?? middle;
  }
}
