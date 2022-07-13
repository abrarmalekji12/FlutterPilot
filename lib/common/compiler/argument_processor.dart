import '../../code_to_component.dart';
import 'code_processor.dart';
import 'datatype_processor.dart';

class ArgumentProcessor {
  ArgumentProcessor();

  static List<dynamic> process(final CodeProcessor processor,
      List<String> argumentData, List<FVBArgument> arguments) {
    List<dynamic> processedArguments = List.filled(arguments.length, null);
    Map<String, dynamic> optionArgs = {};
    for (final argument in argumentData) {
      final split = CodeOperations.splitBy(argument, splitBy: ':');
      if (split.length == 2) {
        optionArgs[split[0]] = split[1];
      }
    }
    for (int i = 0; i < arguments.length; i++) {
      final name = arguments[i].name.startsWith('this.')
          ? arguments[i].name.substring(5)
          : arguments[i].name;
      if (arguments[i].type == FVBArgumentType.placed ||
          arguments[i].type == FVBArgumentType.optionalPlaced) {
        final output = argumentData.length > i
            ? processor.process(argumentData[i])
            : (arguments[i].type == FVBArgumentType.optionalPlaced
                ? arguments[i].defaultVal
                : throw Exception('Missing argument ${arguments[i].name}'));
        if (DataTypeProcessor.checkIfValidDataTypeOfValue(
            output, arguments[i].dataType, name, arguments[i].nullable)) {
          processedArguments[i] = output;
        } else {
          return [];
        }
      } else {
        if (optionArgs[name] != null) {
          final output = processor.process(optionArgs[name]);
          if (DataTypeProcessor.checkIfValidDataTypeOfValue(
              output, arguments[i].dataType, name, arguments[i].nullable)) {
            processedArguments[i] = output;
          }
        } else {
          processedArguments[i] = arguments[i].defaultVal;
        }
      }
    }
    return processedArguments;
  }

  static List<FVBArgument> processArgumentDefinition(
      final CodeProcessor processor, List<String> argumentList,
      {Map<String, FVBVariable>? variables}) {
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
              argumentList[i], CodeProcessor.classes, processor.enableError);

          arguments.add(FVBArgument(
              value != null ? value.variableName! : argumentList[i],
              type: type,
              dataType: value?.dataType ?? DataType.dynamic,
              nullable: value?.nullable ?? false));
        }
      } else {
        final split = CodeOperations.splitBy(argumentList[i], splitBy: '=');
        final FVBVariable? compatibleVar;
        if (argumentList[i].startsWith('this.')) {
          compatibleVar =
              getCompatibleVarForThis(argumentList[i].substring(5), variables);
        } else {
          compatibleVar = null;
        }

        if (split.length == 2) {
          final value = DataTypeProcessor.getFVBValueFromCode(
              split[0], CodeProcessor.classes, processor.enableError);
          arguments.add(FVBArgument(
              value != null ? value.variableName! : split[0],
              type: type,
              defaultVal: processor.process(split[1]),
              dataType: compatibleVar?.dataType ??
                  value?.dataType ??
                  DataType.dynamic,
              nullable: compatibleVar?.nullable ?? value?.nullable ?? false));
        } else {
          final value = DataTypeProcessor.getFVBValueFromCode(
              argumentList[i], CodeProcessor.classes, processor.enableError);
          arguments.add(FVBArgument(
              value != null ? value.variableName! : argumentList[i],
              type: type,
              dataType: compatibleVar?.dataType ??value?.dataType ?? DataType.dynamic,
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
