import '../../code_to_component.dart';
import '../../models/local_model.dart';
import '../../ui/models_view.dart';
import 'argument_processor.dart';
import 'code_processor.dart';

class FunctionProcessor {
  static FVBFunction parse(
      CodeProcessor processor, String name, String argument, String body) {
    final argumentList = CodeOperations.splitBy(argument);
    if (name.isNotEmpty) {
      final split = name.split('~');
      String dataTypeCode = split.first;
      bool nullable = false;
      if (dataTypeCode.endsWith('?')) {
        dataTypeCode = dataTypeCode.substring(0, dataTypeCode.length - 1);
        nullable = true;
      }
      final function = FVBFunction(split.last, body,
          ArgumentProcessor.processArgumentDefinition(processor, argumentList),
          returnType: split.length == 2
              ? LocalModel.codeToDatatype(dataTypeCode, processor.classes)
              : DataType.dynamic,
          canReturnNull: nullable);
      if (processor.operationType == OperationType.checkOnly) {
        function.execute(processor,
            argumentList.map((e) => FVBUndefined('')).toList(growable: false));
      }
      return function;
    }
    final function = FVBFunction('', body,
        ArgumentProcessor.processArgumentDefinition(processor, argumentList),
        returnType: DataType.dynamic, canReturnNull: true);

    if (processor.operationType == OperationType.checkOnly) {
      function.execute(processor,
          argumentList.map((e) => FVBUndefined('')).toList(growable: false));
    }
    return function;
  }
}
