import '../../code_to_component.dart';
import '../../models/local_model.dart';
import '../../ui/models_view.dart';
import 'argument_processor.dart';
import 'code_processor.dart';
import 'constants.dart';

class FunctionProcessor {
  static FVBFunction parse(
      CodeProcessor processor, String name, String argument, String body,
      {bool lambda = false}) {
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
              ? DataType.codeToDatatype(dataTypeCode, CodeProcessor.classes)
              : DataType.dynamic,
          canReturnNull: nullable,
          isLambda: lambda);
      if (CodeProcessor.operationType == OperationType.checkOnly) {
        function.execute(processor,
            function.arguments.map((e) => FVBTest(e.dataType,e.nullable)).toList(growable: false));
      }
      return function;
    }
    final function = FVBFunction('', body,
        ArgumentProcessor.processArgumentDefinition(processor, argumentList),
        returnType: DataType.dynamic, canReturnNull: true);

    if (CodeProcessor.operationType == OperationType.checkOnly) {
      function.execute(processor,
          argumentList.map((e) => FVBUndefined('')).toList(growable: false));
    }
    return function;
  }
}
