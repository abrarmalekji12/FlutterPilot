import 'enums.dart';

abstract class ParameterInfo {
  String code(String value);
}

class NamedParameterInfo extends ParameterInfo {
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

abstract class Parameter {
  String? displayName;
  bool required;
  ParameterInfo? info;

  Parameter(this.displayName, this.info, this.required);

  get value;

  get rawValue;

  String get code;

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
class ConstantValueParameter extends Parameter {
  dynamic constantValue;
  late String constantValueString;
  ParamType paramType;
  ConstantValueParameter({String? displayName, ParameterInfo? info,String? constantValueInString,required this.constantValue,required this.paramType}) : super(displayName, info, true){
    if(constantValueInString!=null){
      constantValueString=constantValueInString;
    }
    else{
     constantValueString=constantValue.toString();
    }
  }

  @override
  // TODO: implement code
  String get code {
   if(info==null||info is SimpleParameterInfo) {
     if(paramType==ParamType.string){
       return '\'$constantValueString}\'';
     }
     return constantValueString;
   }
   return info!.code(paramType==ParamType.string?'\'$constantValueString}\'':constantValueString);
  }

  @override
  get rawValue => constantValue;

  @override
  get value => constantValue;

}
class NullParameter extends Parameter{
  NullParameter({String? displayName, ParameterInfo? info, bool required=false}) : super(displayName, info, required);
  @override
  String get code{
   if((info is InnerObjectParameterInfo&&(info as InnerObjectParameterInfo).namedIfHaveAny==null)||info==null) {
     return 'null';
   }
   return '';
  }

  @override
  get rawValue => null;


  @override
  get value => null;

}
