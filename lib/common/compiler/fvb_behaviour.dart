part of 'code_processor.dart';

class FVBCacheValue {
  final dynamic value;
  final DataType dataType;
  static final fvbNull = FVBCacheValue(null, DataType.fvbNull);

  FVBCacheValue(this.value, this.dataType);
}

class DataType {
  final String name;
  final String? fvbName;
  final List<DataType>? generics;
  static const DataType fvbVoid = DataType('fvbVoid');
  static const DataType fvbInt = DataType('int');
  static const DataType fvbDouble = DataType('double');
  static const DataType fvbNum = DataType('num');
  static const DataType string = DataType('string');
  static const DataType fvbBool = DataType('bool');
  static const DataType dynamic = DataType('dynamic');
  static const DataType fvbNull = DataType('Null');
  static const DataType fvbType = DataType('Type');

  //enum
  static DataType fvbEnum(String name) => DataType('enum', fvbName: name);

  static DataType iterable(DataType? elementType) => fvbInstance('Iterable',
      generics: elementType != null ? [elementType] : []);

  static DataType list(DataType? generics) =>
      fvbInstance('List', generics: generics != null ? [generics] : []);

  static DataType map(List<DataType>? generics) =>
      fvbInstance('Map', generics: generics);

  static DataType fvbEnumValue(String name) => DataType('enum', fvbName: name);

  static const DataType unknown = DataType('unknown');

  static DataType fvbInstance(String className, {List<DataType>? generics}) =>
      DataType('fvbInstance', fvbName: className, generics: generics);
  static const DataType fvbFunction = DataType('fvbFunction');
  static const DataType future = DataType('Future');
  static const DataType stream = DataType('Stream');
  static const DataType widget = DataType('Widget');
  static const DataType undetermined = DataType('undetermined');

  factory DataType.fromDataType(DataType dataType, List<DataType> generics) {
    return DataType(dataType.name,
        fvbName: dataType.fvbName, generics: generics);
  }

  bool canAssignedTo(DataType other) {
    if (name == 'dynamic' ||
        name == 'undetermined' ||
        other.name == 'dynamic') {
      return true;
    }
    if (other.fvbName == 'List' && fvbName == 'Iterable') {
      return true;
    }
    if (other.name != name || other.fvbName != fvbName) {
      return false;
    }
    for (int i = 0;
        i < (generics?.length ?? 0) && i < (other.generics?.length ?? 0);
        i++) {
      if (!generics![i].canAssignedTo(other.generics![i])) {
        return false;
      }
    }
    return true;
  }

  const DataType(this.name, {this.fvbName, this.generics});

  @override
  toString() => name + (generics?.map((e) => e.toString()).join(',') ?? '');

  static DataType codeToDatatype(final String dataType,
      final Map<String, FVBClass> classes, final Map<String, FVBEnum> enums) {
    if (dataType.length > 2 && dataType[dataType.length - 1] == '>') {
      final openIndex = dataType.indexOf('<');
      return DataType.fromDataType(
          codeToDatatype(dataType.substring(0, openIndex), classes, enums),
          CodeOperations.splitBy(
                  dataType.substring(openIndex + 1, dataType.length - 1))
              .map((e) => codeToDatatype(e, classes, enums))
              .toList(growable: false));
    }

    switch (dataType) {
      case 'int':
        return DataType.fvbInt;
      case 'double':
        return DataType.fvbDouble;
      case 'num':
        return DataType.fvbNum;
      case 'String':
        return DataType.string;
      case 'bool':
        return DataType.fvbBool;
      case 'Function':
        return DataType.fvbFunction;
      case 'Future':
        return DataType.future;
      case 'dynamic':
        return DataType.dynamic;
      case 'void':
        return DataType.fvbVoid;
      case 'Widget':
        return DataType.widget;
      default:
        if (classes.containsKey(dataType)) {
          return DataType.fvbInstance(dataType);
        }
        if (enums.containsKey(dataType)) {
          return DataType.fvbEnum(dataType);
        }
        return DataType.unknown;
    }
  }

  static String dataTypeToCode(final DataType dataType) {
    if (dataType.generics != null && dataType.generics!.isNotEmpty) {
      return '${getStaticDatatypeToName(dataType)}<${dataType.generics!.map((e) => dataTypeToCode(e)).join(',')}>';
    }
    return getStaticDatatypeToName(dataType);
  }

  static String getStaticDatatypeToName(final DataType dataType) {
    if (dataType.name == 'fvbInstance') {
      return dataType.fvbName!;
    } else if (dataType.name == 'enum') {
      return dataType.fvbName!;
    }
    switch (dataType) {
      case DataType.fvbInt:
        return 'int';
      case DataType.fvbDouble:
        return 'double';
      case DataType.fvbNum:
        return 'num';
      case DataType.string:
        return 'String';
      case DataType.undetermined:
      case DataType.dynamic:
        return 'dynamic';
      case DataType.future:
        return 'Future';
      case DataType.fvbBool:
        return 'bool';
      case DataType.fvbFunction:
        return 'Function';
      case DataType.unknown:
        return 'UNKNOWN';
      case DataType.fvbVoid:
        return 'void';
      case DataType.widget:
        return 'Widget';
    }
    return 'UNKNOWN';
  }

  // @override
  // operator ==(other) => other is DataType && other.name == name;
  static get values => [
        fvbInt,
        fvbDouble,
        string,
        fvbBool,
      ];
}

abstract class FVBObject {
  String get type;
}



class CustomType extends Type {
  final String name;

  CustomType(this.name);

  @override
  String toString() {
    return 'fvb$name';
  }

  @override
  bool operator ==(other) => other is Type && other.toString() == name;

  @override
  int get hashCode => name.hashCode;
}

enum FVBArgumentType {
  placed,
  optionalNamed,
  optionalPlaced,
}

class FVBBreak {}

class FVBContinue {}

class FVBFuture {
  final Stack2<FVBValue> values;
  final Stack2<String> operators;
  final String asynCode;

  FVBFuture(this.values, this.operators, this.asynCode);
}

class FVBReturn {
  final dynamic value;

  FVBReturn(this.value);
}

class FVBArgument {
  final String name;
  final DataType dataType;
  final FVBArgumentType type;
  final dynamic defaultVal;
  final bool nullable;

  FVBArgument(this.name,
      {this.type = FVBArgumentType.placed,
      this.defaultVal,
      this.dataType = DataType.dynamic,
      this.nullable = false});

  FVBVariable get toVar => FVBVariable(name, dataType, nullable: nullable);

  String get argName {
    if (name.startsWith('this.')) {
      return name.substring(5);
    }
    return name;
  }

  String get varDeclarationCode {
    return '${DataType.dataTypeToCode(dataType)}${nullable ? '?' : ''} $argName;';
  }

  @override
  String toString() {
    return '$name :: $type';
  }
}

class FVBArgumentValue {
  final String? name;
  final dynamic value;

  FVBArgumentValue(this.value, {this.name});
}


class FVBValue {
  dynamic value;
  final bool isVarFinal, createVar;
  final String? variableName;
  final String? object;
  final DataType? dataType;
  final bool nullable;
  final bool static;

  FVBValue(
      {this.value,
      this.variableName,
      this.isVarFinal = false,
      this.createVar = false,
      this.static = false,
      this.dataType,
      this.object,
      this.nullable = false});

  evaluateValue(CodeProcessor processor, {bool ignoreIfNotExist = false}) {
    if (variableName == null) {
      if (value is FVBTest) {
        return (value as FVBTest).testValue(processor);
      }
      return value;
    }
    if (createVar) {
      return null;
    }
    value = processor.getValue(variableName!, object: object ?? '').value;
    if (value is FVBTest) {
      return (value as FVBTest).testValue(processor);
    }
    return value;
  }

  @override
  toString() {
    return '(variableName: $variableName, value: $value, createVar: $createVar, isVarFinal: $isVarFinal)';
  }
}

class FVBUndefined {
  final String varName;

  FVBUndefined(this.varName);

  @override
  toString() {
    return '[undefined "$varName"]';
  }
}

class FVBTest {
  final DataType dataType;
  final bool nullable;
  final FVBClass? fvbClass;
  dynamic value;

  FVBTest(this.dataType, this.nullable, {this.fvbClass});

  // @override
  // toString()=> testValue(ComponentOperationCubit.currentProject!.processor);

  dynamic testValue(CodeProcessor processor) {
    if (dataType.name == 'fvbInstance') {
      if (dataType.fvbName == 'List') {
        return [];
      } else if (dataType.fvbName == 'Map') {
        return {};
      }
      if (value != null) {
        return value;
      }
      return value = CodeProcessor.classes[dataType.fvbName]!.createInstance(
          processor,
          CodeProcessor
                  .classes[dataType.fvbName]!.getDefaultConstructor?.arguments
                  .map<dynamic>((e) => FVBTest(e.dataType, e.nullable))
                  .toList(growable: false) ??
              []);
    }
    switch (dataType) {
      case DataType.fvbBool:
        return false;
      case DataType.fvbInt:
        return 0;
      case DataType.fvbDouble:
        return 0.0;
      case DataType.string:
        return '';
      case DataType.fvbVoid:
        return null;
      case DataType.dynamic:
        return FVBTest(dataType, nullable);
      default:
        return null;
    }
  }
}


enum Scope { main, object }

enum OperationType { regular, checkOnly }
