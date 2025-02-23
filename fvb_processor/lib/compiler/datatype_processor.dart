import 'package:fvb_processor/compiler/constants/processor_constant.dart';

import 'code_processor.dart';
import 'fvb_class.dart';
import 'fvb_classes.dart';
import 'fvb_enums.dart';
import 'fvb_function_variables.dart';

abstract class DataTypeProcessor {
  static DataType compatible(Set<DataType> list) {
    if (list.length == 1) {
      return list.first;
    }
    if (list.length == 2) {
      if (list.contains(DataType.fvbInt) && list.contains(DataType.fvbDouble)) {
        return DataType.fvbNum;
      }
    }
    return DataType.fvbDynamic;
  }

  static FVBValue? getFVBValueFromCode(String variable,
      final Map<String, FVBClass> classes, final Map<String, FVBEnum> enums) {
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
          dataType = DataType.fvbDynamic;
        } else {
          dataType = DataType.codeToDatatype(split.first, classes, enums);
        }
        if (dataType == DataType.unknown) {
          throw Exception('Unknown data type or class name "${split.first}"');
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

  static bool checkIfValidDataTypeOfValue(Processor processor, dynamic value,
      DataType dataType, String variable, bool nullable,
      {String? invalidDataTypeError,
      String? canNotNullError,
      bool throwException = true,
      bool assignedCheck = true}) {
    final DataType valueDataType;
    if (value != null) {
      valueDataType = getDartTypeToDatatype(value);
    } else {
      valueDataType = dataType;
    }

    if ((value is FVBInstance) && dataType.name == 'fvbInstance') {
      final cls = FVBModuleClasses.fvbClasses[dataType.fvbName!]!;
      FVBClass? fvbClass = value.fvbClass;
      while (fvbClass != null) {
        if (fvbClass == cls) {
          return true;
        }
        fvbClass = fvbClass.subClassOf;
      }
    }
    if (value is FVBTest) {
      return true;
    }
    if (value == null && dataType == DataType.fvbVoid) {
      return true;
    }
    if (value is List && dataType.isList) {
      if (value.isEmpty) {
        return true;
      }
    }
    if (assignedCheck &&
        (value == null &&
            !nullable &&
            dataType != DataType.fvbDynamic &&
            dataType != DataType.undetermined)) {
      processor
          .enableError(canNotNullError ?? 'value of $variable can not null');
    }
    if (value is FVBObject) {
      if (value.type == 'enum' && dataType.name == 'enum') {
        return true;
      }
    }
    if (dataType.nullable) {
      dataType = dataType.copyWith(nullable: false);
    }
    if ((dataType.canAssignedTo(valueDataType)) ||
        (dataType == DataType.fvbDouble && valueDataType == DataType.fvbInt) ||
        (dataType == DataType.fvbNum &&
            (valueDataType == DataType.fvbInt ||
                valueDataType == DataType.fvbDouble)) ||
        dataType == DataType.fvbDynamic ||
        dataType == DataType.undetermined) {
      return true;
    } else {
      processor.enableError(invalidDataTypeError ??
          'Cannot assign ${DataType.dataTypeToCode(valueDataType)} to ${DataType.dataTypeToCode(dataType)} : $variable = $value');
    }
    return false;
  }

  static DataType getDartTypeToDatatype(dynamic value) {
    if (value == null) {
      return DataType.fvbVoid;
    }
    if (value is FVBTest) {
      return value.dataType;
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
      dataType = DataType.list(DataTypeProcessor.compatible(value
          .map((e) => DataTypeProcessor.getDartTypeToDatatype(e))
          .toSet()));
    } else if (value is Map) {
      dataType = DataType.fvbInstance('Map');
    } else if (value is FVBInstance) {
      dataType = DataType.fvbInstance(value.fvbClass.name);
    } else if (value is FVBEnumValue) {
      dataType = DataType.fvbEnumValue(value.enumName);
    } else if (value is FVBEnum) {
      dataType = DataType.fvbEnum(value.name);
    } else if (value is FVBFunction) {
      dataType = DataType.fvbFunction;
    } else if (value is Future) {
      dataType = DataType.future();
    } else {
      dataType = DataType.fvbDynamic;
    }
    return dataType;
  }
}
