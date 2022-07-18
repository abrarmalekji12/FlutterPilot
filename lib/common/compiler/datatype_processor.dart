import '../../models/local_model.dart';
import 'code_processor.dart';
import 'constants.dart';

class DataTypeProcessor {
  DataTypeProcessor();

  static FVBValue? getFVBValueFromCode(
      String variable, Map<String, FVBClass> classes, Function showError) {
    if (variable.contains(space)||variable.contains('?')) {
      final split = variable.split(space);
      bool nullable = split.last.contains('?');
      if(nullable){
        split.addAll(split.removeLast().split('?'));
      }
      final bool static=split.remove('static');
      final bool isFinal=split.remove('final');
      DataType? dataType;
      if (split.length==2) {
        dataType = DataType.codeToDatatype(
             split.first,
            classes);
        if (dataType == DataType.unknown) {
          showError('Unknown data type or class name "${split.first}"');
          return null;
        }
      }
      else{
        dataType = DataType.dynamic;
      }
      return FVBValue(
          variableName: split.last,
          createVar: true,
          isVarFinal: isFinal,
          static: static,
          dataType: dataType,
          nullable: nullable);
    }
    return null;
  }

  static bool checkIfValidDataTypeOfValue(dynamic value, DataType dataType,
      String variable, bool nullable,
      {String? invalidDataTypeError, String? canNotNullError}) {
    final DataType valueDataType;
    if (value != null) {
      valueDataType = getDartTypeToDatatype(value);
    } else {
      valueDataType = dataType;
    }

    if(value is FVBTest){
      return true;
    }
    if (value == null && dataType == DataType.fvbVoid) {
      return true;
    }
    if (value == null && !nullable && dataType != DataType.dynamic) {
      throw Exception(canNotNullError ?? 'value of $variable can not null');
    }
    if (dataType == valueDataType ||
        (dataType == DataType.double && valueDataType == DataType.int) ||(dataType == DataType.num && (valueDataType == DataType.int||valueDataType == DataType.double))
        ||dataType == DataType.dynamic) {
      return true;
    } else {

      throw Exception(invalidDataTypeError ??
          'Cannot assign ${DataType.dataTypeToCode(valueDataType)} to ${DataType.dataTypeToCode(dataType)} : $variable = ${value.runtimeType}');
    }
  }

  static DataType getDartTypeToDatatype(dynamic value) {
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
      dataType = DataType.fvbInstance(value.fvbClass.name);
    } else if (value is FVBFunction) {
      dataType = DataType.fvbFunction;
    } else if(value is Future){
      dataType = DataType.future;
    }else {
      dataType = DataType.dynamic;
    }
    return dataType;
  }
}
