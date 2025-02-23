import 'package:flutter_builder/code_operations.dart';

import 'argument_processor.dart';
import 'code_processor.dart';
import 'constants/processor_constant.dart';
import 'fvb_function_variables.dart';

class FunctionProcessor {
  static FVBFunction parse(Processor processor, String name, String argument,
      String body, ProcessorConfig config, int index,
      {bool lambda = false, bool async = false}) {
    final argumentList = CodeOperations.splitBy(argument);
    if (name.isNotEmpty) {
      final List<String> split;
      bool nullable = false;
      if (name.contains(space)) {
        split = name.split(space);
      } else {
        split = name.split('?');
        nullable = true;
      }
      String dataTypeCode = split.first;

      if (dataTypeCode.endsWith('?')) {
        dataTypeCode = dataTypeCode.substring(0, dataTypeCode.length - 1);
        nullable = true;
      }
      final function = FVBFunction(
          split.last,
          body,
          ArgumentProcessor.processArgumentDefinition(
              index, processor, argumentList, config: config),
          returnType: split.length == 2
              ? DataType.codeToDatatype(
                  dataTypeCode, Processor.classes, Processor.enums)
              : DataType.fvbDynamic,
          canReturnNull: nullable,
          isLambda: lambda,
          isAsync: async,
          line: index,
          processor: processor);
      config.functions?.add(function);
      return function;
    }
    final function = FVBFunction(
        '',
        body,
        ArgumentProcessor.processArgumentDefinition(
            index, processor, argumentList,
            config: config),
        returnType: DataType.fvbDynamic,
        canReturnNull: true,
        isAsync: async,
        isLambda: lambda,
        processor: processor);
    config.functions?.add(function);

    return function;
  }
}
