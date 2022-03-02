import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import '../cubit/visual_box_drawer/visual_box_cubit.dart';
import 'operation_model.dart';
import '../code_to_component.dart';
import 'component_model.dart';
import 'other_model.dart';
import '../common/logger.dart';
import '../enums.dart';
import 'parameter_info_model.dart';

abstract class Parameter {
  String? displayName;
  bool isRequired;
  String? Function(ComplexParameter)? validToShow;
  ParameterInfo? info;

  Parameter(this.displayName, this.info, this.isRequired);

  get value;

  get rawValue;

  String code(bool clean);

  bool fromCode(String code) {
    throw UnimplementedError('Unimplemented $displayName $runtimeType');
  }

  void cloneOf(Parameter parameter) {
    if (parameter is SimpleParameter) {
      (this as SimpleParameter).val = parameter.val;
      if (parameter.compilerEnable != null) {
        (this as SimpleParameter).compilerEnable!.code =
            parameter.compilerEnable!.code;
      }
    } else if (parameter is ChoiceParameter) {
      for (int i = 0; i < (this as ChoiceParameter).options.length; i++) {
        (this as ChoiceParameter).options[i].cloneOf(parameter.options[i]);
      }
      if (parameter.val != null) {
        (this as ChoiceParameter).val = (this as ChoiceParameter)
            .options[parameter.options.indexOf(parameter.val!)];
      } else {
        (this as ChoiceParameter).val = null;
      }
    } else if (parameter is ChoiceValueParameter) {
      (this as ChoiceValueParameter).val = parameter.val;
    } else if (parameter is ComplexParameter) {
      for (int i = 0; i < (this as ComplexParameter).params.length; i++) {
        (this as ComplexParameter).params[i].cloneOf(parameter.params[i]);
      }
    } else if (parameter is ListParameter) {
      (this as ListParameter).params.clear();
      for (final param in parameter.params) {
        (this as ListParameter)
            .params
            .add((this as ListParameter).parameterGenerator()
          ..cloneOf(param));
      }
    } else if (parameter is ChoiceValueListParameter) {
      (this as ChoiceValueListParameter).val = parameter.val;
    } else {
      switch (parameter.runtimeType) {
        case BooleanParameter:
          (this as BooleanParameter).val = (parameter as BooleanParameter).val;
          break;
        case ComponentParameter:
          (this as ComponentParameter)
              .components
              .addAll((parameter as ComponentParameter).components);
          break;
      }
    }
  }

  dynamic getValueFromCode<T>(String code) {
    if (T == int) {
      return int.tryParse(code);
    } else if (T == double) {
      return double.tryParse(code);
    } else if (T == String) {
      final codeValue = code;
      final processed =
      codeValue.replaceAll('\\\$', '\$').replaceAll('__quote__', '\'');
      if (code.startsWith('\'') && code.endsWith('\'')) {
        return processed.substring(1, processed.length - 1);
      }
      return processed;
    } else if (T == Color) {
      final colorString = code.replaceAll('Color(', '').replaceAll(')', '');
      return Color(int.parse(colorString));
    } else if (T == ImageData) {
      return ImageData(
          null,
          code
              .replaceAll('\'', '')
              .replaceAll('\\\$', '\$')
              .replaceAll('__quote__', '\''));
    }
    return code;
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

  void withChangeNamed(String? name) {
    if (info != null) {
      if (info is NamedParameterInfo && name != null) {
        (info as NamedParameterInfo).name = name;
      } else if (info is InnerObjectParameterInfo) {
        (info as InnerObjectParameterInfo).namedIfHaveAny = name;
      }
    }
  }

  void withNamedParamInfoAndSameDisplayName(String name) {
    info = NamedParameterInfo(name);
    displayName = name;
  }

  void withInnerNamedParamInfoAndDisplayName(String name,
      String innerObjectName) {
    info = InnerObjectParameterInfo(
        innerObjectName: innerObjectName, namedIfHaveAny: name);
    displayName = name;
  }

  void withNullParamInfoAndParamName() {
    displayName = null;
    info = null;
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
  T? val;
  final ParamInputType inputType;
  late final CompilerEnable? compilerEnable;
  T? defaultValue;

  late final dynamic Function(T) evaluate;
  late dynamic Function(T, bool)? inputCalculateAs;

  SimpleParameter({String? name,
    this.defaultValue,
    this.val,
    this.inputType = ParamInputType.text,
    dynamic Function(T)? evaluate,
    this.inputCalculateAs,
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
    compilerEnable = CompilerEnable();
  }

  @override
  dynamic get value {
    if (compilerEnable != null) {
      final result = compilerEnable!.code.isNotEmpty
          ? ComponentOperationCubit.codeProcessor
          .process<T>(compilerEnable!.code)
          : null;
      if (result != null) {
        val = result as T;
      }
    }
    if (val != null) {
      return evaluate(val!);
    } else if (!isRequired) {
      return null;
    } else if (defaultValue != null) {
      return evaluate(defaultValue!);
    } else if (T == double || T == int) {
      return evaluate(0 as T);
    }
    return '';
  }

  @override
  get rawValue {
    if (compilerEnable != null && compilerEnable!.code.isNotEmpty) {
      final result = ComponentOperationCubit.codeProcessor
          .process<T>(compilerEnable!.code);
      if (result != null) {
        val = result as T;
      }
    }
    if (val != null) {
      return val!;
    } else if (!isRequired) {
      return null;
    } else if (defaultValue != null) {
      return defaultValue!;
    }
    if (T == double || T == int) {
      return 0;
    }
  }

  void setValue(String value) {
    if (value.isEmpty) {
      val = null;
      return;
    }
    if (T == int) {
      val = int.tryParse(value) as T;
    } else if (T == double) {
      val = double.tryParse(value) as T;
    } else {
      val = value as T;
    }
    if (inputCalculateAs != null) {
      val = inputCalculateAs!.call(val!, true);
    }
  }

  T? getValue() {
    if (inputCalculateAs != null) {
      return inputCalculateAs!.call(rawValue as T, false);
    }
    return rawValue;
  }

  void withDefaultValue(T? value) {
    defaultValue = value;
    if (isRequired) {
      val = value;
    }
  }

  @override
  String code(bool clean) {
    if (!isRequired &&
        val == null &&
        (compilerEnable == null || compilerEnable!.code.isEmpty)) {
      return '';
    }
    String tempCode = '';
    if (compilerEnable != null && compilerEnable!.code.isNotEmpty) {
      tempCode = compilerEnable!.code;
      if (!clean) {
        tempCode = '`$tempCode`';
      }
    } else if (T == String) {
      tempCode = '\'${rawValue.replaceAll('\'', '__quote__')}\''
          .replaceAll('\$', '\\\$');
    } else {
      tempCode = '$rawValue';
    }
    if (info != null) {
      return '${info!.code(tempCode)},'.replaceAll(',,', ',');
    }
    return tempCode;
  }

  @override
  bool fromCode(String code) {
    try {
      final paramCode = info?.fromCode(code) ?? code;
      if (paramCode[0] == '`' &&
          paramCode[paramCode.length - 1] == '`' &&
          compilerEnable != null) {
        compilerEnable!.code = paramCode.substring(1, paramCode.length - 1);
      } else {
        val = getValueFromCode<T>(paramCode);
      }
      return true;
    } on Exception {
      logger('SIMPLE PARAMETER FROM CODE EXCEPTION');
    }
    return false;
  }

  process(String value) {
    return ComponentOperationCubit.codeProcessor.process<T>(value);
  }
}

class ListParameter<T> extends Parameter {
  final List<Parameter> params = [];
  final Parameter Function() parameterGenerator;

  ListParameter({String? displayName,
    ParameterInfo? info,
    List<Parameter>? initialParams,
    bool required = true,
    required this.parameterGenerator})
      : super(displayName, info, required) {
    if (initialParams != null) {
      params.addAll(initialParams);
    }
  }

  @override
  String code(bool clean) {
    if (!isRequired && params.isEmpty) {
      return info?.code('') ?? 'null';
    }
    String parametersCode = '[';
    for (final parameter in params) {
      if (parameter.info is InnerObjectParameterInfo) {
        parameter.withInfo(InnerObjectParameterInfo(
            innerObjectName:
            (parameter.info as InnerObjectParameterInfo).innerObjectName));
      }
      parametersCode += '${(parameter).code(clean)},'.replaceAll(',,', ',');
    }
    parametersCode += '],'.replaceAll(',,', ',');
    if (info != null) {
      return '${info!.code(parametersCode)},'.replaceAll(',,', ',');
    }
    return parametersCode;
  }

  @override
  bool fromCode(String code) {
    final processedCode = info?.fromCode(code) ?? code;
    final valueList = CodeOperations.splitByComma(
        processedCode.substring(1, processedCode.length - 1));
    logger('value list $valueList  $code');
    if (valueList.isEmpty) {
      return true;
    }
    if (params.isNotEmpty) {
      for (final parameter in params) {
        final value = valueList.removeAt(0);
        parameter.fromCode(value);
        if (valueList.isEmpty) {
          break;
        }
      }
    }
    for (final value in valueList) {
      if (value.isNotEmpty) {
        params.add(parameterGenerator()
          ..fromCode(value));
      }
    }
    if (params.length >= valueList.length) {
      return true;
    }
    return false;
  }

  @override
  get rawValue {
    return params;
  }

  @override
  get value {
    if (params.isEmpty && !isRequired) {
      return null;
    }
    return params
        .map((e) => e.value)
        .where((element) => element != null)
        .map<T>((e) => e)
        .toList(growable: false);
  }
}

class ChoiceValueParameter extends Parameter {
  final Map<String, dynamic> options;
  dynamic defaultValue;
  final String Function(String)? getCode;
  final String Function(String)? fromCodeToKey;
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
    this.getCode,
    this.fromCodeToKey,
    bool required = true,
    this.val,
    ParameterInfo? info})
      : super(name, info, required);

  @override
  get rawValue {
    return val ?? defaultValue;
  }

  @override
  String code(bool clean) {
    if (info == null || info is SimpleParameterInfo) {
      return getCode != null ? getCode!.call(rawValue) : value.toString();
    }
    return info!
        .code(getCode != null ? getCode!.call(rawValue) : value.toString());
  }

  @override
  bool fromCode(String code) {
    final paramCode = (info?.fromCode(code) ?? code);
    if (fromCodeToKey == null) {
      final option = options.entries
          .firstWhere((element) => element.value.toString() == paramCode);
      val = option.key;
    } else {
      final code = fromCodeToKey!.call(paramCode);
      final option =
      options.entries.firstWhere((element) => element.key == code);
      val = option.key;
    }
    return true;
  }

  void withDefaultValue(dynamic value) {
    defaultValue = value;
    if (isRequired) {
      val = value;
    }
  }
}

class ChoiceValueListParameter<T> extends Parameter {
  final List<dynamic> options;
  final int? defaultValue;
  final Widget Function(dynamic)? dynamicChild;
  int? val;

  @override
  get value {
    if (val != null) {
      return options[val!];
    } else if (defaultValue != null) {
      return options[defaultValue!];
    }
    return null;
  }

  ChoiceValueListParameter({String? name,
    required this.options,
    required this.defaultValue,
    bool required = true,
    this.val,
    this.dynamicChild,
    ParameterInfo? info})
      : super(name, info, required);

  @override
  get rawValue {
    final index = val ?? defaultValue;
    return index != null ? options[index] : null;
  }

  @override
  String code(bool clean) {
    if (info == null || info is SimpleParameterInfo) {
      if (T == String) {
        return '\'${value.toString()}\''.replaceAll(',,', ',');
      }
      return value.toString();
    }
    if (T == String) {
      return '${info!.code('\'${value.toString()}\'')},'.replaceAll(',,', ',');
    }
    return '${info!.code(value.toString())},'.replaceAll(',,', ',');
  }

  @override
  bool fromCode(String code) {
    final paramCode = getValueFromCode<T>(info?.fromCode(code) ?? code);
    val = options.indexWhere((element) => element == paramCode);

    return true;
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

  void resetParameter() {
    val = options[defaultValue];
  }

  String getMetaCode() {
    return '[choice=${val != null ? options.indexOf(val!) : -1}]';
  }

  void fromMetaCode(final String metaCode) {
    final list = metaCode.substring(1, metaCode.length - 1).split('|');
    for (final value in list) {
      if (value.isNotEmpty) {
        final fieldList = value.split('=');
        switch (fieldList[0]) {
          case 'choice':
            final index = int.parse(fieldList[1]);
            if (index == -1) {
              val = null;
            } else {
              val = options[index];
            }
            break;
        }
      }
    }
  }

  @override
  String code(bool clean) {
    final paramCode = (!clean ? getMetaCode() : '') + rawValue.code(clean);
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
  bool fromCode(String code) {
    String paramCode = (info?.fromCode(code) ?? code);
    logger('====== START $paramCode');
    if (paramCode.startsWith('[')) {
      final end = paramCode.indexOf(']') + 1;
      fromMetaCode(paramCode.substring(0,end));
      paramCode=paramCode.replaceRange(0, end, '');
    }
    else {
      val = options[defaultValue];
      if (options.length != 1) {
        for (final parameter in options) {
          logger('TESTING for param ${parameter.displayName}');
          if ((parameter.info is InnerObjectParameterInfo) &&
              (paramCode.startsWith(
                  '${(parameter.info as InnerObjectParameterInfo)
                      .innerObjectName}[') ||
                  paramCode.startsWith(
                      '${(parameter.info as InnerObjectParameterInfo)
                          .innerObjectName}('))) {
            val = parameter;
            break;
          }
          if (paramCode.startsWith('${parameter.info?.getName()}:')) {
            val = parameter;
            break;
          }
          if (paramCode == parameter.code(false)) {
            val = parameter;
            break;
          }
          if (parameter is ComplexParameter) {
            logger('CODESSSS START');
            final codes = CodeOperations.splitByComma(paramCode);
            bool match = true;
            for (final childCode in codes) {
              bool found = false;
              for (final param in parameter.params) {
                final tempCode = param.info?.code('_value_', allowEmpty: true);
                final infoCode =
                tempCode?.substring(0, tempCode.indexOf('_value_'));

                if (param is ListParameter) {
                  if (childCode.startsWith('[') ||
                      childCode.startsWith(param
                          .parameterGenerator()
                          .info
                          ?.code('', allowEmpty: true) ??
                          'N/A')) {
                    found = true;
                  }
                } else if (infoCode != null &&
                    infoCode.isNotEmpty &&
                    childCode.startsWith(infoCode)) {
                  found = true;
                }
              }
              if (!found) {
                match = false;
                break;
              }
            }
            if (!match) {
              continue;
            } else {
              val = parameter;
              break;
            }
          }
        }
      }
    }

    logger('===== FINAL CHOICE ${val!.displayName}');
    val?.fromCode(paramCode);
    return true;
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
  String code(bool clean) {
    String middle = '';
    for (final para in params) {
      final paramCode = para.code(clean);
      if (paramCode.isNotEmpty) {
        middle += '$paramCode,${clean?'\n':''}'.replaceAll(',,', ',');
      }
    }
    return info?.code(middle) ?? middle;
  }

  @override
  bool fromCode(String code) {
    // logger('subcode start $code');
    final paramCodeList =
    CodeOperations.splitByComma((info?.fromCode(code) ?? code));
    // logger('subcode $paramCodeList');
    for (final Parameter parameter in params) {
      // logger('subcode param ${parameter.displayName}');
      if (parameter.info?.isNamed() ?? false) {
        for (final paramCode in paramCodeList) {
          if (paramCode.startsWith('${parameter.info!.getName()}:')) {
            parameter.fromCode(paramCode);
            paramCodeList.remove(paramCode);
            break;
          }
        }
      } else if (paramCodeList.isNotEmpty) {
        final paramCode = paramCodeList.removeAt(0);
        // logger('subcode param trying $paramCode');
        !parameter.fromCode(paramCode);
      } else {
        break;
      }
    }
    return paramCodeList.isEmpty;
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
  String code(bool clean) {
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

  @override
  bool fromCode(String code) => code == constantValueString;
}

class NullParameter extends Parameter {
  NullParameter(
      {String? displayName, ParameterInfo? info, bool required = false})
      : super(displayName, info, required);

  @override
  String code(bool clean) {
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

  @override
  bool fromCode(String code) => code.toLowerCase() == 'null';
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
  String code(bool clean) {
    return info?.code(evaluate(val)) ?? evaluate(val).toString();
  }

  @override
  bool fromCode(String code) {
    final processedCode = info?.fromCode(code) ?? code;
    if (processedCode == 'true' || processedCode == 'false') {
      val = processedCode == 'true';
      return true;
    }
    return false;
  }

  @override
  // TODO: implement rawValue
  get rawValue => val;

  @override
  // TODO: implement value
  get value => val;
}

class ComponentParameter extends Parameter {
  VisualBoxCubit? visualBoxCubit;
  final List<Component> components = [];
  final bool multiple;

  ComponentParameter({
    required this.multiple,
    required ParameterInfo info,
    bool isRequired = false,
  }) : super(info.getName(), info, isRequired);

  void addComponent(final Component component) {
    components.add(component);
  }

  bool isFull() {
    if (multiple) {
      return false;
    }
    return components.isNotEmpty;
  }

  @override
  String code(bool clean) {
    String paramCode = '';
    if (multiple) {
      paramCode += '[\n';
      for (final comp in components) {
        paramCode += '${comp.code(clean: clean)}\n';
      }
      paramCode + '],';
    } else if (components.isNotEmpty) {
      paramCode += components.first.code(clean: clean);
    }
    return info?.code(paramCode) ?? paramCode;
  }

  @override
  bool fromCode(String code) {
    final paramCode = info?.fromCode(code) ?? code;
    if (multiple) {
      final componentCodes = CodeOperations.splitByComma(paramCode);
      for (final compCode in componentCodes) {
        components.add(Component.fromCode(compCode, null)!);
      }
    } else {
      components.add(Component.fromCode(paramCode, null)!);
    }
    return true;
  }

  @override
  get rawValue => components;

  dynamic build() {
    if (multiple) {
      return components
          .map<Widget>(
            (e) =>
            BlocProvider<VisualBoxCubit>(
              create: (_) => visualBoxCubit!,
              child: Builder(
                builder: (context) => e.build(context),
              ),
            ),
      )
          .toList();
    }
    if (components.isNotEmpty) {
      return BlocProvider<VisualBoxCubit>(
        create: (_) => visualBoxCubit!,
        child: Builder(
          builder: (context) => components.first.build(context),
        ),
      );
    }
    return null;
  }

  @override
  get value => components;
}
