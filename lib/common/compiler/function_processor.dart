import '../../code_to_component.dart';
import '../../models/local_model.dart';
import '../../ui/models_view.dart';
import 'argument_processor.dart';
import 'code_processor.dart';
import 'constants.dart';
import 'fvb_function_variables.dart';

class FunctionProcessor {
  static FVBFunction parse(
      CodeProcessor processor, String name, String argument, String body,
      {bool lambda = false, bool async = false}) {
    final argumentList = CodeOperations.splitBy(argument);
    if (name.isNotEmpty) {
      final split = name.split(space);
      String dataTypeCode = split.first;
      bool nullable = false;
      if (dataTypeCode.endsWith('?')) {
        dataTypeCode = dataTypeCode.substring(0, dataTypeCode.length - 1);
        nullable = true;
      }
      final function = FVBFunction(split.last, body,
          ArgumentProcessor.processArgumentDefinition(processor, argumentList),
          returnType: split.length == 2
              ? DataType.codeToDatatype(
                  dataTypeCode, CodeProcessor.classes, CodeProcessor.enums)
              : DataType.dynamic,
          canReturnNull: nullable,
          isLambda: lambda,
          isAsync: async,
          processor: processor);
      if (CodeProcessor.operationType == OperationType.checkOnly) {
        function.execute(
            processor,
            null,
            function.arguments
                .map((e) => FVBTest(e.dataType, e.nullable))
                .toList(growable: false));
      }
      return function;
    }
    final function = FVBFunction('', body,
        ArgumentProcessor.processArgumentDefinition(processor, argumentList),
        returnType: DataType.dynamic,
        canReturnNull: true,
        isAsync: async,
        isLambda: lambda,
        processor: processor);

    if (CodeProcessor.operationType == OperationType.checkOnly) {
      function.execute(
          processor,
          null,
          function.arguments
              .map((e) => FVBTest(e.dataType, e.nullable))
              .toList(growable: false));
    }
    return function;
  }
}
