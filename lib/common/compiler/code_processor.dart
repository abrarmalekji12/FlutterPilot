import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../code_to_component.dart';
import '../../component_list.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../models/function_model.dart';
import '../../models/local_model.dart';
import '../../models/other_model.dart';
import '../../models/variable_model.dart';
import '../../ui/models_view.dart';
import '../logger.dart';
import 'argument_processor.dart';
import 'fvb_classes.dart';

Color? colorToHex(String hexString) {
  if (hexString.length < 7) {
    return null;
  }
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  final colorInt = int.tryParse(buffer.toString(), radix: 16);
  if (colorInt == null) {
    return null; // Not a valid hex color string (or not a color).
  }
  return Color(colorInt);
}

class FVBClass {
  final String name;
  final Map<String, FVBFunction> fvbFunctions;
  final Map<String, FVBFunction>? fvbStaticFunctions;
  final Map<String, FVBVariable> fvbVariables;
  final Map<String, FVBVariable>? fvbStaticVariables;

  FVBClass(this.name, this.fvbFunctions, this.fvbVariables, {this.fvbStaticFunctions, this.fvbStaticVariables});

  FVBInstance createInstance(final CodeProcessor processor, final List<dynamic> arguments) {
    final instance = FVBInstance(
      FVBClass(
          name,
          fvbFunctions,
          fvbVariables.map(
            (key, value) => MapEntry(key, value.clone()),
          ),
          fvbStaticFunctions: fvbStaticFunctions,
          fvbStaticVariables: fvbStaticVariables),
    );
    if (fvbFunctions.containsKey(name)) {
      instance.fvbClass.executeFunction(name, arguments, processor);
    }
    return instance;
  }

  FVBFunction? getFunction(CodeProcessor processor, String name) {
    final FVBFunction? function;
    if (fvbFunctions.containsKey(name)) {
      function = fvbFunctions[name];
    } else if (fvbStaticFunctions != null && fvbStaticFunctions!.containsKey(name)) {
      function = fvbStaticFunctions![name];
    } else if (fvbVariables.containsKey(name)) {
      function = fvbVariables[name]!.value;
    } else if (fvbStaticVariables != null && fvbStaticVariables!.containsKey(name)) {
      function = fvbStaticVariables![name]!.value;
    } else {
      processor.showError('Function $name not found in class $name');
      function = null;
    }
    return function;
  }

  executeFunction(String name, List<dynamic> arguments, CodeProcessor processor) {
    final Map<String, dynamic> oldVariables = {};
    final Map<String, dynamic> globalVariables = {};
    for (final MapEntry<String, FVBVariable> entry in fvbVariables.entries) {
      if (processor.localVariables.containsKey(entry.key)) {
        oldVariables[entry.key] = processor.localVariables[entry.key];
      }
      processor.localVariables[entry.key] = entry.value.value;
      if (processor.variables.containsKey(entry.key)) {
        globalVariables[entry.key] = processor.variables[entry.key]?.value;
        processor.variables[entry.key]?.value = entry.value.value;
      }
    }
    final variables = Map<String, VariableModel>.from(processor.variables);

    final output = getFunction(processor, name)?.execute(processor, arguments);

    for (final MapEntry<String, FVBVariable> entry in fvbVariables.entries) {
      final type = CodeOperations.getDatatypeToDartType(entry.value.dataType);
      final assignedType = processor.localVariables[entry.key].runtimeType;
      if (![DataType.int, DataType.double, DataType.string, DataType.bool, DataType.fvbInstance]
              .contains(entry.value.dataType) ||
          processor.localVariables[entry.key] == null ||
          assignedType == type ||
          (double == type && int == assignedType)) {
        entry.value.value = processor.localVariables[entry.key];
      } else {
        processor.showError(
            'Type mismatch in variable ${entry.key} :: variable is type of ${CodeOperations.getDatatypeToDartType(entry.value.dataType)} and assigned type is ${processor.localVariables[entry.key].runtimeType}');
      }
    }
    processor.variables.clear();
    processor.variables.addAll(variables);
    for (final entry in globalVariables.entries) {
      processor.variables[entry.key]?.value = entry.value;
    }
    for (final MapEntry entry in fvbVariables.entries) {
      if (oldVariables.containsKey(entry.key)) {
        processor.localVariables[entry.key] = oldVariables[entry.key];
      } else {
        processor.localVariables.remove(entry.key);
      }
    }

    return output;
  }
}

class FVBInstance {
  final FVBClass fvbClass;

  FVBInstance(this.fvbClass);
}

enum FVBArgumentType {
  placed,
  optional,
}

class FVBArgument {
  final String name;
  final FVBArgumentType type;
  final dynamic optionalValue;

  FVBArgument(this.name, {this.type = FVBArgumentType.placed, this.optionalValue});

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

  FVBFunction(this.name, this.code, this.arguments);

  dynamic execute(final CodeProcessor processor, final List<dynamic> argumentValues) {
    if (arguments.length != argumentValues.length) {
      processor.showError('Not enough arguments in function $name ');
    }
    if (dartCall != null) {
      return dartCall?.call(argumentValues);
    }
    final Map<String, dynamic> oldVariables = {};
    final Map<String, dynamic> globalVariables = {};

    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i].name.startsWith('this.')) {
        final name = arguments[i].name.substring(5);
        if (processor.localVariables.containsKey(name)) {
          processor.localVariables[name] = argumentValues[i];
        } else {
          processor.error = true;
          processor.errorMessage = 'No variable named "$name" found';
        }
      } else {
        if (processor.localVariables.containsKey(arguments[i].name)) {
          oldVariables[arguments[i].name] = processor.localVariables[arguments[i]];
        }
        if (processor.variables.containsKey(arguments[i].name)) {
          globalVariables[arguments[i].name] = processor.variables[arguments[i].name]?.value;
          processor.variables[arguments[i].name]?.value = argumentValues[i];
        }
        processor.localVariables[arguments[i].name] = argumentValues[i];
      }
    }

    final variables = Map<String, VariableModel>.from(processor.variables);
    final output = processor.executeCode(code!);
    processor.variables.clear();
    processor.variables.addAll(variables);
    for (int i = 0; i < arguments.length; i++) {
      if (oldVariables.containsKey(arguments[i].name)) {
        processor.localVariables[arguments[i].name] = oldVariables[arguments[i].name];
      } else {
        processor.localVariables.remove(arguments[i].name);
      }
    }
    for (final entry in globalVariables.entries) {
      processor.variables[entry.key]?.value = entry.value;
    }
    if (output != null && output is String && output.startsWith('print:')) {
      return null;
    }
    return output;
  }
}

class FVBValue {
  dynamic value;
  final bool isVarFinal, createVarIfNotExist;
  final String? variableName;

  FVBValue({
    this.value,
    this.variableName,
    this.isVarFinal = false,
    this.createVarIfNotExist = false,
  });

  evaluateValue(CodeProcessor processor) {
    if (variableName == null) {
      return value;
    }
    value = processor.getValue(variableName!);
    return value;
  }

  @override
  toString() {
    return '(variableName: $variableName, value: $value)';
  }
}

class FVBVariable {
  final String name;
  dynamic value;
  final DataType dataType;

  FVBVariable(this.name, this.dataType);

  clone() {
    return FVBVariable(
      name,
      dataType,
    );
  }
}

enum Scope { main, object }

class CodeProcessor {
  final Map<String, VariableModel> variables = {};
  final Map<String, FunctionModel> predefinedFunctions = {};
  final Map<String, FVBFunction> functions = {};
  final Map<String, FVBClass> classes = {};
  final Map<String, dynamic> localVariables = {};
  final Scope scope;
  late bool error;
  bool finished = false;
  String errorMessage = '';
  final capitalACodeUnit = 'A'.codeUnits.first,
      smallZCodeUnit = 'z'.codeUnits.first,
      underScoreCodeUnit = '_'.codeUnits.first;
  final zeroCodeUnit = '0'.codeUnits.first,
      nineCodeUnit = '9'.codeUnits.first,
      dotCodeUnit = '.'.codeUnits.first,
      colonCodeUnit = ':'.codeUnits.first;
  final String? Function(String) consoleCallback;
  final void Function(String, String) onError;

  CodeProcessor({this.scope = Scope.main, required this.consoleCallback, required this.onError}) {
    error = false;
    variables['pi'] =
        VariableModel('pi', math.pi, false, 'it is mathematical value of pi', DataType.double, '', deletable: false);
    variables['JSON'] = VariableModel(
        'JSON',
        FVBInstance(FVBClass('JSON', {
          'decode': FVBFunction('decode', null, [FVBArgument('text')])
            ..dartCall = (data) {
              return json.decode(data[0]);
            },
          'encode': FVBFunction('encode', null, [FVBArgument('json')])
            ..dartCall = (data) {
              return json.encode(data[0]);
            }
        }, {})),
        false,
        'it is a json parser',
        DataType.fvbInstance,
        '',
        deletable: false);
    classes['Timer'] = FVBClass('Timer', {
      'Timer': FVBFunction('Timer', '', [FVBArgument('duration'), FVBArgument('callback')]),
      'cancel': FVBFunction('cancel', '', []),
    }, {}, fvbStaticFunctions: {
      'periodic': FVBFunction('periodic', null, [FVBArgument('duration'), FVBArgument('callback')])
        ..dartCall = (arguments) {
          final timerInstance = classes['Timer']!.createInstance(this, arguments);
          final timer = Timer.periodic(
              Duration(milliseconds: (arguments[0] as FVBInstance).fvbClass.fvbVariables['milliseconds']!.value),
              (timer) {
            if (finished || error) {
              timer.cancel();
              return;
            }
            (arguments[1] as FVBFunction).execute(this, [timerInstance]);
          });
          timerInstance.fvbClass.fvbFunctions['cancel']!.dartCall = (args) {
            timer.cancel();
          };
          return timerInstance;
        },
    });
    classes.addAll(FVBModuleClasses.fvbClasses);
    predefinedFunctions['res'] = FunctionModel<dynamic>('res', (arguments) {
      if (variables['dw']!.value > variables['tabletWidthLimit']!.value) {
        return arguments[0];
      } else if (variables['dw']!.value > variables['phoneWidthLimit']!.value || arguments.length == 2) {
        return arguments[1];
      } else {
        return arguments[2];
      }
    }, '''
    double res(double large,double medium,[double? small]){
    if(dw>tabletWidthLimit){
      return large;
    }
    else if(dw>phoneWidthLimit||small==null){
      return medium;
    }
    else {
      return small;
    }
  }
    ''');

    predefinedFunctions['ifElse'] = FunctionModel<dynamic>('ifElse', (arguments) {
      if (arguments.length >= 2) {
        if (arguments[0] == true) {
          return arguments[1];
        } else if (arguments.length == 3) {
          return arguments[2];
        }
      }
    }, '''
    double? ifElse(bool expression,double ifTrue,[double? elseTrue]){
    if(expression){
      return ifTrue;
    }
    return elseTrue;
    }
    ''');

    predefinedFunctions['randInt'] = FunctionModel<int>('randInt', (arguments) {
      if (arguments.length == 1) {
        return math.Random.secure().nextInt(arguments[0] ?? 100);
      }
      return 0;
    }, '''
    int randInt(int? max){
    return math.Random.secure().nextInt(max??100);
    }
    ''');

    predefinedFunctions['randDouble'] = FunctionModel<double>('randDouble', (arguments) {
      return math.Random.secure().nextDouble();
    }, '''
    double randDouble(){
    return math.Random.secure().nextDouble();
    }
    ''');
    predefinedFunctions['randBool'] = FunctionModel<bool>('randBool', (arguments) {
      return math.Random.secure().nextBool();
    }, '''
    bool randBool(){
    return math.Random.secure().nextBool();
    }
    ''');
    predefinedFunctions['randColor'] = FunctionModel<String>('randColor', (arguments) {
      return '#' + Colors.primaries[math.Random().nextInt(Colors.primaries.length)].value.toRadixString(16);
    }, '''
    String randColor(){
    return '#'+Colors.primaries[math.Random().nextInt(Colors.primaries.length)].value.toRadixString(16);
    }
    ''');
    predefinedFunctions['sin'] = FunctionModel<double>('sin', (arguments) {
      return math.sin(arguments[0]);
    }, ''' ''');
    predefinedFunctions['cos'] = FunctionModel<double>('cos', (arguments) {
      return math.cos(arguments[0]);
    }, ''' ''');

    predefinedFunctions['print'] = FunctionModel<String>('print', (arguments) {
      return 'print:${arguments[0].toString()}';
    }, ''' ''');

    predefinedFunctions['showSnackbar'] = FunctionModel<dynamic>('showSnackbar', (arguments) {
      if (arguments.length < 2) {
        error = true;
        errorMessage = 'showSnackbar requires 2 arguments!!';
        return null;
      }
      return 'api:snackbar|${arguments[0]}|${arguments[1]}';
    }, ''' ''');
    predefinedFunctions['newPage'] = FunctionModel<dynamic>('newPage', (arguments) {
      if (arguments.isEmpty) {
        error = true;
        errorMessage = 'newPage requires 1 argument!!';
        return null;
      }
      return 'api:newpage|${arguments[0]}';
    }, ''' ''');
    predefinedFunctions['goBack'] = FunctionModel<dynamic>('goBack', (arguments) {
      return 'api:goback|';
    }, ''' ''');

    predefinedFunctions['toInt'] = FunctionModel<int?>('toInt', (arguments) {
      return int.tryParse(arguments[0]);
    }, ''' ''');
    predefinedFunctions['toDouble'] = FunctionModel<double?>('toDouble', (arguments) {
      return double.tryParse(arguments[0]);
    }, ''' ''');

    predefinedFunctions['lookUp'] = FunctionModel<dynamic>('lookUp', (arguments) {
      final id = arguments[0];
      FVBInstance? out;
      ComponentOperationCubit.currentFlutterProject?.currentScreen.rootComponent?.forEach((p0) {
        if (p0.id == id) {
          if (p0 is CTextField) {
            out = classes['TextField']?.createInstance(this, [])
              ?..fvbClass.fvbVariables['text']?.value = p0.textEditingController.text
              ..fvbClass.fvbFunctions['setText']?.dartCall = (arguments) {
                p0.textEditingController.text = arguments[0];
              };
          }
        }
      });
      return out;
    }, ''' ''');

    predefinedFunctions['refresh'] = FunctionModel<String>('refresh', (arguments) {
      return 'api:refresh|${arguments.isNotEmpty ? arguments[0] : ''}';
    }, ''' ''');
    predefinedFunctions['get'] = FunctionModel<dynamic>('get', (arguments) {
      final url = arguments[0] as String;
      final futureOfGet = classes['Future']!.createInstance(this, []);
      http.get(Uri.parse(url)).then((value) {
        (futureOfGet.fvbClass.fvbVariables['onValue']?.value as FVBFunction?)?.execute(this, [value.body]);
      }).onError((error, stackTrace) {
        (futureOfGet.fvbClass.fvbVariables['onError']?.value as FVBFunction?)?.execute(this, [error!]);
      });
      return futureOfGet;
    }, ''' ''');
  }

  void addVariable(String name, VariableModel value) {
    variables[name] = value;
  }

  bool isOperator(int ch) {
    return ch == '+'.codeUnits[0] ||
        ch == '-'.codeUnits[0] ||
        ch == '*'.codeUnits[0] ||
        ch == '/'.codeUnits[0] ||
        ch == '='.codeUnits[0] ||
        ch == '<'.codeUnits[0] ||
        ch == '>'.codeUnits[0] ||
        ch == '&'.codeUnits[0] ||
        ch == '~'.codeUnits[0] ||
        ch == '%'.codeUnits[0] ||
        ch == '!'.codeUnits[0] ||
        ch == '|'.codeUnits[0];
  }

  int getPrecedence(String ch) {
    if( ch == '<' || ch == '>' || ch == '<=' || ch == '>='){
      return 1;
    }
    if (ch == '+' || ch == '-') {
      return 2;
    }
    if (ch == '*' || ch == '/' ) {
      return 3;
    }
    return 0;
  }

  void destroyProcess() {
    finished = true;
  }

  dynamic getValue(final String variable, {FVBClass? fvbClass}) {
    if (variable.contains('[')) {
      return getOrSetListMapBracketValue(variable, fvbClass: fvbClass);
    } else if (variable == 'true') {
      return true;
    } else if (variable == 'false') {
      return false;
    } else if (fvbClass != null) {
      if (fvbClass.fvbVariables.containsKey(variable)) {
        return fvbClass.fvbVariables[variable]!.value;
      } else if (fvbClass.fvbStaticVariables?.containsKey(variable) ?? false) {
        return fvbClass.fvbStaticVariables![variable]!.value;
      } else if (fvbClass.fvbFunctions.containsKey(variable)) {
        return fvbClass.fvbFunctions[variable]!;
      } else if (fvbClass.fvbStaticFunctions?.containsKey(variable) ?? false) {
        return fvbClass.fvbStaticFunctions![variable]!;
      }
    } else if (variables.containsKey(variable)) {
      return variables[variable]!.value;
    } else if (localVariables.containsKey(variable)) {
      return localVariables[variable];
    } else if (functions.containsKey(variable)) {
      return functions[variable];
    } else if (classes.containsKey(variable)) {
      return classes[variable];
    }
    return null;
  }

  bool setValue(final String variable, dynamic value, {bool isFinal = false, bool createNew = false}) {
    if (variable.contains('[')) {
      getOrSetListMapBracketValue(variable, value: value);
      return true;
    } else if (variables.containsKey(variable)) {
      if (variables[variable]!.isFinal) {
        showError('Cannot change value of final variable $variable');
        return false;
      } else {
        variables[variable]!.value = value;
      }
      return true;
    } else if (localVariables.containsKey(variable)) {
      localVariables[variable] = value;
      return true;
    } else {
      if (createNew) {
        final dataType = getDartTypeToDatatype(value);
        variables[variable] = VariableModel(variable, value, false, null, dataType, '',
            // type: dataType == DataType.fvbInstance
            //     ? (value as FVBInstance).fvbClass.name
            //     : null,
            isFinal: isFinal);
      } else {
        showError('Variable $variable not found');
        return false;
      }
      return true;
    }
  }

  DataType getDartTypeToDatatype(dynamic value) {
    final DataType dataType;
    if (value is double) {
      dataType = DataType.double;
    } else if (value is int) {
      dataType = DataType.int;
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
      throw Exception('Invalid datatype of variable');
    }
    return dataType;
  }

  getOrSetListMapBracketValue(String variable, {dynamic value, FVBClass? fvbClass}) {
    int openBracket = variable.indexOf('[');
    if (openBracket != -1) {
      final closeBracket =
          CodeOperations.findCloseBracket(variable, openBracket, '['.codeUnits.first, ']'.codeUnits.first);
      final key = process(variable.substring(openBracket + 1, closeBracket));
      final subVar = variable.substring(0, openBracket);
      openBracket = variable.indexOf('[', closeBracket);
      dynamic mapValue = getValue(subVar, fvbClass: fvbClass);
      if (value != null && openBracket == -1) {
        mapValue[key] = value;
        return true;
      } else {
        if ((mapValue is Map && mapValue.containsKey(key)) ||
            (mapValue is List && key is int && key < mapValue.length)) {
          mapValue = mapValue[key];
        } else {
          showError('can not use [ ] with $mapValue');
          return null;
        }
      }
      while (openBracket != -1) {
        final closeBracket =
            CodeOperations.findCloseBracket(variable, openBracket, '['.codeUnits.first, ']'.codeUnits.first);
        final key = process(variable.substring(openBracket + 1, closeBracket));
        openBracket = variable.indexOf('[', closeBracket);
        if (value != null && openBracket == -1) {
          mapValue[key] = value;
        } else {
          if ((mapValue is Map && mapValue.containsKey(key)) ||
              (mapValue is List && key is int && key < mapValue.length)) {
            mapValue = mapValue[key];
          } else {
            showError('can not use [ ] with $mapValue');
            return null;
          }
        }
      }
      return mapValue;
    }
  }

  void processOperator(final String operator, final Stack2<FVBValue> valueStack, final Stack2<String> operatorStack) {
    dynamic a, b;
    late FVBValue aVar, bVar;
    if (valueStack.isEmpty) {
      error = true;
      errorMessage = 'ValueStack is Empty, syntax error !!';
      return;
    } else {
      bVar = valueStack.pop()!;
      b = bVar.value;
    }
    if (valueStack.isEmpty && operator != '-' && operator != '--' && operator != '++' && operator != '!') {
      error = true;
      errorMessage = 'Not enough values for operation "$operator", syntax error !!';
      return;
    } else if (valueStack.isNotEmpty) {
      aVar = valueStack.pop()!;
      a = aVar.value;
    }
    late dynamic r;
    switch (operator) {
      case '--':
      case '+':
        if (operator == '--' && a == null) {
          final value = getValue(bVar.variableName!);
          setValue(bVar.variableName!, value - 1);
          r = null;
          break;
        }
        r = a + b;
        break;
      case '-':
        if (a == null) {
          r = -b;
        } else {
          r = a - b;
        }
        break;
      case '*':
        r = a * b;
        break;
      case '/':
        r = a / b;
        break;
      case '~/':
        r = a ~/ b;
        break;
      case '*-':
        r = a * -b;
        break;
      case '**':
        r = math.pow(a, int.parse(b.toString()));
        break;
      case '/-':
        r = a / -b;
        break;
      case '%':
        if (a is int && b is int) {
          r = a % b;
        } else {
          error = true;
          errorMessage = 'Can not do $a % $b, both are not type of int';
          return;
        }
        break;
      case '<':
        r = a < b;
        break;
      case '>':
        r = a > b;
        break;
      case '!':
        r = !b;
        break;
      case '=':
        setValue(aVar.variableName!, b, isFinal: aVar.isVarFinal, createNew: aVar.createVarIfNotExist);
        r = b;
        break;
      case '++':
        final name = bVar.variableName!;
        final value = getValue(name);

        if (value != null) {
          setValue(name, value! + 1);
          r = value! + 1;
        } else {
          showError('Variable $name is not defined');
          r = null;
        }

        break;
      case '+=':
        final name = aVar.variableName!;
        final value = getValue(name);
        if (value != null) {
          setValue(name, value! + b);
          r = value! + b;
        } else {
          showError('Variable $name is not defined');
          r = null;
        }
        break;
      case '-=':
        final name = aVar.variableName!;
        final value = getValue(name);
        r = null;
        if (value != null) {
          setValue(name, value! - b);
        } else {
          showError('Variable $name is not defined');
        }
        break;
      case '*=':
        final name = aVar.variableName!;
        final value = getValue(name);

        if (value != null) {
          setValue(name, value! * b);
          r = value! * b;
        } else {
          showError('Variable $name is not defined');
          r = null;
        }
        break;
      case '/=':
        final name = aVar.variableName!;
        final value = getValue(name);
        if (value != null) {
          setValue(name, value! / b);
          r = value! / b;
        } else {
          showError('Variable $name is not defined');
          r = null;
        }
        break;
      case '<=':
        r = a <= b;
        break;
      case '>=':
        r = a >= b;
        break;
      case '>>':
        r = a >> b;
        break;
      case '<<':
        r = a << b;
        break;
      case '&&':
        r = (a as bool) && (b as bool);
        break;
      case '||':
        r = (a as bool) || (b as bool);
        break;
      case '==':
        r = (a == b);
        break;
      case '!=':
        r = a != b;
        break;
      default:
        error = true;
        errorMessage = 'Operation "$operator" not found!!';
        r = null;
    }
    valueStack.push(FVBValue(value: r));
  }

  String? processString(String code) {
    int si = -1, ei = -1;

    List<int> startList = [];
    List<int> endList = [];
    int count = 0;
    for (int i = 0; i < code.length; i++) {
      if (code.length - 1 > i) {
        if (code[i] == '{' && code[i + 1] == '{') {
          if (count == 0) {
            startList.add(i);
          }
          count++;
        } else if (code[i] == '}' && code[i + 1] == '}') {
          count--;
          if (count == 0) {
            endList.add(i);
          }
        }
      }
    }
    if (startList.length != endList.length) {
      error = true;
      errorMessage = 'Invalid {{ syntax !!';
    }
    while (startList.isNotEmpty) {
      si = startList.removeAt(0);
      ei = endList.removeAt(0);
      if (si + 2 == ei) {
        showError('No expression between {{ and }} !!');
        return null;
        // return CodeOutput.right('No variables');
      }
      final variableName = code.substring(si + 2, ei);
      final value = process(
        variableName,
        resolve: true,
      );
      final k1 = '{{$variableName}}';
      final v1 = value.toString();
      code = code.replaceAll(k1, v1);
      for (int i = 0; i < startList.length; i++) {
        startList[i] += v1.length - k1.length;
        endList[i] += v1.length - k1.length;
      }
    }
    return code;
  }

  dynamic executeCode(final String input) {
    finished = false;
    String code = '';
    for (final line in input.split('\n')) {
      int index = -1;
      bool openString = false;
      for (int i = 0; i < line.length; i++) {
        if (line[i] == '"') {
          openString = !openString;
        } else if (!openString && i + 1 < line.length && line[i] == '/' && line[i + 1] == '/') {
          index = i;
          break;
        }
      }
      if (index != -1) {
        code += line.substring(0, index);
      } else {
        code += line;
      }
    }
    final singleSpaceCode = CodeOperations.trimAvoidSingleSpace(code)!
        .replaceAll('return ', 'return~')
        .replaceAll('var ', 'var~')
        .replaceAll('final ', 'final~');
    String trimCode = CodeOperations.trim(singleSpaceCode)!;
    int count = 0;
    int lastPoint = 0;
    dynamic globalOutput;

    for (int i = 0; i < trimCode.length; i++) {
      if (trimCode[i] == '{' || trimCode[i] == '[' || trimCode[i] == '(') {
        count++;
      } else if (trimCode[i] == '}' || trimCode[i] == ']' || trimCode[i] == ')') {
        count--;
      }
      if (count == 0 && (trimCode[i] == ';' || trimCode.length == i + 1)) {
        final code = trimCode.substring(lastPoint, trimCode.length == i + 1 ? i + 1 : i);
        final output = process(code);
        lastPoint = i + 1;

        if (error) {
          onError.call(errorMessage, code);
          return;
        } else if (output != null) {
          globalOutput = output;
          consoleCallback.call(output.toString());
        }
        if (finished) {
          return;
        }
      }
    }
    return globalOutput;
  }

  dynamic process<T>(
    final String input, {
    bool resolve = false,
  }) {
    final checkForError = CodeOperations.checkSyntaxInCode(input);
    if (checkForError != null) {
      showError(checkForError);
      return null;
    }
    final Stack2<FVBValue> valueStack = Stack2<FVBValue>();
    final Stack2<String> operatorStack = Stack2<String>();
    String number = '';
    bool stringOpen = false;
    int stringCount = 0;
    String variable = '';
    String object = '';
    error = false;
    if (T == String || T == ImageData) {
      return processString(input);
    } else if (T == Color && input.startsWith('#')) {
      return input;
    }
    for (int n = 0; n < input.length; n++) {
      if (error) {
        return null;
      }
      final String nextToken = input[n];
      final ch = nextToken.codeUnits.first;
      if (stringOpen) {
        if (stringCount == 0 && ch == '"'.codeUnits.first) {
          stringOpen = !stringOpen;
          if (n - variable.length - 1 >= 0 && input[n - variable.length - 1] == '"') {
            valueStack.push(FVBValue(value: processString(variable)));
            variable = '';
            continue;
          } else {
            return null;
          }
        } else if (ch == '{'.codeUnits.first) {
          stringCount++;
        } else if (ch == '}'.codeUnits.first) {
          stringCount--;
        }
        variable += nextToken;

        continue;
      } else if (ch == '"'.codeUnits.first) {
        stringOpen = true;
      } else if (ch == '['.codeUnits.first) {
        int count = 0;

        for (int i = n + 1; i < input.length; i++) {
          if (input[i] == ']' && count == 0) {
            final substring = input.substring(n + 1, i);
            if (!substring.contains(',') && (valueStack.peek?.value is List || valueStack.peek?.value is Map)) {
              valueStack.push(FVBValue(value: valueStack.pop()!.value[process(substring)]));
              n = i;
              break;
            } else if (variable.isNotEmpty) {
              variable = variable + '[$substring]';
              n = i;
              break;
            } else {
              valueStack.push(FVBValue(value: CodeOperations.splitBy(substring).map((e) => process(e)).toList()));
              variable = '';
              n = i;
              break;
            }
          } else if (input[i] == '[') {
            count++;
          } else if (input[i] == ']') {
            count--;
          }
        }
        continue;
      } else if (ch == '{'.codeUnits.first) {
        if (variable.isNotEmpty && variable.startsWith('class')) {
          final className = variable.substring(5);
          final closeCurlyBracket = CodeOperations.findCloseBracket(input, n, '{'.codeUnits.first, '}'.codeUnits.first);
          final CodeProcessor processor =
              CodeProcessor(scope: Scope.object, consoleCallback: consoleCallback, onError: onError);
          processor.executeCode(input.substring(n + 1, closeCurlyBracket));
          classes[className] = FVBClass(
            className,
            processor.functions,
            processor.variables.map(
              (key, value) => MapEntry(key, FVBVariable(value.name, value.dataType)..value = value.value),
            ),
          );

          n = closeCurlyBracket;
          variable = '';
          continue;
        } else {
          int count = 0;
          for (int i = n + 1; i < input.length; i++) {
            if (input[i] == '}' && count == 0) {
              valueStack.push(
                FVBValue(
                    value: Map.from(
                  CodeOperations.splitBy(input.substring(n + 1, i)).asMap().map((e, n) {
                    final split = CodeOperations.splitBy(n, splitBy: ':');
                    return MapEntry(process(split[0]), process(split[1]));
                  }),
                )),
              );
              variable = '';
              n = i + 1;
              break;
            } else if (input[i] == '{') {
              count++;
            } else if (input[i] == '}') {
              count--;
            }
          }
        }
      } else if ((ch >= zeroCodeUnit && ch <= nineCodeUnit) || (number.isNotEmpty && ch == dotCodeUnit)) {
        if (variable.isNotEmpty) {
          variable += number + nextToken;
          number = '';
        } else {
          number += nextToken;
        }
      } else if ((ch >= capitalACodeUnit && ch <= smallZCodeUnit) ||
          ch == underScoreCodeUnit ||
          ch == '['.codeUnits.first ||
          ch == ']'.codeUnits.first ||
          ch == '~'.codeUnits.first) {
        variable += nextToken;
      } else if (ch == colonCodeUnit) {
        variables[variable] =
            VariableModel(variable, null, false, null, LocalModel.codeToDatatype(input.substring(n + 1)), '');
        variable = '';
        return null;
      } else if (ch == dotCodeUnit) {
        if (object.isNotEmpty && variable.isNotEmpty) {
          final obj = getValue(object);
          object = 'instance';
          localVariables[object] =
              getValue(variable, fvbClass: obj is FVBInstance ? obj.fvbClass : (obj is FVBClass ? obj : null));
          variable = '';
          continue;
        } else if (variable.isNotEmpty) {
          object = variable;
          variable = '';
          continue;
        } else if (valueStack.isNotEmpty) {
          variable = 'instance';
          localVariables[variable] = valueStack.pop()?.value!;
          object = variable;
          variable = '';
          continue;
        }
      } else {
        if (variable.isNotEmpty && ch == '('.codeUnits[0]) {
          int count = 0;
          for (int m = n + 1; m < input.length; m++) {
            if (input[m] == '(') {
              count++;
            }
            if (count == 0 && input[m] == ')') {
              if (variable == 'return') {
                variable = variable + input.substring(n, m + 1);
                n = m;
                continue;
              } else if (variable == 'for') {
                int endIndex = CodeOperations.findCloseBracket(input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                final insideFor = input.substring(n + 1, m);
                final innerCode = input.substring(m + 2, endIndex);
                final splits = CodeOperations.splitBy(insideFor, splitBy: ';');
                if (splits.length != 3) {
                  if (insideFor.contains(':')) {
                    final split = CodeOperations.splitBy(insideFor, splitBy: ':');
                    final list = process(split[1]);
                    if (list is! Iterable) {
                      showError('Invalid for each loop');
                    } else {
                      for (final item in list) {
                        localVariables[split[0]] = item;
                        executeCode(innerCode);
                      }
                    }
                  } else {
                    showError('For loop syntax error');
                  }
                } else {
                  process(splits[0]);
                  int count = 0;
                  while (process(splits[1]) == true) {
                    executeCode(innerCode);
                    process(splits[2]);
                    count++;
                    if (count > 1000) {
                      showError('For loop goes infinite!!');
                      break;
                    }
                  }
                }
                variable = '';
                n = endIndex;
                continue;
              }
              final argumentList = CodeOperations.splitBy(input.substring(n + 1, m));

              if (scope == Scope.object && (input.length <= m + 1 || input[m + 1] != '{')) {
                final argumentList = CodeOperations.splitBy(input.substring(n + 1, m));
                functions[variable] = FVBFunction(variable, '', processArgDefinitionList(argumentList));
                variable = '';
                n = m;
                continue;
              } else if (classes.containsKey(variable)) {
                final fvbClass = classes[variable]!;
                valueStack.push(
                  FVBValue(
                    value: fvbClass.createInstance(
                        this,
                        fvbClass.fvbFunctions.containsKey(variable)
                            ? processArgList(argumentList, fvbClass.fvbFunctions[variable]!.arguments)
                            : []),
                  ),
                );
                variable = '';
                n = m;
                continue;
              } else if (object.isNotEmpty) {
                final objectInstance = getValue(object);
                if (objectInstance is FVBInstance || objectInstance is FVBClass) {
                  final processedArgs = processArgList(
                      argumentList,
                      objectInstance is FVBInstance
                          ? objectInstance.fvbClass.getFunction(this, variable)?.arguments
                          : objectInstance.getFunction(this, variable)?.arguments);
                  final dynamic output;
                  if (objectInstance is FVBInstance) {
                    output = objectInstance.fvbClass.executeFunction(variable, processedArgs, this);
                  } else {
                    output = objectInstance.executeFunction(variable, processedArgs, this);
                  }
                  if (output != null) {
                    valueStack.push(FVBValue(value: output));
                  }
                } else if (objectInstance is String) {
                  final processedArgs = argumentList.map((e) => process(e)).toList();
                  switch (variable) {
                    case 'substring':
                      valueStack.push(FVBValue(value: objectInstance.substring(processedArgs[0], processedArgs[1])));
                      break;
                    case 'split':
                      valueStack.push(FVBValue(value: objectInstance.split(processedArgs[0])));
                      break;
                    case 'contains':
                      valueStack.push(FVBValue(value: objectInstance.contains(processedArgs[0])));
                      break;
                    case 'startsWith':
                      valueStack.push(FVBValue(value: objectInstance.startsWith(processedArgs[0])));
                      break;
                    case 'endsWith':
                      valueStack.push(FVBValue(value: objectInstance.endsWith(processedArgs[0])));
                      break;
                    case 'trim':
                      valueStack.push(FVBValue(value: objectInstance.trim()));
                      break;
                    case 'toLowerCase':
                      valueStack.push(FVBValue(value: objectInstance.toLowerCase()));
                      break;
                    case 'toUpperCase':
                      valueStack.push(FVBValue(value: objectInstance.toUpperCase()));
                      break;
                    case 'replaceAll':
                      valueStack.push(FVBValue(value: objectInstance.replaceAll(processedArgs[0], processedArgs[1])));
                      break;
                    case 'replaceFirst':
                      valueStack.push(FVBValue(value: objectInstance.replaceFirst(processedArgs[0], processedArgs[1])));
                      break;
                    case 'indexOf':
                      valueStack.push(FVBValue(
                          value: objectInstance.indexOf(
                              processedArgs[0], processedArgs.length > 1 ? processedArgs[1] : null)));
                      break;
                    case 'lastIndexOf':
                      valueStack.push(FVBValue(
                          value: objectInstance.lastIndexOf(
                              processedArgs[0], processedArgs.length > 1 ? processedArgs[1] : null)));
                      break;
                    case 'replaceRange':
                      valueStack.push(FVBValue(
                          value: objectInstance.replaceRange(processedArgs[0], processedArgs[1], processedArgs[2])));
                      break;
                  }
                } else if (objectInstance is Iterable) {
                  final processedArgs = argumentList.map((e) => process(e)).toList();
                  switch (variable) {
                    case 'add':
                      if (objectInstance is List) {
                        objectInstance.add(processedArgs[0]);
                      }
                      break;
                    case 'insert':
                      if (objectInstance is List) {
                        objectInstance.insert(processedArgs[0], processedArgs[1]);
                      }
                      break;
                    case 'clear':
                      if (objectInstance is List) {
                        objectInstance.clear();
                      }
                      break;
                    case 'addAll':
                      if (objectInstance is List) {
                        objectInstance.addAll(processedArgs[0]);
                      }
                      break;
                    case 'removeAt':
                      if (objectInstance is List) {
                        objectInstance.removeAt(processedArgs[0]);
                      }
                      break;
                    case 'remove':
                      if (objectInstance is List) {
                        objectInstance.remove(processedArgs[0]);
                      }
                      break;
                    case 'indexOf':
                      if (objectInstance is List) {
                        valueStack.push(FVBValue(
                            value: objectInstance.indexOf(
                                processedArgs[0], processedArgs.length > 1 ? processedArgs[1] : null)));
                      }
                      break;
                    case 'contains':
                      valueStack.push(FVBValue(
                          value: objectInstance.contains(
                        processedArgs[0],
                      )));
                      break;
                    case 'where':
                      valueStack.push(FVBValue(
                          value: objectInstance.where((e) => (processedArgs[0] as FVBFunction).execute(this, [e]))));
                      break;
                    case 'indexWhere':
                      if (objectInstance is List) {
                        valueStack.push(FVBValue(
                            value: objectInstance
                                .indexWhere((e) => (processedArgs[0] as FVBFunction).execute(this, [e]))));
                      }
                      break;
                    case 'firstWhere':
                      valueStack.push(FVBValue(
                          value:
                              objectInstance.firstWhere((e) => (processedArgs[0] as FVBFunction).execute(this, [e]))));
                      break;
                    case 'any':
                      valueStack.push(FVBValue(
                          value: objectInstance.any((e) => (processedArgs[0] as FVBFunction).execute(this, [e]))));
                      break;

                    case 'forEach':
                      for (var e in objectInstance) {
                        (processedArgs[0] as FVBFunction).execute(this, [e]);
                      }
                      break;

                    case 'sort':
                      if (objectInstance is List) {
                        objectInstance.sort();
                      }
                      break;

                    case 'map':
                      valueStack.push(FVBValue(
                          value: objectInstance.map((e) => (processedArgs[0] as FVBFunction).execute(this, [e]))));
                      break;
                    case 'reduce':
                      valueStack.push(FVBValue(
                          value: objectInstance
                              .reduce((e, f) => (processedArgs[0] as FVBFunction).execute(this, [e, f]))));
                      break;
                    case 'fold':
                      valueStack.push(FVBValue(
                          value: objectInstance.fold(
                              processedArgs[0], (e, f) => (processedArgs[1] as FVBFunction).execute(this, [e, f]))));
                      break;
                    case 'every':
                      valueStack.push(FVBValue(
                          value: objectInstance.every((e) => (processedArgs[0] as FVBFunction).execute(this, [e]))));
                      break;
                    case 'expand':
                      valueStack.push(FVBValue(
                          value: objectInstance.expand((e) => (processedArgs[0] as FVBFunction).execute(this, [e]))));
                      break;
                    case 'take':
                      valueStack.push(FVBValue(value: objectInstance.take(processedArgs[0])));
                      break;
                    case 'takeWhile':
                      valueStack.push(FVBValue(
                          value:
                              objectInstance.takeWhile((e) => (processedArgs[0] as FVBFunction).execute(this, [e]))));
                      break;
                    case 'skip':
                      valueStack.push(FVBValue(value: objectInstance.skip(processedArgs[0])));
                      break;
                    case 'skipWhile':
                      valueStack.push(FVBValue(
                          value:
                              objectInstance.skipWhile((e) => (processedArgs[0] as FVBFunction).execute(this, [e]))));
                      break;
                    case 'elementAt':
                      valueStack.push(FVBValue(value: objectInstance.elementAt(processedArgs[0])));
                      break;
                    case 'sublist':
                      if (objectInstance is List) {
                        valueStack.push(FVBValue(value: objectInstance.sublist(processedArgs[0], processedArgs[1])));
                      }
                      break;
                    case 'getRange':
                      if (objectInstance is List) {
                        valueStack.push(FVBValue(value: objectInstance.getRange(processedArgs[0], processedArgs[1])));
                      }
                      break;
                    case 'removeRange':
                      if (objectInstance is List) {
                        objectInstance.removeRange(processedArgs[0], processedArgs[1]);
                      }
                      break;
                    case 'setRange':
                      if (objectInstance is List) {
                        objectInstance.setRange(processedArgs[0], processedArgs[1], processedArgs[2]);
                      }
                      break;
                    case 'fillRange':
                      if (objectInstance is List) {
                        objectInstance.fillRange(processedArgs[0], processedArgs[1], processedArgs[2]);
                      }
                      break;
                    case 'toList':
                      valueStack.push(FVBValue(
                          value: objectInstance.toList(growable: processedArgs.isNotEmpty ? processedArgs[0] : true)));
                      break;
                    case 'toSet':
                      valueStack.push(FVBValue(value: objectInstance.toSet()));
                      break;
                    case 'asMap':
                      if (objectInstance is List) {
                        valueStack.push(FVBValue(value: objectInstance.asMap()));
                      }
                      break;
                  }
                } else if (objectInstance is Map) {
                  final processedArgs = argumentList.map((e) => process(e)).toList();
                  switch (variable) {
                    case 'remove':
                      objectInstance.remove(processedArgs[0]);
                      break;
                    case 'containsKey':
                      valueStack.push(FVBValue(value: objectInstance.containsKey(processedArgs[0])));
                      break;
                    case 'containsValue':
                      valueStack.push(FVBValue(value: objectInstance.containsValue(processedArgs[0])));
                      break;
                    case 'map':
                      valueStack.push(FVBValue(
                          value: objectInstance
                              .map((key, value) => (processedArgs[0] as FVBFunction).execute(this, [key, value]))));
                      break;
                    case 'forEach':
                      objectInstance.forEach((key, value) {
                        (processedArgs[0] as FVBFunction).execute(this, [key, value]);
                      });
                      break;
                    case 'clear':
                      objectInstance.clear();
                      break;
                  }
                }
                variable = '';
                object = '';
                n = m;
                continue;
              } else if (variable == 'while') {
                int endIndex = CodeOperations.findCloseBracket(input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);

                final innerCode = input.substring(m + 2, endIndex);
                final conditionalCode = input.substring(n + 1, m);
                int count = 0;
                while (process(conditionalCode) == true) {
                  executeCode(innerCode);
                  count++;
                  if (count > 1000) {
                    showError('While loop goes infinite!!');
                    break;
                  }
                }
                variable = '';
                n = endIndex;
                continue;
              } else if (variable == 'if') {
                final List<ConditionalStatement> conditionalStatements = [];
                int endBracket =
                    CodeOperations.findCloseBracket(input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                conditionalStatements.add(ConditionalStatement(argumentList[0], input.substring(m + 2, endBracket)));
                n = endBracket;
                while (input.length > endBracket + 7 && input.substring(endBracket + 1, endBracket + 5) == 'else') {
                  int startBracket = endBracket + 5;
                  if (input.substring(startBracket, endBracket + 7) == 'if') {
                    startBracket += 2;
                    int endRoundBracket =
                        CodeOperations.findCloseBracket(input, startBracket, '('.codeUnits.first, ')'.codeUnits.first);
                    endBracket = CodeOperations.findCloseBracket(
                        input, endRoundBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                    conditionalStatements.add(ConditionalStatement(
                      input.substring(startBracket + 1, endRoundBracket),
                      input.substring(endRoundBracket + 2, endBracket),
                    ));
                  } else {
                    endBracket =
                        CodeOperations.findCloseBracket(input, startBracket, '{'.codeUnits.first, '}'.codeUnits.first);
                    conditionalStatements.add(
                      ConditionalStatement(
                        null,
                        input.substring(startBracket + 1, endBracket),
                      ),
                    );
                  }
                  n = endBracket;
                }

                for (final statement in conditionalStatements) {
                  if (statement.condition == null) {
                    executeCode(statement.body);
                  } else if (process(statement.condition!) == true) {
                    executeCode(statement.body);
                    break;
                  }
                }
                variable = '';
                continue;
              } else if (input.length > m + 1 && input[m + 1] == '{') {
                int closeBracketIndex =
                    CodeOperations.findCloseBracket(input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                if (closeBracketIndex < 0) {
                  error = true;
                  errorMessage = 'Invalid function syntax!!';
                  return;
                }
                final argumentList = CodeOperations.splitBy(input.substring(n + 1, m));
                functions[variable] = FVBFunction(
                    variable, input.substring(m + 2, closeBracketIndex), processArgDefinitionList(argumentList));
                variable = '';
                n = closeBracketIndex;
                continue;
              } else if (functions.containsKey(variable)) {
                final argumentList = CodeOperations.splitBy(input.substring(n + 1, m));
                final output =
                    functions[variable]!.execute(this, processArgList(argumentList, functions[variable]!.arguments));
                if (output != null) {
                  valueStack.push(FVBValue(value: output));
                }
                variable = '';
                n = m;
                continue;
              } else if (variables.containsKey(variable) || localVariables.containsKey(variable)) {
                final function = (variables[variable]?.value ?? localVariables[variable]) as FVBFunction;
                final argumentList = CodeOperations.splitBy(input.substring(n + 1, m));
                final output = function.execute(this, processArgList(argumentList, function.arguments));
                if (output != null) {
                  valueStack.push(FVBValue(value: output));
                }
                variable = '';
                n = m;
                continue;
              } else if (!predefinedFunctions.containsKey(variable)) {
                showError('No predefined function named $variable found');
                return;
              } else {
                final processedArgs = argumentList.map((e) => process(e)).toList();
                final output = predefinedFunctions[variable]!.perform.call(processedArgs);
                valueStack.push(FVBValue(value: output));
                variable = '';
                n = m;
              }
              continue;
            } else if (input[m] == ')') {
              count--;
            }
          }
          continue;
        } else if (ch == '('.codeUnits[0]) {
          final closeOpenBracket = CodeOperations.findCloseBracket(input, n, '('.codeUnits.first, ')'.codeUnits.first);
          if (closeOpenBracket + 1 < input.length &&
              input[closeOpenBracket + 1] == '=' &&
              input[closeOpenBracket + 2] == '>') {
            final argumentList = CodeOperations.splitBy(input.substring(n + 1, closeOpenBracket));

            final arguments = processArgDefinitionList(argumentList);
            final function = FVBFunction('', input.substring(closeOpenBracket + 3, input.length), arguments);
            n = input.length - 1;
            valueStack.push(FVBValue(value: function));
            continue;
          } else if (input.length > closeOpenBracket + 1 && input[closeOpenBracket + 1] == '{') {
            final int closeCurlyBracketIndex =
                CodeOperations.findCloseBracket(input, closeOpenBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);
            final argumentList = CodeOperations.splitBy(input.substring(n + 1, closeOpenBracket))
                .where((element) => element.isNotEmpty)
                .toList();
            final arguments = processArgDefinitionList(argumentList);
            final function = FVBFunction('', input.substring(closeOpenBracket + 2, closeCurlyBracketIndex), arguments);
            n = closeCurlyBracketIndex;
            valueStack.push(FVBValue(value: function));
            continue;
          }
        }

        if (number.isNotEmpty) {
          parseNumber(number, valueStack);
          number = '';
        }

        if (isOperator(ch)) {
          String operator = input[n];
          if (n + 1 < input.length && isOperator(input[n + 1].codeUnits.first)) {
            operator = operator + input[n + 1];
            n++;
          }
          if (operatorStack.isEmpty || getPrecedence(operator) > getPrecedence(operatorStack.peek!)) {
            operatorStack.push(operator);
          } else {
            while (operatorStack.isNotEmpty && getPrecedence(operator) <= getPrecedence(operatorStack.peek!)) {
              processOperator(operatorStack.pop()!, valueStack, operatorStack);
            }
            operatorStack.push(operator);
          }
        } else if (ch == '('.codeUnits[0]) {
          final index = CodeOperations.findCloseBracket(input, n, '('.codeUnits.first, ')'.codeUnits.first);
          if (index == -1) {
            return null;
          }
          final innerProcess = process<T>(input.substring(n + 1, index), resolve: true);
          if (innerProcess != null) {
            valueStack.push(FVBValue(value: innerProcess));
            n = index;
            continue;
          } else {
            return null;
          }
        }
        if (variable.isNotEmpty) {
          if (!resolveVariable(variable, object, valueStack)) {
            return null;
          }

          variable = '';
        }
      }
    }
    if (number.isNotEmpty) {
      parseNumber(number, valueStack);
      number = '';
    } else if (variable.isNotEmpty) {
      if (!resolveVariable(variable, object, valueStack)) {
        return null;
      }
      variable = '';
    }

    // Empty out the operator stack at the end of the input
    while (operatorStack.isNotEmpty) {
      processOperator(operatorStack.pop()!, valueStack, operatorStack);
    }

    // Print the result if no error has been seen.
    if (!error && valueStack.isNotEmpty) {
      dynamic result;
      while (valueStack.isNotEmpty) {
        final value = valueStack.pop()!;
        result = value.evaluateValue(this);
        if (result == null && value.variableName != null && value.createVarIfNotExist) {
          final variable = value.variableName!;
          variables[variable] =
              VariableModel(variable, value.value, false, null, DataType.dynamic, '', isFinal: value.isVarFinal);
        }
      }

      if (operatorStack.isNotEmpty || valueStack.isNotEmpty) {
        logger('Expression error.');
      } else {
        return result;
      }
    }
    return null;
  }

  List<dynamic> processArgList(List<String> argumentList, List<FVBArgument> arguments) {
    return ArgumentProcessor.process(this, argumentList, arguments);
  }

  List<FVBArgument> processArgDefinitionList(List<String> argumentList) {
    return ArgumentProcessor.processArgumentDefinition(this, argumentList);
  }

  void parseNumber(String number, valueStack) {
    final parse = double.tryParse(number);
    if (parse != null) {
      valueStack.push(FVBValue(value: parse));
    } else {
      final intParsed = int.tryParse(number);
      if (intParsed != null) {
        valueStack.push(FVBValue(value: intParsed));
      } else {
        showError('Invalid number $number');
        return;
      }
    }
  }

  void showError(String message) {
    error = true;
    errorMessage = message;
  }

  bool isString(String value) {
    if (value.length >= 2) {
      return value[0] == value[value.length - 1] && (value[0] == '\'' || value[0] == '"');
    }
    return false;
  }

  bool resolveVariable(String variable, String object, valueStack) {
    if (variable.startsWith('return~')) {
      valueStack.push(FVBValue(
          value: process(
        variable.substring(7),
      )));
      return true;
    } else if (variable.startsWith('var~')) {
      valueStack.push(FVBValue(variableName: variable.substring(4), createVarIfNotExist: true)..evaluateValue(this));
      return true;
    } else if (variable.startsWith('final~')) {
      valueStack.push(FVBValue(variableName: variable.substring(6), isVarFinal: true, createVarIfNotExist: true)
        ..evaluateValue(this));
      return true;
    }
    if (object.isNotEmpty) {
      final value = getValue(object);
      if (value is String) {
        switch (variable) {
          case 'length':
            valueStack.push(FVBValue(value: value.length));
            return true;
        }
      } else if (value is List) {
        switch (variable) {
          case 'length':
            valueStack.push(FVBValue(value: value.length));
            break;
        }
        object = '';
        variable = '';
      } else if (value is FVBInstance) {
        valueStack.push(FVBValue(value: getValue(variable, fvbClass: value.fvbClass)));
      } else if (value is FVBClass) {
        valueStack.push(FVBValue(value: getValue(variable, fvbClass: value)));
      }
      return true;
    }

    valueStack.push(FVBValue(variableName: variable)..evaluateValue(this));
    return true;
  }
}

class Stack2<E> {
  final _list = <E>[];

  void push(E value) {
    logger('PUSH = $_list + $value');
    _list.add(value);
  }

  E? pop() => isNotEmpty ? _list.removeLast() : null;

  E? get peek => isNotEmpty ? _list.last : null;

  bool get isEmpty => _list.isEmpty;

  bool get isNotEmpty => _list.isNotEmpty;

  void clear() {
    _list.clear();
  }

  @override
  String toString() => _list.toString();
}

class CodeOutput {
  String? result;
  String? error;

  CodeOutput(this.result, this.error);

  factory CodeOutput.left(String result) {
    return CodeOutput(result, null);
  }

  factory CodeOutput.right(String error) {
    return CodeOutput(null, error);
  }
}

class ConditionalStatement {
  final String? condition;
  final String body;

  ConditionalStatement(this.condition, this.body);
}
