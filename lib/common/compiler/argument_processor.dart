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
      if (arguments[i].type == FVBArgumentType.placed) {
        final output = processor.process(argumentData[i]);
        if (DataTypeProcessor.checkIfValidDataTypeOfValue(
            output,
            arguments[i].dataType,
            arguments[i].name,
            arguments[i].nullable,
            processor.showError)) {
          processedArguments[i] = output;
        } else {
          return [];
        }
      } else {
        final name = arguments[i].name.startsWith('this.')
            ? arguments[i].name.substring(5)
            : arguments[i].name;
        if (optionArgs[name] != null) {
          final output = processor.process(optionArgs[name]);
          if (DataTypeProcessor.checkIfValidDataTypeOfValue(
              output,
              arguments[i].dataType,
              arguments[i].name,
              arguments[i].nullable,
              processor.showError)) {
            processedArguments[i] = output;
          }
        } else {
          processedArguments[i] = arguments[i].optionalValue;
        }
      }
    }
    return processedArguments;
  }

  static List<FVBArgument> processArgumentDefinition(
      final CodeProcessor processor, List<String> argumentList) {
    if (argumentList.isEmpty) {
      return [];
    }
    final List<FVBArgument> arguments = [];
    int placedLength = argumentList.length;
    if (argumentList.last.startsWith('{')) {
      placedLength--;
      final lastArgCode = argumentList.removeLast();
      argumentList.addAll(CodeOperations.splitBy(
              lastArgCode.substring(1, lastArgCode.length - 1))
          .where((element) => element.isNotEmpty));
    }
    for (int i = 0; i < argumentList.length; i++) {
      final type =
          i < placedLength ? FVBArgumentType.placed : FVBArgumentType.optional;
      if (type == FVBArgumentType.placed) {
        final value = DataTypeProcessor.getFVBValueFromCode(
            argumentList[i], processor.classes, processor.showError);
        arguments.add(FVBArgument(
            value != null ? value.variableName! : argumentList[i],
            type: type,
            dataType: value?.dataType ?? DataType.dynamic));
      } else {
        final split = CodeOperations.splitBy(argumentList[i], splitBy: '=');
        if (split.length == 2) {
          final value = DataTypeProcessor.getFVBValueFromCode(
              split[0], processor.classes, processor.showError);
          arguments.add(FVBArgument(
              value != null ? value.variableName! : split[0],
              type: type,
              optionalValue: processor.process(split[1]),
              dataType: value?.dataType ?? DataType.dynamic));
        } else {
          final value = DataTypeProcessor.getFVBValueFromCode(
              argumentList[i], processor.classes, processor.showError);
          arguments.add(FVBArgument(
              value != null ? value.variableName! : argumentList[i],
              type: type,
              dataType: value?.dataType ?? DataType.dynamic));
        }
      }
    }
    return arguments;
  }
}
