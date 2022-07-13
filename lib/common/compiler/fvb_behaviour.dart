part of 'code_processor.dart';

class DataType {
  final String name;
  final String? fvbName;
  static const DataType fvbVoid = DataType('fvbVoid');
  static const DataType int = DataType('int');
  static const DataType double = DataType('double');
  static const DataType num = DataType('num');
  static const DataType string = DataType('string');
  static const DataType bool = DataType('bool');
  static const DataType dynamic = DataType('dynamic');
  static const DataType list = DataType('list');
  static const DataType iterable = DataType('iterable');
  static const DataType map = DataType('map');
  static const DataType unknown = DataType('unknown');
  static const DataType fvbInstance = DataType('fvbInstance');
  static const DataType fvbFunction = DataType('fvbFunction');

  // static DataType fvbInstance(final String name) => DataType('fvbInstance',fvbName: name);
  // static DataType fvbFunction(final String name) => DataType('fvbFunction',fvbName: name);

  const DataType(this.name, {this.fvbName});

  @override
  toString() => name;

  static DataType codeToDatatype(
      final String dataType, Map<String, FVBClass> classes) {
    switch (dataType) {
      case 'int':
        return DataType.int;
      case 'double':
        return DataType.double;
      case 'num':
        return DataType.num;
      case 'String':
        return DataType.string;
      case 'bool':
        return DataType.bool;
      case 'List':
        return DataType.list;
      case 'Map':
        return DataType.map;
      case 'Object':
        return DataType.fvbInstance;
      case 'Function':
        return DataType.fvbFunction;
      case 'Iterable':
        return DataType.iterable;
      case 'dynamic':
        return DataType.dynamic;
      case 'void':
        return DataType.fvbVoid;
      default:
        if (classes.containsKey(dataType)) {
          return DataType.fvbInstance;
        }
        return DataType.unknown;
    }
  }

  static String dataTypeToCode(final DataType dataType) {
    switch (dataType) {
      case DataType.int:
        return 'int';
      case DataType.double:
        return 'double';
      case DataType.num:
        return 'num';
      case DataType.string:
        return 'String';
      case DataType.dynamic:
        return 'dynamic';
      case DataType.bool:
        return 'bool';
      case DataType.list:
        return 'List';
      case DataType.map:
        return 'Map';
      case DataType.fvbInstance:
        return 'Object';
      case DataType.fvbFunction:
        return 'Function';
      case DataType.iterable:
        return 'Iterable';
      case DataType.unknown:
        return 'UNKNOWN';
      case DataType.fvbVoid:
        return 'void';
    }
    return 'UNKNOWN';
  }

  // @override
  // operator ==(other) => other is DataType && other.name == name;
  static get values => [
        fvbVoid,
        int,
        double,
        string,
        bool,
        dynamic,
        list,
        iterable,
        map,
        fvbInstance,
        fvbFunction,
        unknown
      ];
}

class FVBClass {
  final String name;
  final Map<String, FVBFunction> fvbFunctions;
  final Map<String, FVBVariable Function()> fvbVariables;
  final Map<String, FVBFunction>? fvbStaticFunctions;
  final Map<String, FVBVariable>? fvbStaticVariables;
  final Object Function()? toKindObject;
  final FVBConverter? converter;

  FVBClass(this.name, this.fvbFunctions, this.fvbVariables,
      {this.fvbStaticVariables,
      this.converter,
      this.fvbStaticFunctions,
      this.toKindObject,
      CodeProcessor? parent});

  @override
  toString() => name;

  factory FVBClass.create(String name,
      {Map<String, FVBVariable Function()>? vars,
      List<FVBFunction>? funs,
      List<FVBVariable>? staticVars,
      List<FVBFunction>? staticFuns,
      Object Function()? toKindObject,
      FVBConverter? converter}) {
    return FVBClass(
      name,
      Map.fromEntries(funs?.map((e) => MapEntry(e.name, e)) ?? []),
      vars ?? {},
      toKindObject: toKindObject,
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
    return fvbFunctions.values.where((element) => element.name.startsWith('$name.'));
  }

  FVBInstance createInstance(
      final CodeProcessor? parent, final List<dynamic> arguments,
      {final String? constructorName}) {
    final instance = FVBInstance(this, parent: parent);
    if (fvbFunctions.containsKey(constructorName ?? name)) {
      instance.executeFunction(constructorName ?? name, arguments);
    }

    return instance;
  }

  dynamic getValue(final String variable) {
    if (fvbStaticVariables != null &&
        fvbStaticVariables!.containsKey(variable)) {
      return fvbStaticVariables![variable]!.value;
    } else if (fvbStaticFunctions != null &&
        fvbStaticFunctions!.containsKey(variable)) {
      return fvbStaticVariables![variable]!.value;
    } else if (fvbFunctions.containsKey(variable)) {
      return fvbFunctions[variable];
    }
    return null;
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
      throw ('Function $name not found in class $name');
    }
    return function;
  }

  executeFunction(CodeProcessor parent, String name, List<dynamic> arguments) {
    final output = getFunction(parent, name)?.execute(parent, arguments);
    return output;
  }
}

class FVBInstance {
  final FVBClass fvbClass;
  late final CodeProcessor processor;

  FVBInstance(this.fvbClass, {CodeProcessor? parent}) {
    processor = CodeProcessor.build(name: fvbClass.name, processor: parent)
      ..functions.addAll(fvbClass.fvbFunctions)
      ..variables.addAll(fvbClass.fvbVariables.map(
        (key, value) => MapEntry(key, value.call()),
      ));
  }

  toDart() {
    if (fvbClass.converter == null) {
      throw UnimplementedError(
          'Converter not implemented for Class ${fvbClass.name}');
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
      throw Exception('Function $name not found in class $name');
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
    final output = function.execute(processor, arguments);
    return output;
  }
}

class CustomType extends Type {
  final String name;

  CustomType(this.name);

  @override
  String toString() {
    return name;
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
  final FVBInstance futureInstance;

  FVBFuture(this.futureInstance);
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

  String get argName {
    if (name.startsWith('this.')) {
      return name.substring(5);
    }
    return name;
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
  Function(List<dynamic>)? dartCall;
  String name;
  final Map<String, FVBVariable> localVariables = {};
  final List<FVBArgument> arguments;
  final DataType returnType;
  final bool canReturnNull;
  final bool isLambda;

  FVBFunction(
    this.name,
    this.code,
    this.arguments, {
    this.returnType = DataType.dynamic,
    this.canReturnNull = false,
    this.dartCall,
    this.isLambda = false,
  });

  FVBFunctionSample get sampleCode {
    return FVBFunctionSample('''$name(${arguments.map((e) {
      return e.type == FVBArgumentType.optionalNamed
          ? '${e.argName}:${e.argName}'
          : e.argName;
    }).join(', ')});''', name.length + 2, 2);
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

  dynamic execute(
      final CodeProcessor parent, final List<dynamic> argumentValues) {
    if (arguments.length != argumentValues.length) {
      parent.enableError(
          'Not enough arguments in function $name , expected ${arguments.length} but got ${argumentValues.length}');
    }
    if (CodeProcessor.error) {
      return null;
    }
    if (dartCall != null) {
      return dartCall?.call(argumentValues + [parent]);
    }
    final processor = CodeProcessor.build(name: 'fun:$name', processor: parent);
    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i].name.startsWith('this.')) {
        final name = arguments[i].name.substring(5);
        if (parent.variables.containsKey(name)) {
          if (DataTypeProcessor.checkIfValidDataTypeOfValue(argumentValues[i],
              parent.variables[name]!.dataType, name, arguments[i].nullable)) {
            parent.variables[name]!.value = argumentValues[i];
          } else {
            parent.enableError(
                'Type mismatch in variable ${arguments[i].name} :: variable is type of ${parent.variables[name]!.dataType} and assigned type is ${argumentValues[i].runtimeType}');
          }
        } else {
          processor.enableError('No variable named "$name" found');
        }
      } else {
        processor.localVariables[arguments[i].name] = argumentValues[i];
      }
    }
    final returnedOutput = processor.execute(code!);
    final output = isLambda
        ? returnedOutput
        : (returnedOutput is FVBReturn ? returnedOutput.value : null);
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
      return value;
    }
    if (createVar) {
      return null;
    }
    value = processor.getValue(variableName!, object: object ?? '');
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

  FVBTest(this.dataType, this.nullable);
}

class FVBVariable {
  final String name;
  dynamic value;
  final DataType dataType;
  final bool isFinal;
  final bool nullable;

  FVBVariable(this.name, this.dataType,
      {this.value, this.isFinal = false, this.nullable = false});

  FVBVariable clone() {
    return FVBVariable(
      name,
      dataType,
      isFinal: isFinal,
      value: value,
      nullable: nullable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'dataType': dataType.name,
      'isFinal': isFinal,
      'nullable': nullable,
    };
  }
}

enum Scope { main, object }

enum OperationType { regular, checkOnly }
