import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:get/get.dart';

import '../code_operations.dart';
import '../collections/project_info_collection.dart';
import '../common/converter/string_operation.dart';
import '../common/logger.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/visual_box_drawer/visual_box_cubit.dart';
import '../enums.dart';
import '../injector.dart';
import 'fvb_ui_core/component/component_model.dart';
import 'input_types/range_input.dart';
import 'operation_model.dart';
import 'other_model.dart';
import 'parameter_info_model.dart';
import 'project_model.dart';

final UserProjectCollection _collection = sl<UserProjectCollection>();

mixin UsableParam {
  String? usableName;

  bool get reused {
    if (usableName == null) {
      return false;
    }
    if (_collection.project!.commonParams.firstWhereOrNull((element) =>
            element.name == usableName &&
            element.parameter.equals(this as Parameter)) ==
        null) {
      usableName = null;
      return false;
    }
    return _collection.project!.commonParams.firstWhereOrNull(
            (element) => element.parameter == (this as Parameter)) ==
        null;
  }

  CommonParam? get commonParam => _collection.project!.commonParams
      .firstWhereOrNull((element) => element.name == usableName);

  String get outputUsableCode {
    final commonParam = _collection.project!.commonParams
        .firstWhereOrNull((element) => element.name == usableName);
    String usableCode;
    if (commonParam != null) {
      usableCode = '${commonParam.className}.${usableName}';
    } else {
      throw Exception(
          'Common parameter $usableName not found in project, available params are ${_collection.project!.commonParams.map((e) => e.parameter).join(',')}');
    }
    if ((this as Parameter).info.isNamed()) {
      return '${(this as Parameter).info.getName()!}:$usableCode';
    }
    return usableCode;
  }

  void fromUsableMetaCode(List<String> fieldList) {
    switch (fieldList[0]) {
      case 'usable':
        usableName = fieldList[1];

        break;
      case 'inherited':
        if (fieldList[1] == '1') {
          _collection.project!.commonParams
              .add(CommonParam((this as Parameter), usableName!));
        }
    }
  }

  Map<String, dynamic> get usableToJson => {
        'usable': usableName,
        'inherited': reused,
      };

  usableFromJson(Map<String, dynamic> json, FVBProject project) {
    usableName = json['usable'];
    if (json['inherited'] == true) {
      project.commonParams.add(CommonParam((this as Parameter), usableName!));
    }
  }

  String get usableMetaCode {
    if (usableName != null) {
      return 'usable=$usableName|inherited=${reused ? 0 : 1}';
    }
    return '';
  }

  get usableValue {
    if (usableName != null) {
      final param = _collection.project!.commonParams
          .firstWhereOrNull((element) =>
              (element.parameter as UsableParam).usableName == usableName)
          ?.parameter;
      if (param != null) {
        return param.value;
      }
    }
  }

  Parameter? get usedParameter {
    return _collection.project!.commonParams
        .firstWhereOrNull((element) =>
            (element.parameter as UsableParam).usableName == usableName)
        ?.parameter;
  }

  get usableRawValue {
    if (usableName != null) {
      final param = _collection.project!.commonParams
          .firstWhereOrNull((element) =>
              (element.parameter as UsableParam).usableName == usableName)
          ?.parameter;
      if (param != null) {
        return param.rawValue;
      }
    }
  }
}

abstract class Parameter {
  String? displayName;
  VisualConfig? config;
  final CompilerEnable compiler = CompilerEnable();
  bool isRequired;
  String? Function(ComplexParameter)? validToShow;
  late ParameterInfo info;
  final bool generateCode;
  String? id;

  Parameter(String? displayName, ParameterInfo? info, this.isRequired,
      {this.generateCode = true, this.config, this.id}) {
    this.info = info ?? SimpleParameterInfo();
    this.displayName = (displayName != null
        ? StringOperation.toNormalCase(displayName)
        : null);
  }

  String? get idName => (info.getName() ?? displayName)?.toLowerCase();

  get value;

  get rawValue;

  void setCode(String? code) {
    if (code != null) {
      if (this is SimpleParameter) {
        compiler.code = code;
        (this as SimpleParameter).enable = true;
      }
    }
  }

  Map<String, dynamic> toJson() {
    final meta = toMetaJson;
    return {
      if (compiler.code.isNotEmpty) 'code': compiler.code,
      if (this is UsableParam && (this as UsableParam).usableName != null)
        'usable': (this as UsableParam).usableToJson,
    }..addAll(meta ?? {});
  }

  void fromJson(Map<String, dynamic> map, FVBProject? project) {
    if (map['meta'] != null) {
      metaFromJson(map['meta']);
    } else {
      metaFromJson(map);
    }
    compiler.code = map['code'] ?? '';
    if (this is UsableParam && map['usable'] != null && project != null) {
      (this as UsableParam).usableFromJson(map['usable'], project);
    }
  }

  Map<String, dynamic>? get toMetaJson => null;

  metaFromJson(Map<String, dynamic> json) {}

  bool isEqual(Parameter parameter) {
    if (parameter.runtimeType == runtimeType) {
      return equals(parameter);
    }
    return false;
  }

  bool equals(Parameter parameter);

  @nonVirtual
  String get metaCode {
    String metaCodeOutput = '[';
    if (this is UsableParam) {
      final usable = (this as UsableParam).usableMetaCode;
      if (usable.isNotEmpty) metaCodeOutput += usable + '|';
    }
    if (this is SimpleParameter) {
      metaCodeOutput += 'enable=${(this as SimpleParameter).enable}';
    } else if (this is ChoiceParameter) {
      metaCodeOutput +=
          'choice=${((this as ChoiceParameter).val) != null ? (this as ChoiceParameter).selectedIndex : -1}' +
              '|';
    } else if (this is ComplexParameter) {
      metaCodeOutput += 'enable=${(this as ComplexParameter).enable}';
    }
    if (metaCodeOutput.length == 1) {
      return '';
    }

    metaCodeOutput += ']';
    return metaCodeOutput;
  }

  String code(bool output);

  bool fromCode(String code, FVBProject? project) {
    throw UnimplementedError('Unimplemented $displayName $runtimeType');
  }

  void fromMetaCode(final String metaCode) {
    if (metaCode.length < 3) {
      return;
    }
    final list = metaCode.substring(1, metaCode.length - 1).split('|');
    for (final value in list) {
      if (value.isNotEmpty) {
        final fieldList = value.split('=');
        switch (fieldList[0]) {
          case 'enable':
            if (this is SimpleParameter) {
              (this as SimpleParameter).enable = (fieldList[1] == 'true');
            } else if (this is ComplexParameter) {
              (this as ComplexParameter).enable = (fieldList[1] == 'true');
            }
            break;
          case 'choice':
            if (this is ChoiceParameter) {
              final index = int.parse(fieldList[1]);
              if (index == -1) {
                (this as ChoiceParameter).val = null;
              } else if (index < (this as ChoiceParameter).options.length) {
                (this as ChoiceParameter).val =
                    (this as ChoiceParameter).options[index];
              }
            }
            break;
          default:
            if (this is UsableParam) {
              (this as UsableParam).fromUsableMetaCode(fieldList);
            }
        }
      }
    }
  }

  void cloneOf(Parameter parameter, bool connect) {
    if (parameter is UsableParam && this is UsableParam) {
      (this as UsableParam).usableName = (parameter as UsableParam).usableName;
    }
    if (parameter is SimpleParameter) {
      (this as SimpleParameter)
        ..val = parameter.val
        ..compiler.code = parameter.compiler.code
        ..enable = parameter.enable;
    } else if (parameter is ChoiceParameter) {
      for (int i = 0; i < (this as ChoiceParameter).options.length; i++) {
        (this as ChoiceParameter)
            .options[i]
            .cloneOf(parameter.options[i], connect);
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
        (this as ComplexParameter)
            .params[i]
            .cloneOf(parameter.params[i], connect);
        (this as ComplexParameter).enable = parameter.enable;
      }
    } else if (parameter is ListParameter) {
      (this as ListParameter).params.clear();
      for (final param in parameter.params) {
        (this as ListParameter).params.add(
            (this as ListParameter).parameterGenerator()
              ..cloneOf(param, connect));
      }
    } else if (parameter is CodeParameter) {
      (this as CodeParameter).actionCode = parameter.actionCode;
    } else if (parameter is ChoiceValueListParameter) {
      (this as ChoiceValueListParameter).val = parameter.val;
    } else {
      switch (parameter.runtimeType) {
        case BooleanParameter:
          (this as BooleanParameter).val = (parameter as BooleanParameter).val;
          break;
        case ComponentParameter:
          (this as ComponentParameter).components.clear();
          (this as ComponentParameter).components.addAll(
              (parameter as ComponentParameter)
                  .components
                  .map((e) => e.clone(this, deepClone: true, connect: false)));
      }
    }
  }

  static dynamic getValueFromCode<T>(String code) {
    if (T == int) {
      return int.tryParse(code);
    } else if (T == double) {
      return double.tryParse(code);
    } else if (T == String) {
      final codeValue = code;
      final processed = codeValue.replaceAll('__quote__', '\'');
      if (processed.startsWith('\'') && processed.endsWith('\'')) {
        return processed.substring(1, processed.length - 1);
      }
      return processed;
    } else if (T == Color) {
      final colorString = code.replaceAll('Color(', '').replaceAll(')', '');
      return Color(int.parse(colorString));
    } else if (T == FVBImage) {
      return FVBImage(
          name: code
              .replaceAll('\'', '')
              .replaceAll('"', '')
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
    displayName = name != null ? StringOperation.toNormalCase(name) : null;
  }

  void withInfo(ParameterInfo? info) {
    this.info = info ?? SimpleParameterInfo();
  }

  void withChangeNamed(String? name) {
    if (info is NamedParameterInfo) {
      if (name != null) {
        info = (info as NamedParameterInfo).copyWith(name: name);
      } else {
        info = SimpleParameterInfo();
      }
    } else if (info is InnerObjectParameterInfo) {
      info = (info as InnerObjectParameterInfo)
          .copyWith(namedIfHaveAny: name, removeName: name == null);
    }
  }

  void withNamedParamInfoAndSameDisplayName(String name,
      {bool optional = true, bool inner = false}) {
    if (inner && info is InnerObjectParameterInfo) {
      info = InnerObjectParameterInfo(
          innerObjectName: (info as InnerObjectParameterInfo).innerObjectName,
          isOptional: info.optional,
          namedIfHaveAny: name);
    } else {
      info = NamedParameterInfo(name,
          defaultValue: (info is NamedParameterInfo)
              ? (info as NamedParameterInfo).defaultValue
              : null,
          isOptional: optional);
    }
    displayName = StringOperation.toNormalCase(name);
  }

  void withInnerNamedParamInfoAndDisplayName(
      String name, String innerObjectName) {
    info = InnerObjectParameterInfo(
        innerObjectName: innerObjectName, namedIfHaveAny: name);
    displayName = StringOperation.toNormalCase(name);
  }

  void withNullParamInfoAndParamName() {
    displayName = null;
    info = SimpleParameterInfo();
  }

  void withRequired(bool required, {String nullParameterName = 'None'}) {
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
        case ComplexParameter:
          (this as ComplexParameter).enable = isRequired;
      }
    }
  }

  bool forEach(bool Function(Parameter p0) param0) {
    if (param0.call(this)) {
      return true;
    }
    if (this is ComplexParameter) {
      for (final param in (this as ComplexParameter).params) {
        if (param.forEach(param0)) {
          return true;
        }
      }
    } else if (this is ChoiceParameter) {
      for (final param in (this as ChoiceParameter).options) {
        if (param.forEach(param0)) {
          return true;
        }
      }
    }
    return false;
  }
}

class BooleanParameter extends Parameter with UsableParam {
  bool? val;
  late final String Function(bool?) evaluate;

  BooleanParameter(
      {required String displayName,
      ParameterInfo? info,
      super.config,
      required bool required,
      required this.val,
      String Function(bool?)? evaluate,
      super.generateCode})
      : super(displayName, info, required) {
    if (evaluate == null) {
      this.evaluate = (value) => value.toString();
    } else {
      this.evaluate = evaluate;
    }
  }

  @override
  String code(bool clean) {
    if (clean && usableName != null) {
      return outputUsableCode;
    }
    if (compiler.code.isNotEmpty && !clean) {
      return info.code('${!clean ? metaCode : ''}`${compiler.code}`');
    }
    final innerCode = (!clean ? metaCode : '') + evaluate(val);
    return info.code(innerCode);
  }

  @override
  bool fromCode(String code, FVBProject? project) {
    String paramCode = info.fromCode(code);
    if (paramCode.startsWith('[')) {
      final end = paramCode.indexOf(']') + 1;
      fromMetaCode(paramCode.substring(0, end));
      paramCode = paramCode.substring(end);
    }
    if (paramCode.isNotEmpty &&
        paramCode[0] == '`' &&
        paramCode[paramCode.length - 1] == '`') {
      compiler.code = paramCode.substring(1, paramCode.length - 1);
    } else {
      if (paramCode == 'true' || paramCode == 'false') {
        val = paramCode == 'true';
        return true;
      }
    }
    return false;
  }

  @override
  get rawValue {
    if (reused) {
      return usableRawValue;
    }
    final result = compiler.code.isNotEmpty ? process(compiler.code) : null;
    if (result != null) {
      val = result;
    }
    return val;
  }

  dynamic process(String value, {Processor? processor, Component? component}) {
    final oldError = Processor.errorMessage;
    Processor.error = false;
    final execute = (processor ?? OperationCubit.paramProcessor);
    final comp = component ?? processComponent;
    final outputCache = execute.process<bool>(CodeOperations.trim(value)!,
        extendedError:
            '${processor == null ? comp?.id : ''} => ${displayName ?? ''}',
        config: const ProcessorConfig());
    final output = outputCache.value;
    final cubit = sl<SelectionCubit>();
    if (oldError != Processor.errorMessage &&
        Processor.error &&
        !execute.errorSuppress) {
      cubit.showError(
          comp!, Processor.errorMessage, AnalysisErrorType.parameter,
          param: this);
    }
    if (output != null && output is! bool) {
      if (!execute.errorSuppress)
        (processor ?? OperationCubit.paramProcessor)
            .enableError('Can\'t assign ${output.runtimeType} to boolean');
      else {
        return false;
      }
    }
    return output;
  }

  @override
  get value {
    if (reused) {
      return usableValue;
    }
    final result = compiler.code.isNotEmpty ? process(compiler.code) : null;
    if (result != null) {
      if (result is bool)
        val = result;
      else {}
    }
    return val;
  }

  @override
  bool equals(Parameter parameter) {
    return true;
  }
}

class VisualConfig {
  final double? width;
  final String? image;
  final IconData? icon;
  final int? maxLines;
  final bool? labelVisible;

  const VisualConfig({
    this.width,
    this.image,
    this.icon,
    this.maxLines,
    this.labelVisible,
  });
}

class SimpleParameter<T> extends Parameter with UsableParam {
  T? val;
  final ParamInputType inputType;
  T? defaultValue;
  bool enable;
  SimpleInputOption? options;
  late final dynamic Function(T) evaluate;
  late dynamic Function(T, bool)? inputCalculateAs;
  final String? Function(T)? validate;
  final String? initialValue;
  final String? generic;

  SimpleParameter(
      {String? name,
      this.validate,
      super.config,
      this.options,
      this.generic,
      this.initialValue,
      this.defaultValue,
      this.val,
      this.enable = true,
      this.inputType = ParamInputType.simple,
      dynamic Function(T)? evaluate,
      this.inputCalculateAs,
      super.generateCode,
      bool required = true,
      ParameterInfo? info})
      : super(
          name,
          info,
          required,
        ) {
    if (evaluate != null) {
      this.evaluate = evaluate;
    } else {
      this.evaluate = (value) => value;
    }
    isRequired = required;
    if (!required && defaultValue == null) {
      enable = false;
    }
    if (required) {
      val = defaultValue;
    }
  }

  @override
  Map<String, dynamic>? get toMetaJson => {
        'enable': enable,
      };

  @override
  metaFromJson(Map<String, dynamic> json) {
    enable = (json['enable'] ?? true);
  }

  @override
  dynamic get value {
    if (reused) {
      return usableValue;
    }
    if (!enable) {
      if (defaultValue != null) {
        return evaluate(defaultValue!);
      } else {
        return null;
      }
    }
    final processor = OperationCubit.paramProcessor;
    val = null;
    final resultCache = process(compiler.code, processor: processor);
    final result = resultCache.value;
    if (result != null && result is! FVBUndefined) {
      if (T == Color) {
        if (result is FVBInstance && result.fvbClass.name == 'Color') {
          val = result.variables['_dart']?.value;
        } else {
          val = hexToColor(result.toString()) as T?;
        }
      } else if (T == FVBImage) {
        val = FVBImage(bytes: byteCache[result], name: result) as T;
      } else {
        if (T == double && result is int) {
          val = result.toDouble() as T;
        } else if (T == int && result is double) {
          val = result.toInt() as T;
        } else if (T == Uint8List) {
          val = result as T;
        } else if (result is FVBInstance) {
          final v = result.toDart();
          if (v is T ||
              (validate != null && (validate?.call(result as T)) == null)) {
            val = v as T;
          }
        } else if (T == dynamic || result.runtimeType == T) {
          val = result;
        }

        if (generic != null) {}
        if (validate != null && val != null) {
          final msg = validate?.call(val!);
          if (msg != null) {
            Processor.error = true;
            Processor.errorMessage = msg;
            if (defaultValue != null) {
              return evaluate(defaultValue!);
            }
            return null;
          }
        }

        if (val is FVBInstance) {
          return (val as FVBInstance).toDart();
        }
      }
    }
    if (val != null) {
      return evaluate(val!);
    } else if (!isRequired) {
      return null;
    } else if (defaultValue != null) {
      return evaluate(defaultValue!);
    } else if (T == int) {
      return evaluate(0 as T);
    } else if (T == double) {
      return evaluate(0.0 as T);
    } else if (T == String) {
      return evaluate('' as T);
    }
    return null;
  }

  @override
  get rawValue {
    try {
      if (reused) {
        return usableRawValue;
      }
      if (!enable) {
        return defaultValue;
      }
      val = null;
      if (compiler.code.isNotEmpty) {
        final resultCache = process(compiler.code);
        final result = resultCache.value;
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
    } on Exception catch (e) {
      print('get rawvalue Error $e');
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
    } else if (T == String) {
      val = value as T;
    } else {
      val = value as T;
    }
    if (inputCalculateAs != null) {
      val = inputCalculateAs!.call(val!, true);
    }
  }

  T? getValue() {
    if (reused) {
      final rowValue = usableRawValue;
      if (T == double && rowValue.runtimeType == int) {
        return (rowValue as int).toDouble() as T;
      }
      return rowValue;
    }
    if (!enable) {
      return null;
    }
    if (inputCalculateAs != null) {
      return inputCalculateAs!.call(rawValue as T, false);
    }
    final rowValue = rawValue;
    if (T == double && rowValue.runtimeType == int) {
      return (rowValue as int).toDouble() as T;
    }
    return rowValue;
  }

  void withDefaultValue(T? value) {
    defaultValue = value;
    val = defaultValue;
  }

  Type get type {
    return T;
  }

  @override
  String code(bool clean) {
    if (clean && !generateCode) {
      return '';
    }
    try {
      if (clean) {
        if (usableName != null) {
          return outputUsableCode;
        } else if (!enable) {
          return info.optional ? '' : info.code('null');
        }
      }
      if (reused) {
        return info.code(metaCode);
      }
      if ((!isRequired &&
          val == null &&
          (compiler.code.isEmpty) &&
          info.getName() != null)) {
        return !clean ? info.code(metaCode) : '';
      }
      String tempCode = '';
      if (compiler.code.isNotEmpty || T == String) {
        tempCode = compiler.code;
        if (!clean) {
          tempCode = '`$tempCode`';
        } else if (T == String) {
          if (tempCode.contains('\n')) {
            tempCode = '\'\'\'${tempCode}\'\'\'';
          } else {
            tempCode = '"${tempCode}"';
          }
        } else if (T == Color) {
          tempCode =
              '${tempCode.startsWith('#') ? 'hexToColor(\'$tempCode\')' : tempCode}';
        } else if (T == FVBImage) {
          tempCode = '\'assets/images/$tempCode\'';
        }
      } else if (T == int || T == double) {
        tempCode = '$rawValue';
      } else if (info is SimpleParameterInfo) {
        tempCode = 'null';
      }

      return '${info.code('${!clean ? metaCode : ''}${tempCode}')}';
    } on Exception catch (e) {
      e.printError();
      print('SIMPLE PARAM ERROR ${e.toString()}');
      return info.code('');
    }
  }

  @override
  bool fromCode(String code, FVBProject? project) {
    try {
      String paramCode = info.fromCode(code);
      if (paramCode.startsWith('[')) {
        final end = paramCode.indexOf(']') + 1;
        fromMetaCode(paramCode.substring(0, end));
        paramCode = paramCode.substring(end);
      }
      if (paramCode.isNotEmpty &&
          paramCode[0] == '`' &&
          paramCode.length >= 2 &&
          paramCode[paramCode.length - 1] == '`') {
        compiler.code = paramCode.substring(1, paramCode.length - 1);

        if (T == FVBImage) {
          val = FVBImage(
              name: OperationCubit.paramProcessor
                  .process<String>(
                      compiler.code
                          .replaceAll('\'', '')
                          .replaceAll('\\\$', '\$')
                          .replaceAll('__quote__', '\''),
                      config: const ProcessorConfig())
                  .value) as T;
        } else if (T == Color) {
          if (compiler.code.startsWith('#')) {
            compiler.code = '"${compiler.code}"';
          }
        }
      } else {
        val = Parameter.getValueFromCode<T>(paramCode);
      }
      return true;
    } on Exception {
      logger('SIMPLE PARAMETER FROM CODE EXCEPTION');
    }
    return false;
  }

  FVBCacheValue process(String value,
      {Processor? processor, Component? component}) {
    final code =
        (T == String || T == FVBImage) ? value : CodeOperations.trim(value)!;
    final oldError = Processor.errorMessage;

    Processor.error = false;
    Processor.operationType = OperationType.regular;

    final execute = (processor ?? OperationCubit.paramProcessor);
    final processedOutput =
        execute.process<T>(code, config: const ProcessorConfig());
    final output = processedOutput.value;
    final cubit = sl<SelectionCubit>();
    final comp = component ?? processComponent;
    if (oldError != Processor.errorMessage &&
        Processor.error &&
        !execute.errorSuppress &&
        comp != null) {
      cubit.showError(comp, Processor.errorMessage, AnalysisErrorType.code,
          param: this);
    }
    if (output != null &&
        (T != dynamic &&
            (!((output is String || output is FVBInstance) && T == Color) &&
                !(output is String && T == FVBImage) &&
                !(output is FVBInstance &&
                    (output.fvbClass.name == 'Future' ||
                        output.fvbClass.name == (T).toString())) &&
                (!(output is int && T == double)) &&
                (output.runtimeType != T)))) {
      if (!execute.errorSuppress) {
        (processor ?? OperationCubit.paramProcessor)
            .enableError('Can\'t assign ${output.runtimeType} to $T');
      } else {
        final t = elseReturn;
        if (t != null) {
          return t;
        }
      }
    }
    return processedOutput;
  }

  get elseReturn {
    if (T == int) {
      return 1;
    } else if (T == String) {
      return '';
    } else if (T == double) {
      return 1.0;
    } else if (T == Color) {
      return Colors.black;
    } else if (T == FVBImage) {
      return '';
    }
  }

  @override
  bool equals(Parameter parameter) {
    if (parameter is! SimpleParameter) {
      return false;
    }
    return T == parameter.type;
  }
}

class CodeParameter<T> extends Parameter {
  String actionCode;
  final String Function(String)? toDartCode;
  final T Function(Processor)? evaluate;
  final void Function(String, List<dynamic>) apiBindCallback;
  final List<FVBFunction> functions;

  CodeParameter(
    super.displayName,
    super.info,
    super.isRequired, {
    this.actionCode = '',
    this.toDartCode,
    required this.functions,
    required this.apiBindCallback,
    this.evaluate,
  });

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..addAll({'actionCode': actionCode});
  }

  @override
  void fromJson(Map<String, dynamic> map, FVBProject? project) {
    super.fromJson(map, project);
    actionCode = map['actionCode'] ?? '';
  }

  @override
  bool fromCode(String code, FVBProject? project) {
    if (code.isNotEmpty) {
      final extractedCode = info.fromCode(code);
      actionCode = String.fromCharCodes(
          base64Decode(extractedCode.substring(1, extractedCode.length - 1)));
    }
    return true;
  }

  @override
  String code(bool clean) {
    /// TODO: uncomment when this will be usable
    // if(clean&&usableName!=null){
    //   return outputUsableCode;
    // }
    if (!clean) {
      return info.code('"${base64Encode(actionCode.codeUnits)}"');
    } else {
      //toDartCode?.call(actionCode) ?? actionCode
      return info
          .code('${StringOperation.toCamelCase(displayName!)}${hashCode}()');
    }
  }

  @override
  get rawValue {
    throw Exception('Unimplemented');
  }

  execute() {
    Processor.error = false;
    final Processor processor = Processor(
        parentProcessor: OperationCubit.paramProcessor,
        scopeName: 'codep:$displayName',
        consoleCallback: Processor.defaultConsoleCallback,
        onError: Processor.defaultOnError);
    processor.functions.addAll(
      functions.asMap().map(
            (key, value) => MapEntry(value.name, value),
          ),
    );
    processor.executeCode(actionCode, config: const ProcessorConfig());
    return evaluate!.call(processor);
  }

  @override
  T get value {
    return execute();
  }

  Type get type => T;

  @override
  bool equals(Parameter parameter) {
    if (parameter is! CodeParameter) {
      return false;
    }
    return T == parameter.type;
  }
}

class ListParameter<T> extends Parameter with UsableParam {
  final List<Parameter> params = [];
  final Parameter Function() parameterGenerator;

  ListParameter(
      {String? displayName,
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
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(
        {
          'params': params.map((e) => e.toJson()).toList(),
        },
      );
  }

  @override
  void fromJson(Map<String, dynamic> map, FVBProject? project) {
    super.fromJson(map, project);
    params.addAll(List.from(map['params'] ?? [])
        .map((e) => parameterGenerator()..fromJson(e, project)));
  }

  @override
  String code(bool clean) {
    if (!clean && reused) {
      return info.code(metaCode);
    }
    if (!isRequired && params.isEmpty) {
      return info.code(clean ? '' : metaCode);
    }
    String parametersCode = '[';
    for (final parameter in params) {
      if (parameter.info is InnerObjectParameterInfo) {
        parameter.withInfo(InnerObjectParameterInfo(
            innerObjectName:
                (parameter.info as InnerObjectParameterInfo).innerObjectName));
      }
      final pCode = (parameter).code(clean);
      if (pCode.isNotEmpty) {
        parametersCode += '${pCode},';
      }
    }
    parametersCode += ']';
    return '${info.code((clean ? '' : metaCode) + parametersCode)}';
  }

  @override
  bool fromCode(String code, FVBProject? project) {
    String processedCode = info.fromCode(code);
    if (processedCode.startsWith('[usable=')) {
      final end = processedCode.indexOf(']') + 1;
      fromMetaCode(processedCode.substring(0, end));
      if (processedCode.length > end)
        processedCode = processedCode.substring(end);
      else {
        return true;
      }
    }
    if (processedCode.length < 3) {
      return true;
    }
    final valueList = CodeOperations.splitBy(
        processedCode.substring(1, processedCode.length - 1));
    if (valueList.isEmpty) {
      return true;
    }
    if (params.isNotEmpty) {
      for (final parameter in params) {
        final value = valueList.removeAt(0);
        parameter.fromCode(value, project);
        if (valueList.isEmpty) {
          break;
        }
      }
    }
    for (final value in valueList) {
      if (value.isNotEmpty) {
        params.add(parameterGenerator()..fromCode(value, project));
      }
    }
    if (params.length >= valueList.length) {
      return true;
    }
    return false;
  }

  @override
  get rawValue {
    if (reused) {
      return usableRawValue;
    }
    return params;
  }

  @override
  get value {
    if (reused) {
      return usableValue;
    }
    if (params.isEmpty && !isRequired) {
      return null;
    }
    return params
        .map((e) => e.value)
        .where((element) => element != null)
        .map<T>((e) => e)
        .toList(growable: false);
  }

  Type get type => T;

  @override
  bool equals(Parameter parameter) {
    if (parameter is! ListParameter) {
      return false;
    }
    return T == parameter.type;
  }
}

class ChoiceValueParameter extends Parameter with UsableParam {
  final Map<String, dynamic> options;
  dynamic defaultValue;
  final String Function(String)? getCode;
  final String Function(String)? fromCodeToKey;
  final Widget Function(dynamic)? getClue;
  dynamic val;

  @override
  get value {
    if (reused) {
      return usableValue;
    }
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
      this.getCode,
      super.config,
      this.getClue,
      this.fromCodeToKey,
      bool required = true,
      this.val,
      ParameterInfo? info})
      : super(name, info, required);

  @override
  get rawValue {
    if (reused) {
      return usableRawValue;
    }
    if (val == null && isRequired) {
      return defaultValue;
    }
    return val;
  }

  void update(String? key) {
    val = key;
  }

  @override
  String code(bool clean) {
    if (clean && usableName != null) {
      return outputUsableCode;
    }
    final toValue = value;
    if (toValue == null) {
      if (info.optional) {
        return (!clean ? metaCode : '');
      } else {
        return info.code((!clean ? metaCode : '') + toValue.toString());
      }
    }
    final gCode = (!clean ? metaCode : '') +
        (getCode != null ? getCode!.call(rawValue) : toValue.toString());
    return info.code(gCode);
  }

  @override
  toJson() {
    final json = super.toJson();
    json['value'] = val;
    return json;
  }

  @override
  fromJson(Map<String, dynamic> map, FVBProject? project) {
    super.fromJson(map, project);
    val = map['value'];
  }

  @override
  bool fromCode(String code, FVBProject? project) {
    String paramCode = info.fromCode(code);

    if (paramCode.startsWith('[')) {
      final end = paramCode.indexOf(']') + 1;
      fromMetaCode(paramCode.substring(0, end));
      paramCode = paramCode.replaceRange(0, end, '');
    }
    if (paramCode != 'null' && paramCode != 'null()') {
      if (fromCodeToKey == null) {
        final option = options.entries.firstWhereOrNull(
            (element) => element.value.toString() == paramCode);
        val = option?.key;
      } else {
        val = fromCodeToKey!.call(paramCode);
        assert(options.containsKey(val),
            'ChoiceValueParameter $displayName :: "$val" not found in $options $paramCode');
      }
    } else {
      val = null;
    }
    return true;
  }

  void withDefaultValue(dynamic value) {
    defaultValue = value;
    if (isRequired) {
      val = value;
    }
  }

  @override
  bool equals(Parameter parameter) {
    if (parameter is! ChoiceValueParameter) {
      return false;
    }
    return mapEquals(options, parameter.options);
  }
}

class ChoiceValueListParameter<T> extends Parameter with UsableParam {
  final List<T> options;
  final Widget Function(String)? getClue;
  final int? defaultValue;
  final Widget Function(dynamic)? dynamicChild;
  int? val;

  @override
  get value {
    if (reused) {
      return usableValue;
    }
    if (val != null) {
      if (val! < 0 || val! >= options.length) {
        return options[0];
      }
      return options[val!];
    } else if (defaultValue != null) {
      return options[defaultValue!];
    }
    return null;
  }

  ChoiceValueListParameter(
      {String? name,
      required this.options,
      required this.defaultValue,
      bool required = true,
      this.val,
      this.getClue,
      super.config,
      this.dynamicChild,
      ParameterInfo? info})
      : super(name, info, required);

  @override
  get rawValue {
    if (reused) {
      return usableRawValue;
    }
    final index = val ?? defaultValue;
    return index != null ? options[index] : null;
  }

  @override
  toJson() {
    return super.toJson()..addAll({'val': val});
  }

  @override
  fromJson(Map<String, dynamic> map, FVBProject? project) {
    super.fromJson(map, project);
    val = map['val'];
  }

  @override
  String code(bool clean) {
    if (clean && usableName != null) {
      return outputUsableCode;
    }
    if (T == String) {
      return '${info.code('${!clean ? metaCode : ''}\'${value.toString()}\'')}';
    }
    return '${info.code('${!clean ? metaCode : ''}${value.toString()}')}';
  }

  @override
  bool fromCode(String code, FVBProject? project) {
    String infoCode = info.fromCode(code);
    if (infoCode.startsWith('[')) {
      final end = infoCode.indexOf(']') + 1;
      fromMetaCode(infoCode.substring(0, end));
      infoCode = infoCode.replaceRange(0, end, '');
    }
    final paramCode = Parameter.getValueFromCode<T>(infoCode);
    val = options.indexWhere((element) => element == paramCode);

    return true;
  }

  @override
  bool equals(Parameter parameter) {
    if (parameter is! ChoiceValueListParameter) {
      return false;
    }
    return listEquals(options, parameter.options);
  }
}

class ChoiceParameter extends Parameter with UsableParam {
  final List<Parameter> options;
  final int defaultValue;
  Parameter? val;
  final void Function(Parameter?, Parameter?)? onChange;
  String? nullParameterName;

  ChoiceParameter(
      {String? name,
      this.onChange,
      this.defaultValue = 0,
      required this.options,
      bool required = true,
      this.val,
      super.id,
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

  Parameter update(int i) {
    return val = options[i];
  }

  void updateParam(Parameter? parameter) {
    if (parameter != val) {
      if (onChange != null) {
        onChange?.call(val, parameter);
      }
      val = parameter;
    }
  }

  @override
  Map<String, dynamic>? get toMetaJson => {
        'choice': selectedIndex,
      };

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll({'val': val?.toJson()});

  @override
  void fromJson(Map<String, dynamic> map, FVBProject? project) {
    super.fromJson(map, project);
    if (map['val'] != null) val?.fromJson(map['val'], project);
  }

  @override
  metaFromJson(Map<String, dynamic> json) {
    if (json['choice'] != null &&
        json['choice'] != -1 &&
        options.length > json['choice']) {
      val = options[json['choice']];
    }
  }

  @override
  get value {
    if (reused) {
      return usableValue;
    }
    return val?.value;
  }

  @override
  Parameter get rawValue {
    if (reused) {
      return usableRawValue;
    }
    return val ?? options[defaultValue];
  }

  int get selectedIndex => val != null ? options.indexOf(val!) : -1;

  void resetParameter() {
    val = options[defaultValue];
  }

  @override
  String code(bool clean) {
    if (clean && usableName != null) {
      return outputUsableCode;
    }
    final paramCode = (!clean ? metaCode : '') + rawValue.code(clean);
    if (paramCode.isEmpty ||
        ((info is NamedParameterInfo ||
                (info is InnerObjectParameterInfo &&
                    (info as InnerObjectParameterInfo).namedIfHaveAny !=
                        null)) &&
            paramCode == 'null')) {
      return '';
    }

    return info.code(paramCode);
  }

  @override
  bool fromCode(String code, FVBProject? project) {
    String paramCode = info.fromCode(code);
    logger('====== START $paramCode');
    if (paramCode.startsWith('[')) {
      final end = paramCode.indexOf(']') + 1;
      fromMetaCode(paramCode.substring(0, end));
      paramCode = paramCode.replaceRange(0, end, '');
    } else {
      val = options[defaultValue];
      if (options.length != 1) {
        for (final parameter in options) {
          logger('TESTING for param ${parameter.displayName}');
          if ((parameter.info is InnerObjectParameterInfo) &&
              (paramCode.startsWith(
                      '${(parameter.info as InnerObjectParameterInfo).innerObjectName}[') ||
                  paramCode.startsWith(
                      '${(parameter.info as InnerObjectParameterInfo).innerObjectName}('))) {
            val = parameter;
            break;
          }
          if (paramCode.startsWith('${parameter.info.getName()}:')) {
            val = parameter;
            break;
          }
          if (paramCode == parameter.code(false)) {
            val = parameter;
            break;
          }
          if (parameter is ComplexParameter) {
            final codes = CodeOperations.splitBy(paramCode);
            bool match = true;
            for (final childCode in codes) {
              bool found = false;
              for (final param in parameter.params) {
                final tempCode = param.info.code('_value_', allowEmpty: true);
                final infoCode =
                    tempCode.substring(0, tempCode.indexOf('_value_'));

                if (param is ListParameter) {
                  if (childCode.startsWith('[') ||
                      childCode.startsWith(param
                          .parameterGenerator()
                          .info
                          .code('', allowEmpty: true))) {
                    found = true;
                  }
                } else if (infoCode.isNotEmpty &&
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
    val?.fromCode(paramCode, project);
    return true;
  }

  @override
  bool equals(Parameter parameter) {
    if (parameter is! ChoiceParameter) {
      return false;
    }
    return listEqualsParam(parameter.options, options);
  }
}

bool listEqualsParam(List<Parameter>? a, List<Parameter>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (int index = 0; index < a.length; index += 1) {
    if (!a[index].isEqual(b[index])) {
      return false;
    }
  }
  return true;
}

class ComplexParameter extends Parameter with UsableParam {
  final List<Parameter> params;
  bool enable = true;
  final dynamic Function(List<Parameter>) evaluate;

  ComplexParameter(
      {String? name,
      required this.params,
      required this.evaluate,
      ParameterInfo? info,
      bool required = true,
      bool generateCode = true})
      : super(name, info, required, generateCode: generateCode) {
    enable = required;
  }

  @override
  get value {
    if (reused) {
      return usableValue;
    }
    return enable ? evaluate.call(params) : null;
  }

  @override
  get rawValue => throw UnimplementedError();

  @override
  Map<String, dynamic>? get toMetaJson => {'enable': enable};

  @override
  metaFromJson(Map<String, dynamic> json) => enable = (json['enable'] ?? true);

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(
        {
          'params': params.map((e) => e.toJson()).toList(),
        },
      );
  }

  @override
  void fromJson(Map<String, dynamic> map, FVBProject? project) {
    super.fromJson(map, project);
    for (int i = 0; i < (map['params'] ?? []).length; i++) {
      params[i].fromJson(Map<String,dynamic>.from(map['params'][i]), project);
    }
    if (isRequired) {
      enable = true;
    }
  }

  @override
  String code(bool clean) {
    if (clean && usableName != null) {
      return outputUsableCode;
    }
    if (!clean && reused) {
      return info.code(metaCode);
    }
    if (!enable && clean) {
      if (info.isNamed()) {
        return '';
      }
      return 'null';
    }
    String middle = '';
    for (final para in params) {
      final paramCode = para.code(clean);
      if (paramCode.isNotEmpty) {
        middle += '$paramCode,';
      }
    }
    middle = (!clean ? metaCode : '') + middle;
    return info.code(middle);
  }

  @override
  bool fromCode(String code, FVBProject? project) {
    // logger('subcode start $code');
    String outCode = (info.fromCode(code));
    if (outCode == 'null' && !isRequired) {
      enable = false;
    } else if (outCode.startsWith('[')) {
      final end = outCode.indexOf(']') + 1;
      fromMetaCode(outCode.substring(0, end));
      outCode = outCode.substring(end);
    } else {
      enable = true;
    }
    final paramCodeList = CodeOperations.splitBy(outCode);
    for (final Parameter parameter in params) {
      if (parameter.info.isNamed()) {
        for (final paramCode in paramCodeList) {
          if (paramCode.startsWith('${parameter.info.getName()}:')) {
            parameter.fromCode(paramCode, project);
            paramCodeList.remove(paramCode);
            break;
          }
        }
      } else if (paramCodeList.isNotEmpty) {
        final paramCode = paramCodeList.removeAt(0);
        // logger('subcode param trying $paramCode');
        parameter.fromCode(paramCode, project);
      } else {
        break;
      }
    }
    return paramCodeList.isEmpty;
  }

  @override
  bool equals(Parameter parameter) {
    if (parameter is! ComplexParameter) {
      return false;
    }
    return listEqualsParam(parameter.params, params);
  }
}

class ConstantValueParameter extends Parameter {
  dynamic constantValue;
  late String constantValueString;
  ParamType paramType;

  ConstantValueParameter(
      {String? displayName,
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
    if (info is SimpleParameterInfo) {
      if (paramType == ParamType.string) {
        return '\'$constantValueString}\'';
      }
      return constantValueString;
    }
    return info.code(paramType == ParamType.string
        ? '\'$constantValueString}\''
        : constantValueString);
  }

  @override
  get rawValue => constantValue;

  @override
  get value => constantValue;

  @override
  bool fromCode(String code, FVBProject? project) =>
      code == constantValueString;

  @override
  bool equals(Parameter parameter) {
    if (parameter is! ConstantValueParameter) {
      return false;
    }
    return parameter.constantValue == constantValue;
  }
}

class NullParameter extends Parameter {
  NullParameter(
      {String? displayName, ParameterInfo? info, bool required = false})
      : super(displayName, info, required);

  @override
  String code(bool clean) {
    if ((info is InnerObjectParameterInfo &&
        (info as InnerObjectParameterInfo).namedIfHaveAny == null)) {
      return 'null';
    }
    return '';
  }

  @override
  get rawValue => null;

  @override
  get value => null;

  @override
  bool fromCode(String code, FVBProject? project) =>
      code.toLowerCase() == 'null';

  @override
  bool equals(covariant Parameter parameter) {
    return true;
  }
}

class CallbackParameter extends Parameter {
  CallbackParameter(
      {String? displayName, ParameterInfo? info, bool required = false})
      : super(displayName, info, required);

  @override
  String code(bool clean) {
    return '';
  }

  @override
  get rawValue => null;

  @override
  get value => null;

  @override
  bool fromCode(String code, FVBProject? project) =>
      code.toLowerCase() == 'null';

  @override
  bool equals(covariant Parameter parameter) {
    return true;
  }
}

class ComponentParameter extends Parameter {
  VisualBoxCubit? visualBoxCubit;
  final List<Component> components = [];
  final bool multiple;
  late Component parent;

  ComponentParameter({
    required this.multiple,
    required ParameterInfo info,
    bool isRequired = false,
  }) : super(info.getName(), info, isRequired);

  void addComponent(final Component component,
      {int? index, bool reflect = true}) {
    if (index != null) {
      components.insert(index, component);
    } else {
      components.add(component);
    }
    component.parent = this;
    if (parent.cloneElements.isNotEmpty && reflect) {
      final paramIndex = parent.parameters.indexOf(this);
      parent.cloneElements.forEach((element) {
        (element.parameters[paramIndex] as ComponentParameter).addComponent(
            component.clone(element.parameters[paramIndex],
                deepClone: false, connect: true),
            index: index);
      });
    }
  }

  void replace(Component old, Component component, {bool reflect = true}) {
    final index = components.indexOf(old);
    components.removeAt(index);
    if (components.length > index) {
      components.insert(index, component);
    } else {
      components.add(component);
    }
    component.parent = this;
    if (parent.cloneElements.isNotEmpty && reflect) {
      final paramIndex = parent.parameters.indexOf(this);
      parent.cloneElements.forEach((element) {
        final param = (element.parameters[paramIndex] as ComponentParameter);
        param.replace(param.components[index],
            component.clone(param, deepClone: false, connect: true));
      });
    }
  }

  int get type => 7;

  int removeComponent(final Component component, {bool removeAll = false}) {
    final index = components.indexOf(component);
    components.removeAt(index);
    final paramIndex = parent.parameters.indexOf(this);
    switch (component.type) {
      case 1:
        break;
      case 2:
        if ((component as MultiHolder).children.isNotEmpty && !removeAll) {
          addComponent(component.children.first, index: index, reflect: false);
        }
        break;
      case 3:
        if ((component as Holder).child != null && !removeAll) {
          addComponent(component.child!, index: index, reflect: false);
        }
        break;
    }
    parent.cloneElements.forEach((element) {
      (element.parameters[paramIndex] as ComponentParameter).removeComponent(
          (element.parameters[paramIndex] as ComponentParameter)
              .components[index],
          removeAll: removeAll);
    });
    return index;
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
      paramCode += '[';
      for (final comp in components) {
        paramCode += comp.code(clean: clean);
      }
      paramCode + '],';
    } else if (components.isNotEmpty) {
      paramCode += components.first.code(clean: clean);
    }
    return info.code(paramCode);
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({'components': components.map((e) => e.toJson()).toList()});
  }

  @override
  void fromJson(Map<String, dynamic> map, FVBProject? project) {
    super.fromJson(map, project);
    components.addAll(List.of(map['components'] ?? [])
        .map((e) => e is Map && e.containsKey('name')?(Component.fromJson(e, project)..parent = this):null).nonNulls
        .toList());
  }

  @override
  bool fromCode(String code, FVBProject? project) {
    final paramCode = info.fromCode(code);
    if (multiple) {
      final componentCodes =
          CodeOperations.splitBy(paramCode.substring(1, paramCode.length - 1));
      for (final compCode in componentCodes) {
        components.add(Component.fromJson(compCode, project)..parent = this);
      }
    } else {
      components.add(Component.fromJson(paramCode, project)..parent = this);
    }
    return true;
  }

  @override
  get rawValue => components;

  dynamic build() {
    if (multiple) {
      if (visualBoxCubit != null) {
        return components
            .map<Widget>(
              (e) => BlocProvider<VisualBoxCubit>.value(
                value: visualBoxCubit!,
                child: Builder(
                  builder: (context) => e
                      .clone(parent, deepClone: false, connect: true)
                      .build(context),
                ),
              ),
            )
            .toList();
      } else {
        return components
            .map<Widget>(
              (e) => Builder(
                builder: (context) => e
                    .clone(parent, deepClone: false, connect: true)
                    .build(context),
              ),
            )
            .toList();
      }
    }
    if (components.isNotEmpty) {
      if (visualBoxCubit != null) {
        return BlocProvider<VisualBoxCubit>.value(
          value: visualBoxCubit!,
          child: Builder(
            builder: (context) => components.first
                .clone(parent, deepClone: false, connect: true)
                .build(context),
          ),
        );
      } else {
        return Builder(
          builder: (context) => components.first
              .clone(parent, deepClone: false, connect: true)
              .build(context),
        );
      }
    }
    return null;
  }

  @override
  get value => components;

  @override
  bool equals(Parameter parameter) {
    if (parameter is! ComponentParameter) {
      return false;
    }
    return parameter.multiple == multiple;
  }
}
