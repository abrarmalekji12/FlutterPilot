import 'package:flutter_builder/code_operations.dart';
import 'package:flutter_builder/injector.dart';
import 'package:flutter_builder/models/local_model.dart';
import 'package:flutter_builder/models/variable_model.dart';
import 'package:fvb_processor/fvb_processor.dart';

import 'code_processor.dart';
import 'datatype_processor.dart';
import 'fvb_class.dart';

/// Important: [FVBFunction] Leave code empty (non-null) For Constructor
class FVBFunction {
  String? code;

  String? dartCode;

  /// In [dartCall] First Arg will be self-object and last argument will be parent processor
  Function(List<dynamic>, FVBInstance?)? dartCall;
  String name;
  final Map<String, FVBVariable> localVariables = {};
  final List<FVBArgument> arguments;
  final DataType returnType;
  final bool canReturnNull;
  final bool isLambda;
  bool isAsync;
  final bool isFactory;

  ///TODO(Make Final for BuilderComponent):
  Processor? processor;
  final int? line;

  FVBFunction(
    this.name,
    this.code,
    this.arguments, {
    this.returnType = DataType.fvbDynamic,
    this.canReturnNull = false,
    this.isFactory = false,
    this.dartCall,
    this.processor,
    this.dartCode,
    this.isAsync = false,
    this.line,
    this.isLambda = false,
  });

  DataType get dataType => DataType.fvbFunctionOf(
      returnType, arguments.map((e) => e.dataType).toList());

  String get implCode =>
      '''${!isFactory ? '${DataType.dataTypeToCode(returnType)}${canReturnNull ? '?' : ''}' : 'factory '}$name(${arguments.map((e) {
        if (e.dataType.equals(DataType.fvbDynamic)) {
          return e.argName;
        }
        return '${DataType.dataTypeToCode(e.dataType)}${e.nullable ? '?' : ''} ${e.argName}';
      }).join(', ')}){
  $dartCode
  }
  ''';

  String _samplePassedValue(FVBArgument argument) {
    if (argument.dataType.name == 'fvbFunction') {
      return '(${argument.dataType.generics != null ? argument.dataType.generics!.sublist(1).map((e) => e.name).join(',') : ''}){ }';
    }
    return argument.argName;
  }

  FVBFunctionSample get sampleCode {
    return FVBFunctionSample(
        '''$name(${arguments.where((e) => e.type != FVBArgumentType.optionalNamed || !e.nullable).map((e) {
              return e.defaultVal == null
                  ? e.type == FVBArgumentType.optionalNamed
                      ? '${e.argName}:${_samplePassedValue(e)}'
                      : _samplePassedValue(e)
                  : '';
            }).where((element) => element.isNotEmpty).join(', ')})''',
        name.length + 2,
        2);
  }

  String get cleanUpCode {
    return '''${DataType.dataTypeToCode(returnType)}${canReturnNull ? '?' : ''} $name(${arguments.map((e) {
      if (e.dataType.equals(DataType.fvbDynamic)) {
        return e.argName;
      }
      return '${DataType.dataTypeToCode(e.dataType)}${e.nullable ? '?' : ''} ${e.argName}';
    }).join(', ')}){''';
  }

  String getCleanInstanceCode(String code) {
    return '''(${arguments.map((e) {
      if (e.dataType.equals(DataType.fvbDynamic)) {
        return e.argName;
      }
      return '${DataType.dataTypeToCode(e.dataType)}${e.nullable ? '?' : ''} ${e.argName}';
    }).join(', ')}) ${isAsync ? 'async' : ''} {$code}''';
  }

  String get samplePreviewCode {
    final String returnCode;
    if (returnType == DataType.fvbDynamic || returnType == DataType.fvbVoid) {
      returnCode = 'Function';
    } else {
      returnCode =
          '${DataType.dataTypeToCode(returnType)}${canReturnNull ? '?' : ''} ';
    }
    return '$returnCode(${arguments.map((e) => e.dataType.equals(DataType.fvbDynamic) ? e.argName : '${e.argName}:${DataType.dataTypeToCode(e.dataType)}${e.nullable ? '?' : ''}').join(',')})';
  }

  String get suggestionPreviewCode {
    return '(${arguments.map((e) => e.dataType.equals(DataType.fvbDynamic) ? e.argName : '${e.argName}:${DataType.dataTypeToCode(e.dataType)}${e.nullable ? '?' : ''}').join(', ')})';
  }

  dynamic execute(
    final Processor? optionalProcessor,
    FVBInstance? instance,
    final List<dynamic> argumentValues, {
    Processor? defaultProcessor,
    String? filtered,
    dynamic self,
    ProcessorConfig? config,
  }) {
    final Processor processor;
    final Processor? parent;
    if (defaultProcessor != null) {
      processor = defaultProcessor;
      parent = null;
    } else {
      parent = instance?.processor ??
          this.processor ??
          optionalProcessor ??
          (throw Exception('Processor not found'));
      processor = Processor.build(
          name: 'fun:$name', parent: parent, avoidBinding: true);
    }
    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i].name.startsWith('this.')) {
        final name = arguments[i].name.substring(5);
        if (parent?.variables.containsKey(name) ?? false) {
          if (argumentValues.length <= i) {
            processor.enableError(
                'Invalid arguments provided to "${this.name}" given ${argumentValues.join(' ,')}');
            return;
          }
          if (DataTypeProcessor.checkIfValidDataTypeOfValue(
              processor,
              argumentValues[i],
              parent!.variables[name]!.dataType,
              name,
              arguments[i].nullable)) {
            parent.variables[name]!.setValue(processor, argumentValues[i]);
          } else {
            processor.enableError(
                'Type mismatch in variable ${arguments[i].name} :: variable is type of ${parent.variables[name]!.dataType} and assigned type is ${argumentValues[i].runtimeType}');
          }
        } else {
          processor.enableError('No variable named "$name" found');
        }
      } else {
        processor.localVariables[arguments[i].name] = FVBCacheValue(
            argumentValues.length > i
                ? argumentValues[i]
                : arguments[i].defaultVal,
            arguments[i].dataType);
      }
    }
    if (dartCall != null) {
      final output = dartCall?.call(
          (self != null ? [self] : []) + argumentValues + [parent], instance);
      // if ((output is FVBTest && output.dataType.name == 'Future') &&
      //     CodeProcessor.operationType == OperationType.checkOnly) {
      //   return FVBTest(output.dataType.generics![0], true);
      // }
      // if (output is FVBInstance && output.fvbClass.name == 'Future') {
      //   // return
      // }

      return output;
    }
    dynamic returnedOutput;
    if (isAsync) {
      processor
          .executeAsync(filtered ?? code!,
              returnOutput: isLambda, config: config ?? const ProcessorConfig())
          .then((value) {
        returnedOutput = value;
      });
    } else {
      returnedOutput = processor.execute(filtered ?? code!, line ?? 0,
          returnOutput: isLambda,
          givenConfig: config ?? const ProcessorConfig());
    }

    dynamic output;

    if (isLambda) {
      output = returnedOutput;
    } else if (returnedOutput is FVBReturn) {
      // if (Processor.operationType == OperationType.regular) {
      output = returnedOutput.value;
      // } else {
      //   output = FVBTest(
      //     (returnedOutput as FVBReturn).dataType,
      //     (returnedOutput as FVBReturn).dataType.nullable,
      //     fvbClass: instance?.fvbClass,
      //   );
      // }
    } else if (returnedOutput is Future) {
      output = returnedOutput;
    } else {
      output = null;
    }
    if (DataTypeProcessor.checkIfValidDataTypeOfValue(
      processor,
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

  String generate(Map<String, dynamic> fields) => '''$name(${arguments.map((e) {
        final arg = e.argName;
        final value =
            fields.containsKey(arg) ? fields[arg] : _samplePassedValue(e);
        return e.defaultVal == null || value is! FVBCode
            ? (e.type == FVBArgumentType.optionalNamed
                ? '$arg:${LocalModel.valueToCode(value)}'
                : LocalModel.valueToCode(value))
            : '';
      }).where((element) => element.isNotEmpty).join(', ')})''';

  List<FVBCacheValue> cached(List<dynamic> args) => args.indexed
      .map((e) => FVBCacheValue(
          e.$2,
          arguments[e.$1]
              .dataType
              .copyWith(nullable: arguments[e.$1].nullable)))
      .toList();
}

class FVBCode {
  final String code;

  FVBCode(this.code);

  @override
  toString() => code;
}

class FVBVariable {
  final String name;
  dynamic fvbValue;
  DataType dataType;
  final bool isFinal;
  final bool nullable;
  final bool late;
  final bool evaluate;
  final dynamic Function(dynamic, Processor)? getCall;
  final void Function(Processor, FVBVariable, dynamic)? setCall;
  bool initialized;

  FVBVariable(this.name, this.dataType,
      {dynamic value,
      this.late = false,
      this.evaluate = false,
      this.isFinal = false,
      this.nullable = false,
      this.initialized = false,
      this.getCall,
      this.setCall}) {
    fvbValue = value;
  }

  get value {
    if (fvbValue is FVBTest) {
      return (fvbValue as FVBTest).testValue(collection.project!.processor);
    }
    return fvbValue;
  }

  set value(value) {
    fvbValue = value;
  }

  void setValue(Processor processor, dynamic value) {
    if (setCall != null) {
      setCall!(processor, this, value);
    } else {
      fvbValue = value;
    }
  }

  String get code {
    if (this is VariableModel && (this as VariableModel).isDynamic) {
      return 'late ${DataType.dataTypeToCode(dataType)} $name;';
    }
    if (!nullable && value == null) {
      return '';
    }
    return '${isFinal ? 'final' : ''} ${DataType.dataTypeToCode(dataType)}${nullable ? '?' : ''} $name = ${value != null ? LocalModel.valueToCode(value) : 'null'};';
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

  FVBVariable copyWith({String? name, DataType? dataType, bool? nullable}) {
    return FVBVariable(
      name ?? this.name,
      dataType ?? this.dataType,
      isFinal: isFinal,
      value: fvbValue,
      nullable: nullable ?? this.nullable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': fvbValue,
      'dataType': dataType.toJson(),
      'isFinal': isFinal,
      'nullable': nullable,
    };
  }

  factory FVBVariable.fromJson(Map<String, dynamic> json) {
    return FVBVariable(json['name'], DataType.fromJson(json['dataType']),
        value: json['value']);
  }

  FVBArgument get toArg {
    return FVBArgument(name,
        dataType: dataType,
        defaultVal: value,
        nullable: nullable,
        type: FVBArgumentType.optionalNamed);
  }
}

class FVBFunctionSample {
  final String code;
  final int start;
  final int end;

  FVBFunctionSample(this.code, this.start, this.end);
}
