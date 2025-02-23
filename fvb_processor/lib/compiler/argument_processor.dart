import 'package:collection/collection.dart';
import 'package:flutter_builder/code_operations.dart';
import 'package:flutter_builder/common/ide/suggestion_processor.dart';
import 'package:fvb_processor/compiler/constants/processor_constant.dart';

import 'code_processor.dart';
import 'datatype_processor.dart';
import 'fvb_function_variables.dart';

class ArgumentProcessor {
  ArgumentProcessor();

  static List<dynamic> process(
      FVBFunction function,
      int index,
      final Processor processor,
      List<String> argumentData,
      Map<String, DataType> generics,
      config) {
    List<dynamic> processedArguments =
        List.filled(function.arguments.length, null);
    final Map<String, dynamic> optionArgs = {};

    int placedIndex = function.arguments.length;
    if (processor.isSuggestionEnable) {
      for (int i = 0; i < function.arguments.length; i++) {
        if (function.arguments[i].type == FVBArgumentType.optionalNamed) {
          placedIndex = i;
          break;
        }
      }
    }
    final List<String> notProcessedArguments = [];
    for (int i = 0; i < argumentData.length; i++) {
      final argument = argumentData[i];
      final split = CodeOperations.splitBy(argument, splitBy: colonCodeUnit);
      if (split.length == 2 &&
          function.arguments.firstWhereOrNull(
                  (element) => element.argName == split.first) !=
              null) {
        optionArgs[split[0]] = split[1];
      } else if (placedIndex <= i) {
        notProcessedArguments.add(argument);
      }
    }

    if (processor.isSuggestionEnable) {
      final exceptArguments = function.arguments.where((element) =>
          element.type == FVBArgumentType.optionalNamed &&
          !optionArgs.containsKey(element.argName));
      processor.suggestionConfig.namedParameterSuggestion =
          NamedParameterSuggestion(
              exceptArguments
                  .map((e) => '${e.argName}:')
                  .toList(growable: false),
              Processor.lastCodeCount);
      for (final argument in notProcessedArguments) {
        processor.process(argument, index: index, config: config);
      }
      processor.suggestionConfig.namedParameterSuggestion = null;
    }

    for (int i = 0; i < function.arguments.length; i++) {
      final name = function.arguments[i].argName;
      if (function.arguments[i].type == FVBArgumentType.placed ||
          function.arguments[i].type == FVBArgumentType.optionalPlaced) {
        FVBCacheValue cache;
        if (argumentData.length > i) {
          cache =
              processor.process(argumentData[i], index: index, config: config);
        } else {
          cache = FVBCacheValue(
            function.arguments[i].type == FVBArgumentType.optionalPlaced
                ? function.arguments[i].defaultVal
                : throw Exception(
                    'Missing argument "${function.arguments[i].name}" in function ${function.name}'),
            function.arguments[i].dataType,
          );
        }
        final dynamic value;
        if (Processor.operationType == OperationType.regular) {
          value = cache.value;
        } else {
          value = FVBTest(cache.dataType, cache.dataType.nullable);
        }

        if (DataTypeProcessor.checkIfValidDataTypeOfValue(
            processor,
            value,
            function.arguments[i].dataType,
            name,
            function.arguments[i].nullable)) {
          processedArguments[i] = value;
        } else {
          throw Exception(
              'Invalid Argument "${function.arguments[i].name}". expected "${function.arguments[i].dataType}" but got "$value" in function ${function.name}');
        }
      } else {
        if (optionArgs[name] != null) {
          final outputCache =
              processor.process(optionArgs[name], index: index, config: config);
          final output = outputCache.value;
          if (DataTypeProcessor.checkIfValidDataTypeOfValue(
              processor,
              output,
              function.arguments[i].dataType,
              name,
              function.arguments[i].nullable)) {
            processedArguments[i] = output;
          }
        } else {
          processedArguments[i] = function.arguments[i].defaultVal;
        }
      }
    }

    return processedArguments;
  }

  static List<FVBArgument> processArgumentDefinition(
      int index, final Processor processor, List<String> argumentList,
      {Map<String, FVBVariable>? variables, required ProcessorConfig config}) {
    if (argumentList.isEmpty) {
      return [];
    }
    final List<FVBArgument> arguments = [];
    int placedLength = argumentList.length;
    final last = argumentList.last;
    FVBArgumentType lastArgType = FVBArgumentType.placed;
    if (last.startsWith('{') || last.startsWith('[')) {
      placedLength--;
      final lastArgCode = argumentList.removeLast();
      argumentList.addAll(CodeOperations.splitBy(
              lastArgCode.substring(1, lastArgCode.length - 1))
          .where((element) => element.isNotEmpty));
      if (last.startsWith('{')) {
        lastArgType = FVBArgumentType.optionalNamed;
      } else {
        lastArgType = FVBArgumentType.optionalPlaced;
      }
    }
    for (int i = 0; i < argumentList.length; i++) {
      final type = i < placedLength ? FVBArgumentType.placed : lastArgType;
      if (type == FVBArgumentType.placed) {
        if (argumentList[i].startsWith('this.')) {
          final compatibleVar =
              getCompatibleVarForThis(argumentList[i].substring(5), variables);
          arguments.add(FVBArgument(argumentList[i],
              type: type,
              dataType: compatibleVar.dataType,
              nullable: compatibleVar.nullable));
        } else {
          final value = DataTypeProcessor.getFVBValueFromCode(
              argumentList[i], Processor.classes, Processor.enums);
          arguments.add(FVBArgument(
              value != null ? value.variableName! : argumentList[i],
              type: type,
              dataType: value?.dataType ?? DataType.fvbDynamic,
              nullable: value?.nullable ?? false));
        }
      } else {
        final split =
            CodeOperations.splitBy(argumentList[i], splitBy: equalCodeUnit);
        final FVBVariable? compatibleVar;
        if (argumentList[i].startsWith('this.')) {
          compatibleVar =
              getCompatibleVarForThis(argumentList[i].substring(5), variables);
        } else {
          compatibleVar = null;
        }

        if (split.length == 2) {
          final value = DataTypeProcessor.getFVBValueFromCode(
              split[0], Processor.classes, Processor.enums);
          final defaultValueCache =
              processor.process(split[1], index: index, config: config);
          arguments.add(FVBArgument(
              value != null ? value.variableName! : split[0],
              type: type,
              defaultVal: defaultValueCache.value,
              dataType: compatibleVar?.dataType ??
                  value?.dataType ??
                  DataType.fvbDynamic,
              nullable: compatibleVar?.nullable ?? value?.nullable ?? false));
        } else {
          final value = DataTypeProcessor.getFVBValueFromCode(
              argumentList[i], Processor.classes, Processor.enums);
          arguments.add(FVBArgument(
              value != null ? value.variableName! : argumentList[i],
              type: type,
              dataType: compatibleVar?.dataType ??
                  value?.dataType ??
                  DataType.fvbDynamic,
              nullable: compatibleVar?.nullable ?? value?.nullable ?? false));
        }
      }
    }
    return arguments;
  }

  static FVBVariable getCompatibleVarForThis(
      final String argument, final Map<String, FVBVariable>? variables) {
    if (variables == null) {
      throw Exception('Wrong use of keyword "this"');
    }
    final compatibleVar = variables[argument];
    if (compatibleVar == null) {
      throw Exception('Invalid use og "this", No variable $argument exist');
    }
    return compatibleVar;
  }
}
