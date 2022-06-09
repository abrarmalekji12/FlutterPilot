import 'dart:core';
import 'dart:io';
import 'dart:math' as math;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../code_to_component.dart';
import '../../component_list.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../models/function_model.dart';
import '../../models/local_model.dart';
import '../../models/other_model.dart';
import '../../models/variable_model.dart';
import '../../ui/models_view.dart';
import '../logger.dart';

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
  final Map<String, FVBVariable> fvbVariables;

  FVBClass(this.name, this.fvbFunctions, this.fvbVariables);

  FVBInstance createInstance(
      final CodeProcessor processor, final List<dynamic> arguments) {
    final instance = FVBInstance(
      FVBClass(
        name,
        fvbFunctions,
        fvbVariables.map(
          (key, value) => MapEntry(key, value.clone()),
        ),
      ),
    );
    if (fvbFunctions.containsKey(name)) {
      instance.fvbClass.executeFunction(name, arguments, processor, null, null);
    }
    return instance;
  }

  executeFunction(String name, List<dynamic> arguments, CodeProcessor processor,
      consoleCallback, onError) async {
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

    final output = fvbFunctions[name]!
        .execute(processor, arguments, consoleCallback, onError);

    for (final MapEntry<String, FVBVariable> entry in fvbVariables.entries) {
      final type = CodeOperations.getDatatypeToDartType(entry.value.dataType);
      final assignedType = processor.localVariables[entry.key].runtimeType;
      if (![
            DataType.int,
            DataType.double,
            DataType.string,
            DataType.bool,
            DataType.fvbInstance
          ].contains(entry.value.dataType) ||
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

class FVBFunction {
  String? code;
  Function(List<dynamic>)? dartCall;
  final String name;
  final Map<String, FVBVariable> localVariables = {};
  final List<String> arguments;

  FVBFunction(this.name, this.code, this.arguments);

  dynamic execute(
      final CodeProcessor processor,
      final List<dynamic> argumentValues,
      String? Function(String)? consoleCallback,
      void Function(String)? onError) async {
    if (arguments.length != argumentValues.length) {
      processor.showError('Not enough arguments in function $name ');
    }
    if (dartCall != null) {
      return dartCall?.call(argumentValues);
    }
    final Map<String, dynamic> oldVariables = {};
    final Map<String, dynamic> globalVariables = {};

    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i].startsWith('this.')) {
        final name = arguments[i].substring(5);
        if (processor.localVariables.containsKey(name)) {
          processor.localVariables[name] = argumentValues[i];
        } else {
          processor.error = true;
          processor.errorMessage = 'No variable named "$name" found';
        }
      } else {
        if (processor.localVariables.containsKey(arguments[i])) {
          oldVariables[arguments[i]] = processor.localVariables[arguments[i]];
        }
        if (processor.variables.containsKey(arguments[i])) {
          globalVariables[arguments[i]] =
              processor.variables[arguments[i]]?.value;
          processor.variables[arguments[i]]?.value = argumentValues[i];
        }
        processor.localVariables[arguments[i]] = argumentValues[i];
      }
    }

    final variables = Map<String, VariableModel>.from(processor.variables);
    final output = processor.executeCode(code!, consoleCallback, onError);
    processor.variables.clear();
    processor.variables.addAll(variables);
    for (int i = 0; i < arguments.length; i++) {
      if (oldVariables.containsKey(arguments[i])) {
        processor.localVariables[arguments[i]] = oldVariables[arguments[i]];
      } else {
        processor.localVariables.remove(arguments[i]);
      }
    }
    for (final entry in globalVariables.entries) {
      processor.variables[entry.key]?.value = entry.value;
    }
    return output;
  }
}

class FVBValue {
  dynamic value;
  final String? variableName;

  FVBValue({
    this.value,
    this.variableName,
  });

  evaluateValue(CodeProcessor processor) {
    if (variableName == null) {
      return value;
    }
    return value = processor.getValue(variableName!);
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
  static final fvbClasses = {
    'TextField': FVBClass('TextField', {
      'setText': FVBFunction('setText', null, ['text']),
      'clear': FVBFunction('clear', '', []),
    }, {
      'text': FVBVariable('text', DataType.string),
    }),
    'Api': FVBClass('Api', {
      'get': FVBFunction('get', null, ['url'])
        ..dartCall = (arguments) async {
          return (await http.get(arguments[0])).body;
        },
    }, {})
  };
  final Map<String, VariableModel> variables = {};
  final Map<String, FunctionModel> predefinedFunctions = {};
  final Map<String, FVBFunction> functions = {};
  final Map<String, FVBClass> classes = {};
  final Map<String, dynamic> localVariables = {};
  final Scope scope;
  late bool error;
  String errorMessage = '';
  final capitalACodeUnit = 'A'.codeUnits.first,
      smallZCodeUnit = 'z'.codeUnits.first,
      underScoreCodeUnit = '_'.codeUnits.first;
  final zeroCodeUnit = '0'.codeUnits.first,
      nineCodeUnit = '9'.codeUnits.first,
      dotCodeUnit = '.'.codeUnits.first,
      colonCodeUnit = ':'.codeUnits.first;

  CodeProcessor({this.scope = Scope.main}) {
    error = false;
    variables['pi'] = VariableModel(
        'pi', pi, false, 'it is mathematical value of pi', DataType.double, '',
        deletable: false);
    classes.addAll(fvbClasses);
    predefinedFunctions['res'] = FunctionModel<dynamic>('res', (arguments) {
      if (variables['dw']!.value > variables['tabletWidthLimit']!.value) {
        return arguments[0];
      } else if (variables['dw']!.value > variables['phoneWidthLimit']!.value ||
          arguments.length == 2) {
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

    predefinedFunctions['ifElse'] =
        FunctionModel<dynamic>('ifElse', (arguments) {
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

    predefinedFunctions['randDouble'] =
        FunctionModel<double>('randDouble', (arguments) {
      return math.Random.secure().nextDouble();
    }, '''
    double randDouble(){
    return math.Random.secure().nextDouble();
    }
    ''');
    predefinedFunctions['randBool'] =
        FunctionModel<bool>('randBool', (arguments) {
      return math.Random.secure().nextBool();
    }, '''
    bool randBool(){
    return math.Random.secure().nextBool();
    }
    ''');
    predefinedFunctions['randColor'] =
        FunctionModel<String>('randColor', (arguments) {
      return '#' +
          Colors.primaries[math.Random().nextInt(Colors.primaries.length)].value
              .toRadixString(16);
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
      return arguments[0].toString();
    }, ''' ''');

    predefinedFunctions['showSnackbar'] =
        FunctionModel<dynamic>('showSnackbar', (arguments) {
      if (arguments.length < 2) {
        error = true;
        errorMessage = 'showSnackbar requires 2 arguments!!';
        return null;
      }
      return 'api:snackbar|${arguments[0]}|${arguments[1]}';
    }, ''' ''');
    predefinedFunctions['newPage'] =
        FunctionModel<dynamic>('newPage', (arguments) {
      if (arguments.isEmpty) {
        error = true;
        errorMessage = 'newPage requires 1 argument!!';
        return null;
      }
      return 'api:newpage|${arguments[0]}';
    }, ''' ''');
    predefinedFunctions['goBack'] =
        FunctionModel<dynamic>('goBack', (arguments) {
      return 'api:goback|';
    }, ''' ''');

    predefinedFunctions['toInt'] = FunctionModel<int?>('toInt', (arguments) {
      return int.tryParse(arguments[0]);
    }, ''' ''');
    predefinedFunctions['toDouble'] =
        FunctionModel<double?>('toDouble', (arguments) {
      return double.tryParse(arguments[0]);
    }, ''' ''');

    predefinedFunctions['lookUp'] =
        FunctionModel<dynamic>('lookUp', (arguments) {
      final id = arguments[0];
      FVBInstance? out;
      ComponentOperationCubit.currentFlutterProject?.currentScreen.rootComponent
          ?.forEach((p0) {
        if (p0.id == id) {
          if (p0 is CTextField) {
            out = fvbClasses['TextField']?.createInstance(this, [])
              ?..fvbClass.fvbVariables['text']?.value =
                  p0.textEditingController.text
              ..fvbClass.fvbFunctions['setText']?.dartCall = (arguments) {
                p0.textEditingController.text = arguments[0];
              };
          }
        }
      });
      return out;
    }, ''' ''');

    predefinedFunctions['refresh'] =
        FunctionModel<String>('refresh', (arguments) {
      return 'api:refresh|${arguments[0]}';
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
    if (ch == '+' || ch == '-') {
      return 1;
    }
    if (ch == '*' ||
        ch == '/' ||
        ch == '<' ||
        ch == '>' ||
        ch == '<=' ||
        ch == '>=') {
      return 2;
    }
    return 0;
  }

  dynamic getValue(final String variable, {FVBInstance? fvbInstance}) {
    if (variable.contains('[')) {
      return getOrSetListMapBracketValue(variable, fvbInstance: fvbInstance);
    } else if (variable == 'true') {
      return true;
    } else if (variable == 'false') {
      return false;
    } else if (fvbInstance != null &&
        fvbInstance.fvbClass.fvbVariables.containsKey(variable)) {
      return fvbInstance.fvbClass.fvbVariables[variable]!.value;
    } else if (variables.containsKey(variable)) {
      return variables[variable]!.value;
    } else if (localVariables.containsKey(variable)) {
      return localVariables[variable];
    }
    return null;
  }

  bool setValue(final String variable, dynamic value) {
    if (variable.contains('[')) {
      getOrSetListMapBracketValue(variable, value: value);
      return true;
    } else if (variables.containsKey(variable)) {
      variables[variable]!.value = value;
      return true;
    } else if (localVariables.containsKey(variable)) {
      localVariables[variable] = value;
      return true;
    }
    return false;
  }

  getOrSetListMapBracketValue(String variable,
      {dynamic value, FVBInstance? fvbInstance}) {
    int openBracket = variable.indexOf('[');
    if (openBracket != -1) {
      final closeBracket = CodeOperations.findCloseBracket(
          variable, openBracket, '['.codeUnits.first, ']'.codeUnits.first);
      final key = process(variable.substring(openBracket + 1, closeBracket));
      final subVar = variable.substring(0, openBracket);
      openBracket = variable.indexOf('[', closeBracket);
      dynamic mapValue = getValue(subVar, fvbInstance: fvbInstance);
      if (value != null && openBracket == -1) {
        mapValue[key] = value;
        return true;
      } else {
        if ((mapValue is Map && mapValue.containsKey(key)) ||
            (mapValue is List && key is int && key < mapValue.length)) {
          mapValue = mapValue[key];
        } else {
          showError('can not use [ ] with $mapValue', throwError: false);
          return null;
        }
      }
      while (openBracket != -1) {
        final closeBracket = CodeOperations.findCloseBracket(
            variable, openBracket, '['.codeUnits.first, ']'.codeUnits.first);
        final key = process(variable.substring(openBracket + 1, closeBracket));
        openBracket = variable.indexOf('[', closeBracket);
        if (value != null && openBracket == -1) {
          mapValue[key] = value;
        } else {
          if ((mapValue is Map && mapValue.containsKey(key)) ||
              (mapValue is List && key is int && key < mapValue.length)) {
            mapValue = mapValue[key];
          } else {
            showError('can not use [ ] with $mapValue', throwError: false);
            return null;
          }
        }
      }
      return mapValue;
    }
  }

  void processOperator(final String operator, final Stack2<FVBValue> valueStack,
      final Stack2<String> operatorStack) {
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
    if (valueStack.isEmpty &&
        operator != '-' &&
        operator != '--' &&
        operator != '++' &&
        operator != '!') {
      error = true;
      errorMessage = 'Not enough values, syntax error !!';
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
        r = pow(a, int.parse(b.toString()));
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
        final value = getValue(aVar.variableName!);
        if (value != null || aVar.variableName!.contains('[')) {
          setValue(aVar.variableName!, b);
        } else {
          late final DataType dataType;
          if (b == null) {
            dataType = DataType.dynamic;
          } else if (b is double) {
            dataType = DataType.double;
          } else if (b is int) {
            dataType = DataType.int;
          } else if (b is String) {
            dataType = DataType.string;
          } else if (b is bool) {
            dataType = DataType.bool;
          } else if (b is List) {
            dataType = DataType.list;
          } else if (b is Map) {
            dataType = DataType.map;
          } else if (b is FVBInstance) {
            dataType = DataType.fvbInstance;
          } else {
            throw Exception('Invalid datatype of variable');
          }
          aVar.value = b;
          variables[aVar.variableName!] = VariableModel(
              aVar.variableName!, b, false, null, dataType, '',
              type: dataType == DataType.fvbInstance
                  ? (b as FVBInstance).fvbClass.name
                  : null);
        }
        r = null;
        break;
      case '++':
        final name = bVar.variableName!;
        final value = getValue(name);
        r = null;
        if (value != null) {
          setValue(name, value! + 1);
        } else {
          showError('Variable $name is not defined');
        }
        break;
      case '+=':
        final name = aVar.variableName!;
        final value = getValue(name);
        r = null;
        if (value != null) {
          setValue(name, value! + b);
        } else {
          showError('Variable $name is not defined');
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
        r = null;
        if (value != null) {
          setValue(name, value! * b);
        } else {
          showError('Variable $name is not defined');
        }
        break;
      case '/=':
        final name = aVar.variableName!;
        final value = getValue(name);
        r = null;
        if (value != null) {
          setValue(name, value! / b);
        } else {
          showError('Variable $name is not defined');
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

  String? processString(String code,
      {String? Function(String)? consoleCallback,
      void Function(String)? onError}) {
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
      final value = process<String>(variableName,
          resolve: true, consoleCallback: consoleCallback, onError: onError);
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

  dynamic executeCode(
      final String input,
      String? Function(String)? consoleCallback,
      void Function(String)? onError) {
    final trimCode = CodeOperations.trim(input)!;
    logger('TRIMMED \n $trimCode \n');
    int count = 0;
    int lastPoint = 0;
    dynamic globalOutput;
    for (int i = 0; i < trimCode.length; i++) {
      if (trimCode[i] == '{' || trimCode[i] == '[' || trimCode[i] == '(') {
        count++;
      } else if (trimCode[i] == '}' ||
          trimCode[i] == ']' ||
          trimCode[i] == ')') {
        count--;
      }
      if (count == 0 && (trimCode[i] == ';' || trimCode.length == i + 1)) {
        logger(
            'EXEC \n ${trimCode.substring(lastPoint, trimCode.length == i + 1 ? i + 1 : i)} \n-------');
        final output = process(
            trimCode.substring(lastPoint, trimCode.length == i + 1 ? i + 1 : i),
            consoleCallback: consoleCallback,
            onError: onError);
        lastPoint = i + 1;
        if (error) {
          onError?.call(errorMessage);
        } else if (output != null) {
          globalOutput = output;
          consoleCallback?.call(output.toString());
        }
      }
    }
    return globalOutput;
  }

  dynamic process<T>(final String input,
      {bool resolve = false,
      String? Function(String)? consoleCallback,
      void Function(String)? onError}) {
    final Stack2<FVBValue> valueStack = Stack2<FVBValue>();
    final Stack2<String> operatorStack = Stack2<String>();
    String number = '';
    bool stringOpen = false;
    String variable = '';
    String object = '';
    error = false;
    if ((T == String || T == ImageData || isString(input)) && !resolve) {
      if (T != String && T != ImageData) {
        return processString(input.substring(1, input.length - 1),
            consoleCallback: consoleCallback, onError: onError);
      }
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
      if (ch != '"'.codeUnits.first && stringOpen) {
        variable += nextToken;
        continue;
      }
      if (ch == '"'.codeUnits.first) {
        stringOpen = !stringOpen;
        if (variable.isEmpty) {
          continue;
        }
        if (n - variable.length - 1 >= 0 &&
            input[n - variable.length - 1] == '"') {
          valueStack.push(FVBValue(
              value: processString(variable,
                  consoleCallback: consoleCallback, onError: onError)));
          variable = '';
          continue;
        } else {
          return null;
        }
      } else if (ch == '['.codeUnits.first) {
        int count = 0;

        for (int i = n + 1; i < input.length; i++) {
          if (input[i] == ']' && count == 0) {
            final substring = input.substring(n + 1, i);
            if (!substring.contains(',') &&
                (valueStack.peek?.value is List ||
                    valueStack.peek?.value is Map)) {
              valueStack.push(FVBValue(
                  value: valueStack.pop()!.value[process(substring,
                      consoleCallback: consoleCallback, onError: onError)]));
              n = i;
              break;
            } else if (variable.isNotEmpty) {
              variable = variable + '[$substring]';
              n = i;
              break;
            } else {
              valueStack.push(FVBValue(
                  value: CodeOperations.splitBy(substring)
                      .map((e) => process(e,
                          consoleCallback: consoleCallback, onError: onError))
                      .toList()));
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
          final closeCurlyBracket = CodeOperations.findCloseBracket(
              input, n, '{'.codeUnits.first, '}'.codeUnits.first);
          final instructions = CodeOperations.getFVBInstructionsFromCode(
              input.substring(n + 1, closeCurlyBracket));
          final CodeProcessor processor = CodeProcessor(scope: Scope.object);
          for (final instruction in instructions) {
            processor.process(instruction);
          }
          classes[className] = FVBClass(
            className,
            processor.functions,
            processor.variables.map(
              (key, value) => MapEntry(key,
                  FVBVariable(value.name, value.dataType)..value = value.value),
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
                  CodeOperations.splitBy(input.substring(n + 1, i))
                      .asMap()
                      .map((e, n) {
                    final split = CodeOperations.splitBy(n, splitBy: ':');
                    return MapEntry(
                        process(split[0],
                            consoleCallback: consoleCallback, onError: onError),
                        process(split[1],
                            consoleCallback: consoleCallback,
                            onError: onError));
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
      } else if ((ch >= zeroCodeUnit && ch <= nineCodeUnit) ||
          (number.isNotEmpty && ch == dotCodeUnit)) {
        if (variable.isNotEmpty) {
          variable += number + nextToken;
          number = '';
        } else {
          number += nextToken;
        }
      } else if ((ch >= capitalACodeUnit && ch <= smallZCodeUnit) ||
          ch == underScoreCodeUnit ||
          ch == '['.codeUnits.first ||
          ch == ']'.codeUnits.first) {
        variable += nextToken;
      } else if (ch == colonCodeUnit) {
        variables[variable] = VariableModel(variable, null, false, null,
            LocalModel.codeToDatatype(input.substring(n + 1)), '');
        variable = '';
        return null;
      } else if (ch == dotCodeUnit) {
        if (object.isNotEmpty && variable.isNotEmpty) {
          final obj = getValue(object);
          object = 'instance';
          localVariables[object] =
              getValue(variable, fvbInstance: obj is FVBInstance ? obj : null);
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
                int endIndex = CodeOperations.findCloseBracket(
                    input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                final insideFor = input.substring(n + 1, m);
                final innerCode = input.substring(m + 2, endIndex);
                final splits = CodeOperations.splitBy(insideFor, splitBy: ';');
                if (splits.length != 3) {
                  if (insideFor.contains(':')) {
                    final split =
                        CodeOperations.splitBy(insideFor, splitBy: ':');
                    final list = process(split[1],
                        consoleCallback: consoleCallback, onError: onError);
                    if (list is! List) {
                      showError('Invalid for each loop');
                    } else {
                      for (final item in list) {
                        localVariables[split[0]] = item;
                        executeCode(innerCode, consoleCallback, onError);
                      }
                    }
                  } else {
                    showError('For loop syntax error');
                  }
                } else {
                  process(splits[0],
                      consoleCallback: consoleCallback, onError: onError);
                  int count = 0;
                  while (process(splits[1],
                          consoleCallback: consoleCallback, onError: onError) ==
                      true) {
                    executeCode(innerCode, consoleCallback!, onError!);
                    process(splits[2],
                        consoleCallback: consoleCallback, onError: onError);
                    count++;
                    if (count > 1000) {
                      onError.call('For loop goes infinite!!');
                      break;
                    }
                  }
                }
                variable = '';
                n = endIndex;
                continue;
              }
              final argumentList =
                  CodeOperations.splitBy(input.substring(n + 1, m));
              if (scope == Scope.object &&
                  (input.length <= m + 1 || input[m + 1] != '{')) {
                final argumentList =
                    CodeOperations.splitBy(input.substring(n + 1, m));
                functions[variable] = FVBFunction(variable, '', argumentList);
                variable = '';
                n = m;
                continue;
              } else if (classes.keys.contains(variable)) {
                valueStack.push(FVBValue(
                    value: classes[variable]!.createInstance(
                        this,
                        argumentList
                            .map((e) => process(e,
                                consoleCallback: consoleCallback,
                                onError: onError))
                            .toList())));
                variable = '';
                n = m;
                continue;
              } else if (object.isNotEmpty) {
                final objectInstance = getValue(object);
                if (objectInstance is FVBInstance) {
                  final output = objectInstance.fvbClass.executeFunction(
                      variable,
                      argumentList
                          .map((e) => process(e,
                              consoleCallback: consoleCallback,
                              onError: onError))
                          .toList(),
                      this,
                      consoleCallback,
                      onError);
                  if (output != null) {
                    valueStack.push(FVBValue(value: output));
                  }
                } else if (objectInstance is List) {
                  switch (variable) {
                    case 'add':
                      objectInstance.add(process(argumentList[0],
                          consoleCallback: consoleCallback, onError: onError));
                      break;
                    case 'removeAt':
                      objectInstance.removeAt(process(argumentList[0],
                          consoleCallback: consoleCallback, onError: onError));
                      break;
                    case 'remove':
                      objectInstance.remove(process(argumentList[0],
                          consoleCallback: consoleCallback, onError: onError));
                      break;
                    case 'indexOf':
                      valueStack.push(FVBValue(
                          value: objectInstance.indexOf(process(argumentList[0],
                              consoleCallback: consoleCallback,
                              onError: onError))));
                      break;
                    case 'contains':
                      valueStack.push(FVBValue(
                          value: objectInstance.contains(process(
                              argumentList[0],
                              consoleCallback: consoleCallback,
                              onError: onError))));
                      break;

                    case 'sort':
                      objectInstance.sort();
                      break;
                  }
                } else if (objectInstance is Map) {
                  switch (variable) {
                    case 'remove':
                      objectInstance.remove(process(argumentList[0],
                          consoleCallback: consoleCallback, onError: onError));
                      break;
                    case 'containsKey':
                      valueStack.push(FVBValue(
                          value: objectInstance.containsKey(process(
                              argumentList[0],
                              consoleCallback: consoleCallback,
                              onError: onError))));
                      break;
                    case 'containsValue':
                      valueStack.push(FVBValue(
                          value: objectInstance.containsValue(process(
                              argumentList[0],
                              consoleCallback: consoleCallback,
                              onError: onError))));
                      break;
                  }
                }
                variable = '';
                object = '';
                n = m;
                continue;
              } else if (variable == 'while') {
                int endIndex = CodeOperations.findCloseBracket(
                    input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);

                final innerCode = input.substring(m + 2, endIndex);
                final conditionalCode = input.substring(n + 1, m);
                int count = 0;
                while (process(conditionalCode,
                        consoleCallback: consoleCallback, onError: onError) ==
                    true) {
                  executeCode(innerCode, consoleCallback!, onError!);
                  count++;
                  if (count > 1000) {
                    onError.call('While loop goes infinite!!');
                    break;
                  }
                }
                variable = '';
                n = endIndex;
                continue;
              } else if (variable == 'if') {
                final List<ConditionalStatement> conditionalStatements = [];
                int endBracket = CodeOperations.findCloseBracket(
                    input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                conditionalStatements.add(ConditionalStatement(
                    argumentList[0], input.substring(m + 2, endBracket)));
                n = endBracket;
                while (input.length > endBracket + 7 &&
                    input.substring(endBracket + 1, endBracket + 5) == 'else') {
                  int startBracket = endBracket + 5;
                  if (input.substring(startBracket, endBracket + 7) == 'if') {
                    startBracket += 2;
                    int endRoundBracket = CodeOperations.findCloseBracket(input,
                        startBracket, '('.codeUnits.first, ')'.codeUnits.first);
                    endBracket = CodeOperations.findCloseBracket(
                        input,
                        endRoundBracket + 1,
                        '{'.codeUnits.first,
                        '}'.codeUnits.first);
                    conditionalStatements.add(ConditionalStatement(
                      input.substring(startBracket + 1, endRoundBracket),
                      input.substring(endRoundBracket + 2, endBracket),
                    ));
                  } else {
                    endBracket = CodeOperations.findCloseBracket(input,
                        startBracket, '{'.codeUnits.first, '}'.codeUnits.first);
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
                    executeCode(statement.body, consoleCallback!, onError!);
                  } else if (process(statement.condition!,
                          consoleCallback: consoleCallback, onError: onError) ==
                      true) {
                    executeCode(statement.body, consoleCallback!, onError!);
                    break;
                  }
                }
                variable = '';
                continue;
              } else if (variable == 'delayed') {
                int endIndex = CodeOperations.findCloseBracket(
                    input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                final int durationInMillis = process(input.substring(n + 1, m),
                    consoleCallback: consoleCallback, onError: onError);
                Future.delayed(Duration(milliseconds: durationInMillis), () {
                  executeCode(input.substring(m + 2, endIndex),
                      consoleCallback!, onError!);
                });
                n = endIndex;
                variable = '';
                continue;
              } else if (input.length > m + 1 && input[m + 1] == '{') {
                int closeBracketIndex = CodeOperations.findCloseBracket(
                    input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                if (closeBracketIndex < 0) {
                  error = true;
                  errorMessage = 'Invalid function syntax!!';
                  return;
                }
                final argumentList =
                    CodeOperations.splitBy(input.substring(n + 1, m));
                functions[variable] = FVBFunction(variable,
                    input.substring(m + 2, closeBracketIndex), argumentList);
                variable = '';
                n = closeBracketIndex;
                continue;
              } else if (functions.containsKey(variable)) {
                final argumentList =
                    CodeOperations.splitBy(input.substring(n + 1, m));
                final output = functions[variable]!.execute(
                    this,
                    argumentList
                        .map((e) => process(e,
                            consoleCallback: consoleCallback, onError: onError))
                        .toList(),
                    consoleCallback,
                    onError);
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
                final output = predefinedFunctions[variable]!.perform.call(
                    argumentList
                        .map((e) => process(e,
                            consoleCallback: consoleCallback, onError: onError))
                        .toList());
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
        }

        if (number.isNotEmpty) {
          parseNumber(number, valueStack);
          number = '';
        }

        if (isOperator(ch)) {
          String operator = input[n];
          if (n + 1 < input.length &&
              isOperator(input[n + 1].codeUnits.first)) {
            operator = operator + input[n + 1];
            n++;
          }
          if (operatorStack.isEmpty ||
              getPrecedence(operator) > getPrecedence(operatorStack.peek!)) {
            operatorStack.push(operator);
          } else {
            while (operatorStack.isNotEmpty &&
                getPrecedence(operator) <= getPrecedence(operatorStack.peek!)) {
              processOperator(operatorStack.pop()!, valueStack, operatorStack);
            }
            operatorStack.push(operator);
          }
        } else if (ch == '('.codeUnits[0]) {
          final index = CodeOperations.findCloseBracket(
              input, n, '('.codeUnits.first, ')'.codeUnits.first);
          if (index == -1) {
            return null;
          }
          final innerProcess = process<T>(input.substring(n + 1, index),
              resolve: true,
              consoleCallback: consoleCallback,
              onError: onError);
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
      final result = valueStack.pop()!.evaluateValue(this);
      if (operatorStack.isNotEmpty || valueStack.isNotEmpty) {
        logger('Expression error.');
      } else {
        return result;
      }
    }
    return null;
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

  void showError(String message, {bool throwError = true}) {
    error = true;
    errorMessage = message;
  }

  bool isString(String value) {
    if (value.length >= 2) {
      return value[0] == value[value.length - 1] &&
          (value[0] == '\'' || value[0] == '"');
    }
    return false;
  }

  bool resolveVariable(String variable, String object, valueStack) {
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
        valueStack
            .push(FVBValue(value: getValue(variable, fvbInstance: value)));
      }
      return true;
    }
    if (variable.startsWith('return')) {
      valueStack.push(FVBValue(
          value: process(
        variable.substring(6),
      )));
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
