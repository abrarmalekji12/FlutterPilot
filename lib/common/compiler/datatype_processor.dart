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

  static bool checkIfValidDataTypeOfValue(dynamic value, DataType dataType,String variable, Function showError,{String? invalidError}) {
    final valueDataType = getDartTypeToDatatype(value,showError);
    if(value==null&&dataType==DataType.fvbVoid){
      return true;
    }
    if (dataType == valueDataType ||
        (dataType == DataType.double && valueDataType == DataType.int) ||
        dataType == DataType.dynamic) {
      return true;
    } else {
      showError(
          invalidError??'Cannot assign ${LocalModel.dataTypeToCode(valueDataType)} to ${LocalModel.dataTypeToCode(dataType)} : $variable=${value.runtimeType}');
      return false;
    }
  }

  static DataType getDartTypeToDatatype(dynamic value,Function showError) {
    if(value==null){
      return DataType.fvbVoid;
    }
    final DataType dataType;
    if (value is int) {
      dataType = DataType.int;
    } else if (value is double) {
      dataType = DataType.double;
    } else if (value is String) {
      dataType = DataType.string;
    } else if (value is bool) {
      dataType = DataType.bool;
    } else if (value is List) {
      dataType = DataType.list;
    } else if (value is Map) {
      dataType = DataType.map;
    } else if (value is FVBInstance) {
      dataType = DataType.fvbInstance;
    } else if (value is FVBFunction) {
      dataType = DataType.fvbFunction;
    }
    else {
      dataType = DataType.unknown;
      showError('Unknown type of value $value');
    }
    return dataType;
  }
}
