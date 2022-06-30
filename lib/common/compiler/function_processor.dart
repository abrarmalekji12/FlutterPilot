import '../../code_to_component.dart';
import '../../models/local_model.dart';
import '../../ui/models_view.dart';
import 'argument_processor.dart';
import 'code_processor.dart';

class FunctionProcessor {
  static FVBFunction parse(CodeProcessor processor, String name, String argument, String body) {
    final argumentList = CodeOperations.splitBy(argument);
    final split = name.split('~');
    return FVBFunction(split.last, body, ArgumentProcessor.processArgumentDefinition(processor, argumentList),
        returnType: split.length == 2 ? LocalModel.codeToDatatype(split.first, processor.classes) : DataType.dynamic);
  }
}
