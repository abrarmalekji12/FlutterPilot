import '../../models/local_model.dart';
import 'code_processor.dart';
import 'constants.dart';

class DataTypeProcessor {
  DataTypeProcessor();

  static FVBValue? getFVBValueFromCode(
      String variable,
      final Map<String, FVBClass> classes,
      final Map<String, FVBEnum> enums,
      Function showError) {
    if (variable.contains(space) ||
        variable.contains('?') ||
        variable.contains('>')) {
      final split = variable.split(space);
      final bool nullable = split.last.contains('?');
      if (nullable) {
        split.addAll(split.removeLast().split('?'));
      } else if (split.last.contains('>')) {
        final last = split.removeLast();
        final lastIndex = last.lastIndexOf('>');
        split.addAll(
            [last.substring(0, lastIndex + 1), last.substring(lastIndex + 1)]);
      }
      final bool static = split.remove('static');
      final bool isFinal = split.remove('final');
      DataType? dataType;
      if (split.length == 2) {
        // if(className.endsWith('>')){
        //   DataType.codeToDatatype(
        //       className,
        //       classes,enums)
        // }
        if (split.first == 'var') {
          dataType = DataType.dynamic;
        } else {
          dataType = DataType.codeToDatatype(split.first, classes, enums);
        }
        if (dataType == DataType.unknown) {
          showError('Unknown data type or class name "${split.first}"');
          return null;
        }
      } else {
        dataType = DataType.undetermined;
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

  static bool checkIfValidDataTypeOfValue(
      dynamic value, DataType dataType, String variable, bool nullable,
      {String? invalidDataTypeError, String? canNotNullError}) {
    final DataType valueDataType;
    if (value != null) {
      valueDataType = getDartTypeToDatatype(value);
    } else {
      valueDataType = dataType;
    }

    if (value is FVBTest) {
      return true;
    }
    if (value == null && dataType == DataType.fvbVoid) {
      return true;
    }
    if (value == null && !nullable && dataType != DataType.dynamic&& dataType != DataType.undetermined) {
      throw Exception(canNotNullError ?? 'value of $variable can not null');
    }
    if (value is FVBObject) {
      if (value.type == 'enum' && dataType.name == 'enum') {
        return true;
      }
    }
    if ((dataType.canAssignedTo(valueDataType)) ||
        (dataType == DataType.fvbDouble && valueDataType == DataType.fvbInt) ||
        (dataType == DataType.fvbNum &&
            (valueDataType == DataType.fvbInt ||
                valueDataType == DataType.fvbDouble)) ||
        dataType == DataType.dynamic ||
        dataType == DataType.undetermined) {
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
      dataType = DataType.fvbInt;
    } else if (value is double) {
      dataType = DataType.fvbDouble;
    } else if (value is String) {
      dataType = DataType.string;
    } else if (value is bool) {
      dataType = DataType.fvbBool;
    } else if (value is List) {
      dataType = DataType.fvbInstance('List');
    } else if (value is Map) {
      dataType = DataType.fvbInstance('Map');
    } else if (value is FVBInstance) {
      dataType = DataType.fvbInstance(value.fvbClass.name);
    } else if (value is FVBFunction) {
      dataType = DataType.fvbFunction;
    } else if (value is Future) {
      dataType = DataType.future;
    } else {
      dataType = DataType.dynamic;
    }
    return dataType;
  }
}
