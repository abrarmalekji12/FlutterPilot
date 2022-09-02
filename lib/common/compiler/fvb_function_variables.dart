import '../../code_to_component.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import 'code_processor.dart';
import 'datatype_processor.dart';
import 'fvb_class.dart';

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

class FVBFunctionSample {
  final String code;
  final int start;
  final int end;

  FVBFunctionSample(this.code, this.start, this.end);
}
