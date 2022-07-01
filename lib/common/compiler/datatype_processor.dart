import '../../models/local_model.dart';
import 'code_processor.dart';

class DataTypeProcessor {
  DataTypeProcessor();

  static FVBValue? getFVBValueFromCode(String variable, Map<String, FVBClass> classes, Function showError) {
    if (variable.contains('~')) {
      final split = variable.split('~');
      bool nullable = false;
      DataType? dataType;
      if (split.length == 2) {
        if (split[0] != 'final') {
          nullable = split.first.endsWith('?');
          dataType = LocalModel.codeToDatatype(
              nullable ? split.first.substring(0, split.first.length - 1) : split.first, classes);
          if (dataType == DataType.unknown) {
            showError('Unknown data type or class name "${split.first}"');
            return null;
          }
        } else {
          dataType = DataType.dynamic;
        }
      } else if (split.length == 3) {
        nullable = split[1].endsWith('?');
        dataType = LocalModel.codeToDatatype(nullable ?split[1].substring(0, split[1].length - 1) :split[1], classes);
        if (dataType == DataType.unknown) {
          showError('Unknown data type or class name "${split[1]}"');
          return null;
        }
      }
      return FVBValue(
          variableName: split.last, createVarIfNotExist: true, isVarFinal: split.first == 'final', dataType: dataType,nullable: nullable);
    }
    return null;
  }

  static bool checkIfValidDataTypeOfValue(dynamic value, DataType dataType, String variable, bool nullable,Function showError,
      {String? invalidError}) {
    final DataType valueDataType;
    if(value != null) {
      valueDataType = getDartTypeToDatatype(value, showError);
    }
    else{
      valueDataType= dataType;
    }
    if(value==null&&!nullable&&dataType != DataType.dynamic){
      showError('value of $variable can not null');
      return false;
    }
    if (value == null && dataType == DataType.fvbVoid) {
      return true;
    }
    if (dataType == valueDataType ||
        (dataType == DataType.double && valueDataType == DataType.int) ||
        dataType == DataType.dynamic) {
      return true;
    } else {
      showError(invalidError ??
          'Cannot assign ${LocalModel.dataTypeToCode(valueDataType)} to ${LocalModel.dataTypeToCode(dataType)} : $variable=${value.runtimeType}');
      return false;
    }
  }

  static DataType getDartTypeToDatatype(dynamic value, Function showError) {
    if (value == null) {
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
    } else {
      dataType = DataType.unknown;
      showError('Unknown type of value $value');
    }
    return dataType;
  }
}
