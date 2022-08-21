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

class FVBEnum extends FVBObject {
  final String name;
  final Map<String, FVBEnumValue> values;

  FVBEnum(this.name, this.values);

  @override
  String get type => 'enum';
}

class FVBEnumValue extends FVBObject {
  final String name;
  final int index;
  final String enumName;

  FVBEnumValue(this.name, this.index, this.enumName);

  @override
  String get type => 'enum';

  @override
  String toString() {
    return '$enumName.$name';
  }
}

enum ABC { a1, b1, c2 }

class FVBClass {
  final String name;
  final Map<String, FVBFunction> fvbFunctions;
  final Map<String, FVBVariable Function()> fvbVariables;
  final Map<String, FVBFunction>? fvbStaticFunctions;
  final Map<String, FVBVariable>? fvbStaticVariables;
  final FVBConverter? converter;
  final List<String> generics;
  List<FVBClass> superclasses = [];

  FVBClass(this.name, this.fvbFunctions, this.fvbVariables,
      {this.fvbStaticVariables,
      this.converter,
      this.fvbStaticFunctions,
      this.generics = const [],
      CodeProcessor? parent});

  @override
  toString() => name;

  factory FVBClass.create(String name,
      {Map<String, FVBVariable Function()>? vars,
      List<FVBFunction>? funs,
      List<FVBVariable>? staticVars,
      List<FVBFunction>? staticFuns,
      FVBConverter? converter}) {
    return FVBClass(
      name,
      Map.fromEntries(funs?.map((e) => MapEntry(e.name, e)) ?? []),
      vars ?? {},
      fvbStaticVariables:
          Map.fromEntries(staticVars?.map((e) => MapEntry(e.name, e)) ?? []),
      fvbStaticFunctions:
          Map.fromEntries(staticFuns?.map((e) => MapEntry(e.name, e)) ?? []),
      converter: converter,
    );
  }

  FVBFunction? get getDefaultConstructor {
    return fvbFunctions[name];
  }

  Iterable<FVBFunction> get getNamedConstructor {
    return fvbFunctions.values
        .where((element) => element.name.startsWith('$name.'));
  }

  FVBInstance createInstance(
      final CodeProcessor parent, final List<dynamic> arguments,
      {final String? constructorName, final List<DataType>? generics}) {
    final constructor = constructorName ?? name;
    final isFactory = fvbFunctions[constructor]?.isFactory ?? false;
    if (isFactory) {
      return fvbFunctions[constructor]!.execute(parent, null, arguments);
    }
    final instance =
        FVBInstance(this, parent: parent, generics: generics ?? []);
    if (fvbFunctions.containsKey(constructor)) {
      instance.executeFunction(constructor, arguments + [instance]);
    } else if (constructorName != null) {
      throw Exception('No constructor named $constructor in $name');
    }
    return instance;
  }

  FVBCacheValue getValue(final String variable, final CodeProcessor processor) {
    if (fvbStaticVariables != null &&
        fvbStaticVariables!.containsKey(variable)) {
      if (fvbStaticVariables![variable]!.getCall != null) {
        return FVBCacheValue(
            fvbStaticVariables![variable]!.getCall!(null, processor),
            fvbStaticVariables![variable]!.dataType);
      }
      return FVBCacheValue(fvbStaticVariables![variable]!.value,
          fvbStaticVariables![variable]!.dataType);
    } else if (fvbStaticFunctions != null &&
        fvbStaticFunctions!.containsKey(variable)) {
      return FVBCacheValue(
          fvbStaticFunctions![variable]!, DataType.fvbFunction);
    }
    return FVBCacheValue(null, DataType.fvbNull);
  }

  void setValue(final String variable, dynamic value) {
    if (fvbStaticVariables != null &&
        fvbStaticVariables!.containsKey(variable)) {
      fvbStaticVariables![variable]!.value = value;
    } else if (fvbStaticFunctions != null &&
        fvbStaticFunctions!.containsKey(variable)) {
      fvbStaticVariables![variable]!.value = value;
    }
  }

  FVBFunction? getFunction(CodeProcessor processor, String name) {
    final FVBFunction? function;
    if (fvbStaticFunctions != null && fvbStaticFunctions!.containsKey(name)) {
      function = fvbStaticFunctions![name];
    } else if (fvbStaticVariables != null &&
        fvbStaticVariables!.containsKey(name)) {
      function = fvbStaticVariables![name]!.value;
    } else {
      throw Exception('Function $name not found in class ${this.name}');
    }
    return function;
  }

  executeFunction(CodeProcessor parent, String name, List<dynamic> arguments) {
    final output = getFunction(parent, name)?.execute(parent, null, arguments);
    return output;
  }
}

class FVBModel extends FVBClass {
  FVBModel.create(LocalModel model)
      : super(
          model.name,
          {},
          model.variables
              .asMap()
              .map((key, e) => MapEntry(e.name, () => e.toVar)),
        );
}

class FVBInstance {
  final FVBClass fvbClass;
  late final CodeProcessor processor;
  final List<DataType> generics;

  FVBInstance(this.fvbClass,
      {CodeProcessor? parent, this.generics = const []}) {
    processor = CodeProcessor.build(name: fvbClass.name, processor: parent)
      ..functions.addAll(fvbClass.fvbFunctions)
      ..variables.addAll(fvbClass.fvbVariables.map(
        (key, value) => MapEntry(key, value.call()),
      ));
  }

  toDart() {
    if (fvbClass.converter == null) {
      return variables['_dart']!.value;
    }
    return fvbClass.converter?.toDart(this);
  }

  Map<String, FVBVariable> get variables => processor.variables;

  Map<String, FVBFunction> get functions => processor.functions;

  @override
  Type get runtimeType => CustomType(fvbClass.name);

  FVBFunction? getFunction(CodeProcessor processor, String name) {
    final FVBFunction? function;
    if (fvbClass.fvbFunctions.containsKey(name)) {
      function = fvbClass.fvbFunctions[name];
    } else if (variables.containsKey(name)) {
      function = variables[name]!.value;
    } else {
      throw Exception('Function $name not found in class ${fvbClass.name}');
    }
    return function;
  }

  executeFunction(String name, List<dynamic> arguments) {
    final function = getFunction(processor, name)!;
    if (function.code == null && function.dartCall == null) {
      return fvbClass.converter!.fromDart(
          name,
          arguments
              .map(
                (e) => fvbClass.converter!.convert(e),
              )
              .toList(growable: false));
    }
    final output = function.execute(processor, this, arguments);
    return output;
  }
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

class FVBFunction {
  String? code;
  Function(List<dynamic>, FVBInstance?)? dartCall;
  String name;
  final Map<String, FVBVariable> localVariables = {};
  final List<FVBArgument> arguments;
  final DataType returnType;
  final bool canReturnNull;
  final bool isLambda;
  final bool isAsync;
  final bool isFactory;
  final CodeProcessor? processor;

  FVBFunction(
    this.name,
    this.code,
    this.arguments, {
    this.returnType = DataType.dynamic,
    this.canReturnNull = false,
    this.isFactory = false,
    this.dartCall,
    this.processor,
    this.isAsync = false,
    this.isLambda = false,
  });

  FVBFunctionSample get sampleCode {
    return FVBFunctionSample('''$name(${arguments.map((e) {
      return e.type == FVBArgumentType.optionalNamed
          ? '${e.argName}:${e.argName}'
          : e.argName;
    }).join(', ')});''', name.length + 2, 2);
  }

  String get cleanUpCode {
    return '''${DataType.dataTypeToCode(returnType)}${canReturnNull ? '?' : ''} $name(${arguments.map((e) {
      return '${DataType.dataTypeToCode(e.dataType)}${e.nullable ? '?' : ''} ${e.argName}';
    }).join(', ')}){''';
  }

  String getCleanInstanceCode(String code) {
    return '''(${arguments.map((e) {
      return '${DataType.dataTypeToCode(e.dataType)}${e.nullable ? '?' : ''} ${e.argName}';
    }).join(', ')}){$code}''';
  }

  String get samplePreviewCode {
    final String returnCode;
    if (returnType == DataType.dynamic || returnType == DataType.fvbVoid) {
      returnCode = 'Function';
    } else {
      returnCode =
          '${DataType.dataTypeToCode(returnType)}${canReturnNull ? '?' : ''} ';
    }
    return '$returnCode(${arguments.map((e) => '${e.name}:${DataType.dataTypeToCode(e.dataType)}${e.nullable ? '?' : ''}').join(' ,')})';
  }

  dynamic execute(final CodeProcessor? optionalProcessor, FVBInstance? instance,
      final List<dynamic> argumentValues,
      {CodeProcessor? defaultProcessor, String? filtered, dynamic self}) {
    if (CodeProcessor.error) {
      return null;
    }
    final parent = this.processor ??
        optionalProcessor ??
        (throw Exception('Processor not found'));
    final processor = defaultProcessor ??
        CodeProcessor.build(name: 'fun:$name', processor: parent);
    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i].name.startsWith('this.')) {
        final name = arguments[i].name.substring(5);
        if (parent.variables.containsKey(name)) {
          if (DataTypeProcessor.checkIfValidDataTypeOfValue(argumentValues[i],
              parent.variables[name]!.dataType, name, arguments[i].nullable)) {
            parent.variables[name]!.value = argumentValues[i];
          } else {
            processor.enableError(
                'Type mismatch in variable ${arguments[i].name} :: variable is type of ${parent.variables[name]!.dataType} and assigned type is ${argumentValues[i].runtimeType}');
          }
        } else {
          processor.enableError('No variable named "$name" found');
        }
      } else {
        processor.localVariables[arguments[i].name] = argumentValues[i];
      }
    }
    if (dartCall != null) {
      return dartCall?.call(
          (self != null ? [self] : []) + argumentValues + [parent], instance);
    }
    dynamic returnedOutput;
    if (isAsync) {
      processor.executeAsync(filtered ?? code!).then((value) {
        returnedOutput = value;
      });
    } else {
      returnedOutput = processor.execute(filtered ?? code!);
    }

    final output = isLambda
        ? returnedOutput
        : (returnedOutput is FVBReturn
            ? returnedOutput.value
            : (returnedOutput is Future ? returnedOutput : null));
    if (DataTypeProcessor.checkIfValidDataTypeOfValue(
      output,
      returnType,
      name,
      canReturnNull,
      invalidDataTypeError:
          'Function $name has return type of ${CodeOperations.getDatatypeToDartType(returnType)} but returned value is of type ${output.runtimeType}',
      canNotNullError:
          'Function $name has return type of ${CodeOperations.getDatatypeToDartType(returnType)} but returned value is null',
    )) {
      return output;
    }
  }

  FVBFunction clone() {
    return FVBFunction(name, code, arguments,
        returnType: returnType,
        canReturnNull: canReturnNull,
        dartCall: dartCall,
        isAsync: isAsync,
        isLambda: isLambda);
  }
}

class FVBFunctionSample {
  final String code;
  final int start;
  final int end;

  FVBFunctionSample(this.code, this.start, this.end);
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

class FVBVariable {
  final String name;
  dynamic fvbValue;
  DataType dataType;
  final bool isFinal;
  final bool nullable;
  final dynamic Function(dynamic, CodeProcessor)? getCall;
  final void Function(dynamic, dynamic)? setCall;
  bool initialized;

  FVBVariable(this.name, this.dataType,
      {dynamic value,
      this.isFinal = false,
      this.nullable = false,
      this.initialized = false,
      this.getCall,
      this.setCall}) {
    fvbValue = value;
  }

  get value {
    if (fvbValue is FVBTest) {
      return (fvbValue as FVBTest)
          .testValue(ComponentOperationCubit.currentProject!.processor);
    }
    return fvbValue;
  }

  set value(dynamic value) {
    if (setCall != null) {
      setCall!(this, value);
    } else {
      fvbValue = value;
    }
  }

  FVBVariable clone() {
    return FVBVariable(
      name,
      dataType,
      isFinal: isFinal,
      value: fvbValue,
      nullable: nullable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': fvbValue,
      'dataType': dataType.name,
      'isFinal': isFinal,
      'nullable': nullable,
    };
  }
}

enum Scope { main, object }

enum OperationType { regular, checkOnly }
