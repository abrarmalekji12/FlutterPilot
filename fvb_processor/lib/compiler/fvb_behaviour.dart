part of 'code_processor.dart';

class FVBAnalysisPlace {
  final String name;

  const FVBAnalysisPlace(this.name);

  static const any = FVBAnalysisPlace('Any');
}

class FVBCacheValue extends Equatable {
  final dynamic value;
  final DataType dataType;
  static const kNull = FVBCacheValue(null, DataType.fvbNull);

  const FVBCacheValue(this.value, this.dataType);

  @override
  List<Object?> get props => [value, dataType];
}

const kfvbInstance = 'fvbInstance';

class DataType extends Equatable {
  final String name;
  final String? fvbName;
  final List<DataType>? generics;
  final bool nullable;
  static const DataType fvbVoid = DataType('void');
  static const DataType fvbInt = DataType('int');
  static const DataType fvbDouble = DataType('double');
  static const DataType fvbNum = DataType('num');
  static const DataType string = DataType('String');
  static const DataType fvbBool = DataType('bool');
  static const DataType dateTime = DataType(kfvbInstance, fvbName: 'DateTime');

  static const DataType fvbIntNull = DataType('int', nullable: true);
  static const DataType fvbDoubleNull = DataType('double', nullable: true);
  static const DataType fvbNumNull = DataType('num', nullable: true);
  static const DataType stringNull = DataType('string', nullable: true);
  static const DataType fvbBoolNull = DataType('bool', nullable: true);
  static const DataType fvbDynamic = DataType('dynamic');

  static const DataType fvbNull = DataType('Null', nullable: true);
  static DataType fvbType(String fvbClass) =>
      DataType('Type', fvbName: fvbClass);

  bool get isFVBInstance => name == 'fvbInstance';

  //enum
  static DataType fvbEnum(String name) => DataType('enum', fvbName: name);

  static DataType iterable([DataType? elementType]) =>
      fvbInstance('Iterable', generics: [elementType ?? DataType.fvbDynamic]);

  static DataType list([DataType? generics]) =>
      fvbInstance('List', generics: [generics ?? DataType.fvbDynamic]);

  static DataType dart(String name) => DataType('dart', fvbName: name);

  static DataType map([List<DataType>? generics]) {
    assert(generics == null || generics.length == 2);
    return fvbInstance('Map',
        generics: generics ?? [DataType.fvbDynamic, DataType.fvbDynamic]);
  }

  static DataType future([DataType? type]) =>
      DataType('Future', generics: [type ?? fvbDynamic]);

  static DataType generic(String name) => DataType('Generic', fvbName: name);

  static DataType fvbEnumValue(String name) =>
      DataType('enumValue', fvbName: name);

  static DataType fvbFunctionOf(
          DataType returnType, List<DataType> arguments) =>
      DataType('fvbFunction', generics: [returnType, ...arguments]);
  static const DataType unknown = DataType('unknown');

  static DataType fvbInstance(String className, {List<DataType>? generics}) =>
      DataType('fvbInstance', fvbName: className, generics: generics);
  static const DataType fvbFunction = DataType('fvbFunction');

  static const DataType stream = DataType('Stream');
  static const DataType widget = DataType('fvbInstance', fvbName: 'Widget');
  static const DataType undetermined = DataType('undetermined');

  factory DataType.fromDataType(DataType dataType, List<DataType> generics) {
    return DataType(dataType.name,
        fvbName: dataType.fvbName, generics: generics);
  }

  bool get isList => name == 'fvbInstance' && fvbName == 'List';

  bool get isMap => name == 'fvbInstance' && fvbName == 'Map';

  static DataType ofType(Type T) {
    if (T == String) {
      return DataType.string;
    } else if (T == int) {
      return DataType.fvbInt;
    } else if (T == double) {
      return DataType.fvbDouble;
    } else if (T == num) {
      return DataType.fvbNum;
    } else if (T == bool) {
      return DataType.fvbBool;
    } else if (T == FVBImage) {
      return DataType.string;
    } else {
      return DataType.fvbDynamic;
    }
  }

  static DataType fromValue(dynamic value) {
    if (value is String) {
      return DataType.string;
    } else if (value is int) {
      return DataType.fvbInt;
    } else if (value is double) {
      return DataType.fvbDouble;
    } else if (value is num) {
      return DataType.fvbNum;
    } else if (value is bool) {
      return DataType.fvbBool;
    } else if (value is List) {
      return DataType.list(
          value.isEmpty ? DataType.fvbDynamic : fromValue(value.first));
    } else if (value is Map) {
      return DataType.map(value.isEmpty
          ? [DataType.fvbDynamic, DataType.fvbDynamic]
          : [
              fromValue(value.entries.first.key),
              fromValue(value.entries.first.value)
            ]);
    } else if (value is DateTime) {
      return DataType.fvbInstance('DateTime');
    } else {
      return DataType.fvbDynamic;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fvb_name': fvbName,
      'generics': generics?.map((e) => e.toJson()).toList(growable: false),
    };
  }

  bool equals(DataType other) {
    return name == other.name &&
        fvbName == other.fvbName &&
        listEqualsCheck<DataType>(generics ?? [], other.generics ?? [],
            (one, second) => one.equals(second));
  }

  factory DataType.fromJson(Map<String, dynamic> map) {
    if (map['name'] == 'string') {
      map['name'] = 'String';
    }
    return DataType(
      map['name'],
      fvbName: map['fvb_name'],
      generics:
          (map['generics'] as List?)?.map((e) => DataType.fromJson(e)).toList(),
    );
  }

  bool canAssignedTo(DataType other) {
    if (name == 'dynamic' ||
        name == 'Generic' ||
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

  const DataType(this.name,
      {this.fvbName, this.generics, this.nullable = false});

  @override
  toString() =>
      '${fvbName != null ? fvbName! : name}${(generics?.isNotEmpty ?? false) ? '<' : ''}${generics?.map((e) => e.toString()).join(',') ?? ''}${(generics?.isNotEmpty ?? false) ? '>' : ''}';

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
      case 'dynamic':
        return DataType.fvbDynamic;
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
        if (dataType == 'Future') {
          return DataType.future();
        }
        return DataType.unknown;
    }
  }

  static String dataTypeToCode(final DataType dataType) {
    if (dataType.generics != null && dataType.generics!.isNotEmpty) {
      return '${getStaticDatatypeToName(dataType)}<${dataType.generics!.map((e) => dataTypeToCode(e)).join(',')}>${dataType.nullable ? '?' : ''}';
    }
    return '${getStaticDatatypeToName(dataType)}${dataType.nullable ? '?' : ''}';
  }

  static String getStaticDatatypeToName(final DataType dataType) {
    if (dataType.name == 'fvbInstance') {
      return dataType.fvbName!;
    } else if (dataType.name == 'enum') {
      return dataType.fvbName!;
    } else if (dataType.name == 'dart') {
      return dataType.fvbName!;
    } else if (dataType.name == 'Future') {
      return 'Future';
    }
    switch (dataType.copyWith(nullable: false)) {
      case DataType.fvbInt:
        return 'int';
      case DataType.fvbDouble:
        return 'double';
      case DataType.fvbNum:
        return 'num';
      case DataType.string:
        return 'String';
      case DataType.undetermined:
      case DataType.fvbDynamic:
        return 'dynamic';
      case DataType.fvbBool:
        return 'bool';
      case DataType.fvbFunction:
        return 'Function';
      case DataType.fvbVoid:
        return 'void';
      case DataType.widget:
        return 'Widget';
    }
    return 'UNKNOWN';
  }

  DataType clone() {
    return DataType(
      name,
      fvbName: fvbName,
      generics: generics?.map((e) => e.clone()).toList(growable: false),
      nullable: nullable,
    );
  }

  DataType copyWith(
      {String? name,
      String? fvbName,
      List<DataType>? generics,
      bool? nullable}) {
    return DataType(
      name ?? this.name,
      fvbName: fvbName ?? this.fvbName,
      generics: generics ?? this.generics,
      nullable: nullable ?? this.nullable,
    );
  }

  // @override
  // operator ==(other) => other is DataType && other.name == name;
  static List<DataType> get values => [
        fvbInt,
        fvbDouble,
        string,
        fvbBool,
        fvbColor,
        fvbDynamic,
      ];

  static List<DataType> get modelValues => [
        fvbInt,
        fvbDouble,
        string,
        fvbBool,
        fvbMapStringDynamic,
        for (final fvbClass in Processor.classes.values)
          DataType.fvbInstance(fvbClass.name),
        for (final fvbEnum in Processor.enums.values)
          DataType.fvbEnum(fvbEnum.name),
        fvbDynamic,
      ];

  @override
  List<Object?> get props => [name, fvbName, nullable, generics];
}

abstract class FVBObject {
  String get type;
}

class CustomType implements Type {
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
  final (String, int) asynCode;

  FVBFuture(this.values, this.operators, this.asynCode);
}

class FVBReturn extends FVBCacheValue {
  const FVBReturn(super.value, super.datatype);

  factory FVBReturn.fromCache(FVBCacheValue value) {
    return FVBReturn(value.value, value.dataType);
  }
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
      this.dataType = DataType.fvbDynamic,
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

  factory FVBValue.fromCache(FVBCacheValue value) =>
      FVBValue(value: value.value, dataType: value.dataType);

  factory FVBValue.string(dynamic value) => FVBValue(
        value: value,
        dataType: DataType.string,
      );

  FVBCacheValue get cacheValue =>
      FVBCacheValue(value, dataType ?? DataType.fvbDynamic);

  FVBCacheValue evaluateValue(int index, Processor processor, config,
      {bool ignoreIfNotExist = false}) {
    if (variableName == null) {
      if (value is FVBTest) {
        return FVBCacheValue((value as FVBTest).testValue(processor),
            (value as FVBTest).dataType);
      }
      return FVBCacheValue(value, dataType ?? DataType.fvbDynamic);
    }
    if (createVar) {
      return FVBCacheValue.kNull;
    }
    final valueCache =
        processor.getValue(index, variableName!, config, object: object ?? '');
    value = valueCache.value;
    if (value is FVBTest) {
      return FVBCacheValue(
          (value as FVBTest).testValue(processor), (value as FVBTest).dataType);
    }
    return valueCache;
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
  final dynamic value;
  static const kDynamic = FVBTest(DataType.fvbDynamic, true);

  const FVBTest(this.dataType, this.nullable, {this.fvbClass, this.value});

  FVBTest copyWith(
          {DataType? dataType,
          bool? nullable,
          FVBClass? fvbClass,
          dynamic value}) =>
      FVBTest(
        dataType ?? this.dataType,
        nullable ?? this.nullable,
        fvbClass: fvbClass ?? this.fvbClass,
        value: value ?? this.value,
      );

  // @override
  // toString()=> testValue(Componentcollection.project!.processor);

  dynamic testValue(Processor processor) {
    if (dataType.name == 'fvbInstance') {
      // if (dataType.fvbName == 'List') {
      //   return [];
      // } else if (dataType.fvbName == 'Map') {
      //   return {};
      // }
      if (value != null) {
        return value;
      }
      if (Processor.classes[dataType.fvbName] == null) {
        return null;
      }
      return Processor.classes[dataType.fvbName]!.createInstance(
          processor,
          Processor.classes[dataType.fvbName]!.getDefaultConstructor?.arguments
                  .map<dynamic>((e) => FVBTest(e.dataType, e.nullable))
                  .toList(growable: false) ??
              [],
          config: const ProcessorConfig(unmodifiable: true));
    }

    // switch (dataType) {
    //   case DataType.fvbBool:
    //     return false;
    //   case DataType.fvbInt:
    //     return 0;
    //   case DataType.fvbDouble:
    //     return 0.0;
    //   case DataType.string:
    //     return '';
    //   case DataType.fvbVoid:
    //     return null;
    //   case DataType.fvbDynamic:
    //     return FVBTest(dataType, nullable);
    //   default:
    //     return this;
    // }
    return this;
  }
}

enum Scope { main, object }

enum OperationType { regular, checkOnly }
