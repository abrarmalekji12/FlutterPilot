import '../../models/local_model.dart';
import '../../ui/models_view.dart';
import 'code_processor.dart';

class DataTypeProcessor {
  DataTypeProcessor();

  static FVBValue? getFVBValueFromCode(String variable, Map<String, FVBClass> classes, Function showError) {
    if (variable.contains('~')) {
      final split = variable.split('~');
      DataType? dataType;
      if (split.length == 2) {
        if (split[0] != 'final') {
          dataType = LocalModel.codeToDatatype(split.first, classes);
          if (dataType == DataType.unknown) {
            showError('Unknown data type or class name "${split.first}"');
            return null;
          }
        } else {
          dataType = DataType.dynamic;
        }
      } else if (split.length == 3) {
        dataType = LocalModel.codeToDatatype(split[1], classes);
        if (dataType == DataType.unknown) {
          showError('Unknown data type or class name "${split[1]}"');
          return null;
        }
      }

      return FVBValue(
          variableName: split.last, createVarIfNotExist: true, isVarFinal: split.first == 'final', dataType: dataType);
    }
    return null;
  }
}
