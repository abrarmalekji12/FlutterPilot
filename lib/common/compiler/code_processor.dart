import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../bloc/error/error_bloc.dart';
import '../../bloc/state_management/state_management_bloc.dart';
import '../../code_to_component.dart';
import '../../component_list.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../cubit/stack_action/stack_action_cubit.dart';
import '../../injector.dart';
import '../../models/function_model.dart';
import '../../models/other_model.dart';
import '../../models/variable_model.dart';
import '../../ui/action_code_editor.dart';
import '../../ui/build_view/build_view.dart';
import '../common_methods.dart';
import '../converter/string_operation.dart';
import '../ide/suggestion_processor.dart';
import '../logger.dart';
import 'argument_processor.dart';
import 'constants.dart';
import 'datatype_processor.dart';
import 'function_processor.dart';
import 'fvb_classes.dart';
import 'fvb_converter.dart';

part 'fvb_behaviour.dart';
// enum DataType { fvbVoid,int, double, string, bool, dynamic, list,iterable, map, fvbInstance,fvbFunction, unknown}

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

final Map<String, CodeProcessor> processorMap = {};
const List<String> keywords = [
  'class ',
  'while',
  'if',
  'else',
  'else if',
  'for(',
  'switch(',
  'case:',
  'default:',
  'break;',
  'continue;',
  'return ',
];

class CodeProcessor {
  final CodeProcessor? parentProcessor;
  CacheMemory? cacheMemory;
  final String scopeName;
  final SuggestionConfig suggestionConfig = SuggestionConfig();
  final Map<String, dynamic> ignoreVariables = {'dw': 0, 'dh': 0};
  final Map<String, FVBVariable> variables = {};
  final Map<String, FVBVariable> _staticVariables = {};
  final Map<String, FVBFunction> _staticFunctions = {};
  static final Map<String, FunctionModel> predefinedFunctions = {};
  final Map<String, FunctionModel> predefinedSpecificFunctions = {};
  final Map<String, FVBFunction> functions = {};
  static final Map<String, FVBClass> classes = {};
  final Map<String, dynamic> localVariables = {};
  static OperationType operationType = OperationType.regular;
  final Scope scope;
  static bool error = false;
  bool finished = false;
  static final VariableModel _piVariable = VariableModel('pi', DataType.double,
      deletable: false, value: math.pi, description: 'it is mathematical value of pi', isFinal: true);

  static final arithmeticOperators = [
    '+',
    '-',
    '*',
    '/',
    '%',
    '>',
    '<',
    '>=',
    '<=',
    '%',
    '+=',
    '-=',
    '*=',
    '/=',
    '**',
    '&',
    '|',
    '^',
    '<<',
    '>>'
  ];
  static final baNullOperators = ['='];

  // static final abNullOperators=['==','!='];
  static final capitalACodeUnit = 'A'.codeUnits.first,
      capitalZCodeUnit = 'Z'.codeUnits.first,
      smallZCodeUnit = 'z'.codeUnits.first,
      underScoreCodeUnit = '_'.codeUnits.first,
      questionMarkCodeUnit = '?'.codeUnits.first,
      roundBracketClose = ')'.codeUnits.first,
      roundBracketOpen = '('.codeUnits.first,
      squareBracketClose = ']'.codeUnits.first,
      squareBracketOpen = '['.codeUnits.first,
      curlyBracketClose = '}'.codeUnits.first,
      curlyBracketOpen = '{'.codeUnits.first;
  static final zeroCodeUnit = '0'.codeUnits.first,
      nineCodeUnit = '9'.codeUnits.first,
      dotCodeUnit = '.'.codeUnits.first,
      colonCodeUnit = ':'.codeUnits.first;

  static final List<Timer> timers = [];
  final String? Function(String, {List<dynamic>? arguments}) consoleCallback;
  final void Function(String, String) onError;
  bool declarativeOnly = false;
  static final List<String> lastCodes = [];
  static int lastCodeCount = 0;
  void Function(CodeSuggestion?)? onSuggestions;

  factory CodeProcessor.build({CodeProcessor? processor, required String name}) {
    final codeProcessor = CodeProcessor(
      parentProcessor: processor,
      consoleCallback: processor?.consoleCallback ?? defaultConsoleCallback,
      onError: processor?.onError ?? defaultOnError,
      scopeName: name,
    );
    if (processor != null && processor.onSuggestions != null) {
      codeProcessor.onSuggestions = processor.onSuggestions;
    }
    if (!name.startsWith('fun:') && !processorMap.containsKey(name)) {
      processorMap[name] = codeProcessor;
    }
    return codeProcessor;
  }

  CodeProcessor(
      {this.scope = Scope.main,
      required this.scopeName,
      this.parentProcessor,
      required this.consoleCallback,
      required this.onError}) {
    error = false;
    if (scopeName == ComponentOperationCubit.currentProject?.name) {
      variables['pi'] = _piVariable;
    }

    predefinedSpecificFunctions['res'] = FunctionModel<dynamic>('res', (arguments) {
      if (variables['dw']!.value > variables['tabletWidthLimit']!.value) {
        return arguments[0];
      } else if (variables['dw']!.value > variables['phoneWidthLimit']!.value || arguments.length == 2) {
        return arguments[1];
      } else {
        return arguments[2];
      }
    }, functionCode: '''
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
    ''', description: 'return one of the argument according to the screen size');
    predefinedSpecificFunctions['print'] = FunctionModel<void>('print', (arguments) {
      if (arguments.isEmpty) {
        enableError('print function requires at least one argument');
        return;
      }
      consoleCallback.call('print:${arguments.map((e) => e.toString()).join('')}');
    }, description: 'print the given arguments');

    predefinedSpecificFunctions['showSnackbar'] = FunctionModel<void>('showSnackbar', (arguments) {
      if (arguments.length < 2) {
        enableError('showSnackbar requires 2 arguments!!');
        return;
      }
      consoleCallback.call('api:snackbar|${arguments[0]}|${arguments[1]}');
    }, description: 'show a snackbar');
    predefinedSpecificFunctions['newPage'] = FunctionModel<void>('newPage', (arguments) {
      if (arguments.isEmpty) {
        enableError('newPage requires 1 argument!!');
        return;
      }
      consoleCallback.call('api:newpage|${arguments[0]}');
    }, description: 'open a new page');
    predefinedSpecificFunctions['goBack'] = FunctionModel<void>('goBack', (arguments) {
      consoleCallback.call('api:goback|');
    }, description: 'go back to previous page');
    predefinedSpecificFunctions['lookUp'] = FunctionModel<dynamic>('lookUp', (arguments) {
      final id = arguments[0];
      FVBInstance? out;
      ComponentOperationCubit.currentProject?.currentScreen.rootComponent?.forEach((p0) {
        if (p0.id == id) {
          if (p0 is CTextField) {
            out = classes['TextField']?.createInstance(this, [])
              ?..variables['text']?.value = p0.textEditingController.text
              ..functions['setText']?.dartCall = (arguments) {
                p0.textEditingController.text = arguments[0];
              };
          }
        }
      });
      return out;
    }, description: 'look up a component by id');

    predefinedSpecificFunctions['refresh'] = FunctionModel<void>('refresh', (arguments) {
      consoleCallback.call('api:refresh|${arguments.isNotEmpty ? arguments[0] : ''}');
    }, description: 'refresh specific widget by ID');
    predefinedFunctions['get'] = FunctionModel<dynamic>('get', (arguments) {
      final url = arguments[0] as String;
      final futureOfGet = classes['Future']!.createInstance(this, []);
      http.get(Uri.parse(url)).then((value) {
        (futureOfGet.variables['onValue']?.value as FVBFunction?)?.execute(this, [value.body]);
      }).onError((error, stackTrace) {
        (futureOfGet.variables['onError']?.value as FVBFunction?)?.execute(this, [error!]);
      });
      return futureOfGet;
    }, description: 'get data from a url');
  }

  void enableSuggestion(void Function(CodeSuggestion?) suggestions) {
    onSuggestions = suggestions;
  }

  void disableSuggestion() {
    onSuggestions = null;
  }

  static init() {
    classes.addAll(FVBModuleClasses.fvbClasses);

    predefinedFunctions['ifElse'] = FunctionModel<dynamic>('ifElse', (arguments) {
      if (arguments.length >= 2) {
        if (arguments[0] == true) {
          return arguments[1];
        } else if (arguments.length == 3) {
          return arguments[2];
        }
      }
    }, functionCode: '''
    double? ifElse(bool expression,double ifTrue,[double? elseTrue]){
    if(expression){
      return ifTrue;
    }
    return elseTrue;
    }
    ''', description: 'inline if-else function (expression,ifTrue,elseTrue)');

    predefinedFunctions['randInt'] = FunctionModel<int>('randInt', (arguments) {
      if (arguments.length == 1) {
        return math.Random.secure().nextInt(arguments[0] ?? 100);
      }
      return 0;
    }, functionCode: '''
    int randInt(int? max){
    return math.Random.secure().nextInt(max??100);
    }
    ''', description: 'return a random integer between 0 and max');
    predefinedFunctions['jsonEncode'] = FunctionModel<String>('jsonEncode', (arguments) {
      if (arguments.length == 1) {
        return jsonEncode(arguments[0]);
      }
      return '';
    }, description: 'encode a json object');
    predefinedFunctions['jsonDecode'] = FunctionModel<dynamic>('jsonDecode', (arguments) {
      if (arguments.length == 1) {
        return jsonDecode(arguments[0]);
      }
      return '';
    }, description: 'decode a json object');

    predefinedFunctions['randDouble'] = FunctionModel<double>('randDouble', (arguments) {
      return math.Random.secure().nextDouble();
    }, functionCode: '''
    double randDouble(){
    return math.Random.secure().nextDouble();
    }
    ''', description: 'return a random double');
    predefinedFunctions['randBool'] = FunctionModel<bool>('randBool', (arguments) {
      return math.Random.secure().nextBool();
    }, functionCode: '''
    bool randBool(){
    return math.Random.secure().nextBool();
    }
    ''', description: 'return a random boolean');
    predefinedFunctions['randColor'] = FunctionModel<String>('randColor', (arguments) {
      return '#' + Colors.primaries[math.Random().nextInt(Colors.primaries.length)].value.toRadixString(16);
    }, functionCode: '''
    String randColor(){
    return '#'+Colors.primaries[math.Random().nextInt(Colors.primaries.length)].value.toRadixString(16);
    }
    ''', description: 'return a random color');
    predefinedFunctions['sin'] = FunctionModel<double>('sin', (arguments) {
      return math.sin(arguments[0]);
    }, description: 'return the sine of the given angle (radian)');
    predefinedFunctions['cos'] = FunctionModel<double>('cos', (arguments) {
      return math.cos(arguments[0]);
    }, description: 'return the cosine of the given angle (radian)');
  }

  static String? defaultConsoleCallback(String message, {List<dynamic>? arguments}) {
    doAPIOperation(message, stackActionCubit: get<StackActionCubit>(), stateManagementBloc: get<StateManagementBloc>());
    return null;
  }

  static void defaultOnError(error, line) {
    get<ErrorBloc>().add(ConsoleUpdatedEvent(ConsoleMessage(error, ConsoleMessageType.error)));
  }

  void addVariable(String name, VariableModel value) {
    variables[name] = value;
  }

  bool isValidOperator(String a) {
    return a == '-=' ||
        a == '--' ||
        a == '++' ||
        a == '+=' ||
        a == '*-' ||
        a == '~/' ||
        a == '/-' ||
        a == '*=' ||
        a == '/=' ||
        a == '%=' ||
        a == '==' ||
        a == '!=' ||
        a == '<=' ||
        a == '>=' ||
        a == '>-' ||
        a == '<-' ||
        a == '>=-' ||
        a == '<=-' ||
        a == '&&' ||
        a == '||' ||
        a == '??';
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
        ch == '?'.codeUnits[0] ||
        ch == '|'.codeUnits[0];
  }

  int getPrecedence(String ch) {
    if (ch == '=') {
      return 1;
    }
    if (ch == '&&' || ch == '||' || ch == '?' || ch == '??') {
      return 2;
    }
    if (ch == '<' ||
        ch == '>' ||
        ch == '<=' ||
        ch == '>=' ||
        ch == '<-' ||
        ch == '>-' ||
        ch == '<=-' ||
        ch == '>=-' ||
        ch == '==' ||
        ch == '!=') {
      return 3;
    }
    if (ch == '+' || ch == '-' || ch == '|' || ch == '&' || ch == '!') {
      return 4;
    }
    if (ch == '*' || ch == '/' || ch == '%' || ch == '~/') {
      return 5;
    }
    return 0;
  }

  void destroyProcess({CacheMemory? cacheMemory, required bool deep}) {
    finished = true;
    if (cacheMemory != null) {
      cacheMemory.restore(this);
    } else if (this.cacheMemory != null) {
      this.cacheMemory?.restore(this);
      this.cacheMemory = null;
    }
    variables.removeWhere((key, value) => (value is VariableModel) && !value.uiAttached && value.deletable);
    if (deep) {
      resetStaticParameters();
    }
    // if (memory == null) {
    //   final List<String> removeList = [];
    //   for (final entry in variables.entries) {
    //     if (entry.value.deletable && !entry.value.uiAttached) {
    //       removeList.add(entry.key);
    //     }
    //   }
    //   for (final entry in removeList) {
    //     variables.remove(entry);
    //   }
    // } else {
    //   memory.restore(this);
    // }
  }

  dynamic getValue(final String variable, {String object = ''}) {
    if (object.isNotEmpty) {
      final value = getValue(object);
      if (variable == 'runtimeType') {
        // valueStack.push(FVBValue(value: value.runtimeType.toString()));
        return value.runtimeType.toString();
      }
      if (value is FVBInstance) {
        return value.processor.getValue(variable);
      } else if (value is FVBClass) {
        return value.getValue(variable);
      } else if (classes.containsKey(value.runtimeType.toString())) {
        final instance = classes[value.runtimeType.toString()]!.fvbVariables[variable]!();
        if (instance.getCall == null) {
          throw Exception('No variable $variable in ${value.runtimeType.toString()}');
        }
        return instance.getCall!.call(value);
      }
      return null;
    }
    if (variable.contains('[')) {
      return getOrSetListMapBracketValue(variable);
    } else if (variable == 'true') {
      return true;
    } else if (variable == 'false') {
      return false;
    }
    // else if (fvbClass != null) {
    //   if (fvbClass.fvbStaticVariables?.containsKey(variable) ?? false) {
    //     return fvbClass.fvbStaticVariables![variable]!.value;
    //   } else if (fvbClass.fvbFunctions.containsKey(variable)) {
    //     return fvbClass.fvbFunctions[variable]!;
    //   } else if (fvbClass.fvbStaticFunctions?.containsKey(variable) ?? false) {
    //     return fvbClass.fvbStaticFunctions![variable]!;
    //   }
    // }
    else if (classes.containsKey(variable)) {
      return classes[variable];
    }
    CodeProcessor? pointer = this;
    while (pointer != null) {
      if (pointer.variables.containsKey(variable)) {
        if (!pointer.variables[variable]!.nullable && pointer.variables[variable]!.value == null) {
          throw Exception('variable $variable is not initialized');
        }
        return pointer.variables[variable]!.value;
      } else if (pointer.localVariables.containsKey(variable)) {
        return pointer.localVariables[variable];
      } else if (pointer.functions.containsKey(variable)) {
        return pointer.functions[variable];
      }
      pointer = pointer.parentProcessor;
    }
    if (operationType == OperationType.checkOnly && ignoreVariables.containsKey(variable)) {
      return ignoreVariables[variable];
    }
    // else if (operationType == OperationType.checkOnly) {
    //   showError('Variable $variable not found!!');
    //   return null;
    // }
    throw Exception('variable $variable does not exist!!');
  }

  DataType getVarType(final String variable, {String object = ''}) {
    if (object.isNotEmpty) {
      final value = getValue(object);
      if (variable == 'runtimeType') {
        // valueStack.push(FVBValue(value: value.runtimeType.toString()));
        return DataType.string;
      }
      if (value is FVBInstance) {
        return DataType.fvbInstance(value.fvbClass.name);
      } else if (value is FVBClass) {
        return DataType.fvbInstance(value.name);
      } else {
        return DataType.unknown;
      }
    }
    if (variable.contains('[')) {
      return getOrSetListMapBracketValue(variable);
    } else if (variable == 'true') {
      return DataType.bool;
    } else if (variable == 'false') {
      return DataType.bool;
    }
    // else if (fvbClass != null) {
    //   if (fvbClass.fvbStaticVariables?.containsKey(variable) ?? false) {
    //     return fvbClass.fvbStaticVariables![variable]!.value;
    //   } else if (fvbClass.fvbFunctions.containsKey(variable)) {
    //     return fvbClass.fvbFunctions[variable]!;
    //   } else if (fvbClass.fvbStaticFunctions?.containsKey(variable) ?? false) {
    //     return fvbClass.fvbStaticFunctions![variable]!;
    //   }
    // }
    else if (classes.containsKey(variable)) {
      return DataType.fvbInstance(classes[variable]!.name);
    }
    CodeProcessor? pointer = this;
    while (pointer != null) {
      if (pointer.variables.containsKey(variable)) {
        return pointer.variables[variable]!.dataType;
      } else if (pointer.localVariables.containsKey(variable)) {
        return DataType.dynamic;
      } else if (pointer.functions.containsKey(variable)) {
        return DataType.fvbFunction;
      }
      pointer = pointer.parentProcessor;
    }
    if (operationType == OperationType.checkOnly && ignoreVariables.containsKey(variable)) {
      return ignoreVariables[variable];
    }
    // else if (operationType == OperationType.checkOnly) {
    //   showError('Variable $variable not found!!');
    //   return null;
    // }
    throw Exception('variable $variable does not exist!!');
  }

  bool setValue(final String variable, dynamic value,
      {bool isFinal = false,
      bool isStatic = false,
      bool createNew = false,
      String object = '',
      DataType? dataType,
      bool nullable = false}) {
    if (declarativeOnly && !createNew) {
      throw Exception('Cannot set variable $variable in declarative mode');
    }
    if (createNew) {
      if (isStatic && scopeName == ComponentOperationCubit.currentProject!.name) {
        throw Exception('Cannot create a static variable global scope');
      }

      DataType type;
      if (dataType == null) {
        type = DataTypeProcessor.getDartTypeToDatatype(value);
      } else if (DataTypeProcessor.checkIfValidDataTypeOfValue(value, dataType, variable, nullable)) {
        type = dataType;
      } else {
        return false;
      }
      if (variables.containsKey(variable)) {
        throw Exception('Variable $variable already exists');
      }
      final variableModel = VariableModel(variable, type,
          nullable: nullable,
          value: value,

          // type: dataType == DataType.fvbInstance
          //     ? (value as FVBInstance).fvbClass.name
          //     : null,
          isFinal: isFinal);
      if (isStatic) {
        _staticVariables[variable] = variableModel;
      } else {
        variables[variable] = variableModel;
      }
      return true;
    }
    if (object.isNotEmpty) {
      final objectValue = getValue(object);
      if (objectValue is FVBInstance) {
        objectValue.processor.setValue(variable, value);
      } else if (objectValue is FVBClass) {
        objectValue.setValue(variable, value);
      }
      return true;
    }
    if (variable.contains('[')) {
      getOrSetListMapBracketValue(variable, value: value);
      return true;
    }

    if (variables.containsKey(variable)) {
      if (variables[variable]!.isFinal) {
        throw Exception('Cannot change value of final variable $variable');
      } else if (DataTypeProcessor.checkIfValidDataTypeOfValue(
          value, variables[variable]!.dataType, variable, variables[variable]!.nullable)) {
        variables[variable]!.value = value;
      }
      return true;
    } else if (localVariables.containsKey(variable)) {
      localVariables[variable] = value;
      return true;
    }
    CodeProcessor? parent = parentProcessor;
    while (parent != null) {
      if (parent.variables.containsKey(variable)) {
        if (parent.variables[variable]!.isFinal) {
          throw Exception('Cannot change value of final variable $variable');
        } else if (DataTypeProcessor.checkIfValidDataTypeOfValue(
          value,
          parent.variables[variable]!.dataType,
          variable,
          parent.variables[variable]!.nullable,
        )) {
          parent.variables[variable]!.value = value;
          return true;
        }
      } else if (parent.localVariables.containsKey(variable)) {
        parent.localVariables[variable] = value;
        return true;
      }
      parent = parent.parentProcessor;
    }
    throw Exception('Variable $variable not found');
  }

  getOrSetListMapBracketValue(String variable, {dynamic value}) {
    int openBracket = variable.indexOf('[');
    if (openBracket != -1) {
      final closeBracket =
          CodeOperations.findCloseBracket(variable, openBracket, '['.codeUnits.first, ']'.codeUnits.first);
      final key = process(variable.substring(openBracket + 1, closeBracket));
      final subVar = variable.substring(0, openBracket);
      openBracket = variable.indexOf('[', closeBracket);
      dynamic mapValue = getValue(subVar);
      if (value != null && openBracket == -1) {
        mapValue[key] = value;
        return true;
      } else {
        if ((mapValue is Map && mapValue.containsKey(key)) ||
            ((mapValue is List || mapValue is String) && key is int && key < mapValue.length)) {
          mapValue = mapValue[key];
        } else {
          // showError('can not use [ ] with $mapValue');
          return FVBUndefined('$variable not have "$key"');
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
              ((mapValue is List || mapValue is String) && key is int && key < mapValue.length)) {
            mapValue = mapValue[key];
          } else {
            return FVBUndefined('$variable not have "$key"');
          }
        }
      }
      return mapValue;
    }
  }

  void processOperator(final String operator, final String object, final Stack2<FVBValue> valueStack,
      final Stack2<String> operatorStack) {
    print('PROCCESSING OPERATOR $operator | $valueStack = $operatorStack');
    dynamic a, b;
    late FVBValue aVar, bVar;
    if (valueStack.isEmpty) {
      throw Exception('ValueStack is Empty, syntax error !!');
    } else {
      bVar = valueStack.pop()!;
      b = bVar.evaluateValue(this, ignoreIfNotExist: bVar.createVar);
    }

    if (valueStack.isEmpty && operator != '-' && operator != '--' && operator != '++' && operator != '!') {
      throw Exception('Not enough values for operation "$operator", syntax error !!');
    } else if ((operator != '-' || valueStack.length > operatorStack.length) && valueStack.isNotEmpty) {
      aVar = valueStack.pop()!;
      if (operator != '=') {
        a = aVar.evaluateValue(this, ignoreIfNotExist: bVar.createVar);
      } else {
        a = null;
      }
      // else if(a!=null&&b!=null&&(a is! int&& a is! double) || (b is! int&& b is! double) ){
      //   if(arithmeticOperators.contains(operator)){
      //     showError('can not use $operator with ${aVar.variableName ?? aVar.value} and ${bVar.variableName ?? bVar.value}');
      //     return;
      //   }
      // }
    }

    late dynamic r;
    try {
      switch (operator) {
        case '??':
          r = a ?? b;
          break;
        case '--':
        case '+':
          if (operator == '--' && a == null) {
            setValue(bVar.variableName!, getValue(bVar.variableName!) - 1);
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
        case '/-':
          r = a / -b;
          break;
        case '%':
          if (a is int && b is int) {
            r = a % b;
          } else {
            throw Exception('Can not do $a % $b, both are not type of int');
          }
          break;
        case '<':
          r = a < b;
          break;
        case '>':
          r = a > b;
          break;
        case '>-':
          r = a > -b;
          break;
        case '<-':
          r = a < -b;
          break;
        case '<=-':
          r = a <= -b;
          break;
        case '>=-':
          r = a >= -b;
          break;
        case '==-':
          r = a == -b;
          break;
        case '!=-':
          r = a != -b;
          break;
        case '!':
          r = !b;
          break;
        case '=':
          setValue(aVar.variableName!, b,
              isFinal: aVar.isVarFinal,
              createNew: aVar.createVar,
              dataType: aVar.dataType,
              isStatic: aVar.static,
              nullable: aVar.nullable,
              object: object);
          r = b;
          break;
        case '++':
          final name = bVar.variableName!;
          final value = getValue(name);

          if (value != null) {
            setValue(name, value! + 1);
            r = value! + 1;
          } else {
            throw Exception('Variable $name is not defined');
          }

          break;
        case '+=':
          final name = aVar.variableName!;
          final value = getValue(name);
          if (value != null) {
            setValue(name, value! + b);
            r = value! + b;
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '-=':
          final name = aVar.variableName!;
          final value = getValue(name);
          if (value != null) {
            setValue(name, value! - b);
            r = value! + b;
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '*=':
          final name = aVar.variableName!;
          final value = getValue(name);

          if (value != null) {
            setValue(name, value! * b);
            r = value! * b;
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '/=':
          final name = aVar.variableName!;
          final value = getValue(name);
          if (value != null) {
            setValue(name, value! / b);
            r = value! / b;
          } else {
            throw Exception('Variable $name is not defined');
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
        case '&':
          r = a & b;
          break;
        case '|':
          r = a | b;
          break;
        case '^':
          r = a ^ b;
          break;
        default:
          throw Exception('Unknown operator $operator');
      }
    } catch (e) {
      enableError(e.toString());
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
      enableError('Invalid syntax in string');
      return null;
    }
    while (startList.isNotEmpty) {
      si = startList.removeAt(0);
      ei = endList.removeAt(0);
      if (si + 2 == ei) {
        enableError('No expression between {{ and }} !!');
        return null;
        // return CodeOutput.right('No variables');
      }
      if (ei > code.length) {
        enableError('Not enough characters in string');
        return null;
      }
      final variableName = code.substring(si + 2, ei);
      final value = process(
        variableName,
        resolve: true,
      );
      if (value is FVBUndefined) {
        enableError('undefined ${value.varName}');
        return null;
      }
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

  void resetStaticParameters() {
    while (timers.isNotEmpty) {
      timers.removeLast().cancel();
    }
    for (final processor in processorMap.values) {
      processor.destroyProcess(deep: false);
    }
  }

  bool get isSuggestionEnable {
    return operationType == OperationType.checkOnly && onSuggestions != null;
  }

  dynamic executeCode<T>(final String input,
      {OperationType type = OperationType.regular, bool declarativeOnly = true, List<String>? arguments}) async {
    error = false;
    operationType = type;
    finished = false;
    if (isSuggestionEnable) {
      lastCodeCount = 0;
      onSuggestions!.call(null);
    }

    cacheMemory = CacheMemory(this);
    final code = cleanCode(input, this);
    if (code == null) {
      return null;
    }
    final output = execute<T>(code, declarativeOnly: declarativeOnly);
    // if(functions.containsKey(scopeName)){
    //   if(arguments==null){
    //     enableError('Invalid arguments for constructor $scopeName ');
    //     return null;
    //   }
    //   functions[scopeName]!.execute(this, ArgumentProcessor.process(this, arguments, functions[scopeName]!.arguments));
    // }
    return output;
  }

  static String? cleanCode(String input, CodeProcessor processor) {
    String trimCode = '';
    bool commentOpen = false;
    for (final line in input.split('\n')) {
      int index = -1;
      bool openString = false;
      for (int i = 0; i < line.length; i++) {
        if (line[i] == '"') {
          openString = !openString;
        } else if (!openString && i + 1 < line.length) {
          if (line[i] == '/') {
            if (line[i + 1] == '/') {
              index = i;
              break;
            } else if (line[i + 1] == '*') {
              commentOpen = true;
              break;
            }
          } else if (line[i] == '*' && line[i + 1] == '/') {
            commentOpen = false;
            trimCode += line.substring(i + 2);
            index = 0;
            break;
          }
        }
      }
      if (commentOpen) {
        continue;
      }
      if (index != -1) {
        trimCode += line.substring(0, index);
      } else {
        trimCode += line;
      }
    }
    final singleSpaceCode = CodeOperations.trimAvoidSingleSpace(trimCode)!;
    final checkForError = CodeOperations.checkSyntaxInCode(trimCode);
    if (checkForError != null) {
      processor.enableError(checkForError);
      return null;
    }
    return CodeOperations.trim(singleSpaceCode)!;
  }

  dynamic executeAsync<T>(final String trimCode, {bool declarativeOnly = false}) async {
    final oldDeclarativeMode = this.declarativeOnly;
    this.declarativeOnly = declarativeOnly;
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
        final endIndex = trimCode[i] == ';' ? i : i + 1;
        final code = trimCode.substring(lastPoint, endIndex);
        dynamic output = process<T>(
          code,
        );
        if (output is FVBFuture) {
          final asyncOutput = process(output.asynCode);
          if (operationType == OperationType.regular) {
            if (asyncOutput is FVBInstance && asyncOutput.fvbClass.name == 'Future') {
              final future = await (asyncOutput.variables['future']!.value as Future);
              output.values.push(FVBValue(value: future));
            }
          } else {
            output.values.push(FVBValue(value: FVBTest(DataType.dynamic, false)));
          }
          process('', oldValueStack: output.values, oldOperatorStack: output.operators);
        }

        lastPoint = i + 1;
        if (error) {
          break;
        }
        globalOutput = output;

        if (output is FVBContinue || output is FVBBreak || output is FVBReturn) {
          this.declarativeOnly = oldDeclarativeMode;
          return globalOutput;
        }
        if (finished) {
          break;
        }
      }
    }

    this.declarativeOnly = oldDeclarativeMode;
    return globalOutput;
  }

  dynamic execute<T>(final String trimCode, {bool declarativeOnly = false}) {
    final oldDeclarativeMode = this.declarativeOnly;
    this.declarativeOnly = declarativeOnly;
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
        final endIndex = trimCode[i] == ';' ? i : i + 1;
        final code = trimCode.substring(lastPoint, endIndex);
        final output = process<T>(
          code,
        );
        if (output is FVBFuture) {
          enableError('can not use await in sync code "${output.asynCode}"');
        }
        lastPoint = i + 1;
        if (error) {
          break;
        }
        globalOutput = output;

        if (output is FVBContinue || output is FVBBreak || output is FVBReturn) {
          this.declarativeOnly = oldDeclarativeMode;
          return globalOutput;
        }
        if (finished) {
          break;
        }
      }
    }

    this.declarativeOnly = oldDeclarativeMode;
    return globalOutput;
  }

  dynamic process<T>(final String input,
      {bool resolve = false, Stack2<FVBValue>? oldValueStack, Stack2<String>? oldOperatorStack}) {
    int editIndex = -1;
    if (isSuggestionEnable) {
      if (lastCodeCount >= lastCodes.length) {
        lastCodes.add(input);
      } else if (lastCodes[lastCodeCount] != input) {
        if (input.length == 1) {
          editIndex = 0;
        } else {
          final lastCode = lastCodes[lastCodeCount];
          if ((lastCode.length - input.length).abs() < 5) {
            if (input != lastCode) {
              for (int i = 0; i < input.length && i < lastCode.length; i++) {
                if (input[i] != lastCode[i]) {
                  editIndex = i;
                  break;
                }
              }
              if (editIndex == -1) {
                editIndex = (input.length > lastCode.length) ? input.length - 1 : lastCode.length - 1;
              }
            }
          } else {
            onSuggestions?.call(null);
          }
        }
        lastCodes[lastCodeCount] = input;
      }
      lastCodeCount++;
    }
    try {
      if (T == String || T == ImageData) {
        return processString(input);
      } else if (T == Color && input.startsWith('#')) {
        return input;
      }
      final Stack2<FVBValue> valueStack = oldValueStack ?? Stack2<FVBValue>();
      final Stack2<String> operatorStack = oldOperatorStack ?? Stack2<String>();
      bool stringOpen = false;
      int stringCount = 0;
      String variable = '';
      String object = '';
      bool isNumber = true;
      for (int currentIndex = 0; currentIndex < input.length; currentIndex++) {
        if (error) {
          return null;
        }
        final String nextToken = input[currentIndex];
        final ch = nextToken.codeUnits.first;
        if (stringOpen) {
          if (stringCount == 0 && (ch == '"'.codeUnits.first || ch == '\''.codeUnits.first)) {
            stringOpen = !stringOpen;
            if (currentIndex - variable.length - 1 >= 0 &&
                (input[currentIndex - variable.length - 1] == '"' ||
                    input[currentIndex - variable.length - 1] == '\'')) {
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
        } else if (ch == '"'.codeUnits.first || ch == '\''.codeUnits.first) {
          isNumber = false;
          stringOpen = true;
        } else if (ch == '['.codeUnits.first) {
          int count = 0;

          for (int i = currentIndex + 1; i < input.length; i++) {
            if (input[i] == ']' && count == 0) {
              final substring = input.substring(currentIndex + 1, i);
              if (!substring.contains(',') && (valueStack.peek?.value is List || valueStack.peek?.value is Map)) {
                valueStack.push(FVBValue(value: valueStack.pop()!.value[process(substring)]));
                currentIndex = i;
                break;
              } else if (variable.isNotEmpty) {
                variable = variable + '[$substring]';
                currentIndex = i;
                break;
              } else {
                valueStack.push(FVBValue(value: CodeOperations.splitBy(substring).map((e) => process(e)).toList()));
                variable = '';
                currentIndex = i;
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
          if (variable.isNotEmpty && variable.startsWith('class$space')) {
            final className = variable.substring(6);
            final closeCurlyBracket =
                CodeOperations.findCloseBracket(input, currentIndex, '{'.codeUnits.first, '}'.codeUnits.first);
            final CodeProcessor processor = CodeProcessor(
                scope: Scope.object, consoleCallback: consoleCallback, onError: onError, scopeName: className);
            processor.execute(input.substring(currentIndex + 1, closeCurlyBracket), declarativeOnly: true);
            classes[className] = FVBClass(
              className,
              processor.functions,
              Map.fromEntries(
                  processor.variables.entries.map((entry) => MapEntry(entry.key, () => entry.value.clone()))),
              parent: this,
              fvbStaticVariables: processor._staticVariables,
              fvbStaticFunctions: processor._staticFunctions,
            );

            currentIndex = closeCurlyBracket;
            variable = '';
            continue;
          } else {
            int count = 0;
            for (int i = currentIndex + 1; i < input.length; i++) {
              if (input[i] == '}' && count == 0) {
                valueStack.push(
                  FVBValue(
                      value: Map.from(
                    CodeOperations.splitBy(input.substring(currentIndex + 1, i)).asMap().map((e, n) {
                      final split = CodeOperations.splitBy(n, splitBy: ':');
                      return MapEntry(process(split[0]), process(split[1]));
                    }),
                  )),
                );
                variable = '';
                currentIndex = i + 1;
                break;
              } else if (input[i] == '{') {
                count++;
              } else if (input[i] == '}') {
                count--;
              }
            }
          }
        } else if ((ch >= capitalACodeUnit && ch <= smallZCodeUnit) ||
            (ch >= zeroCodeUnit && ch <= nineCodeUnit) ||
            ch == underScoreCodeUnit ||
            ch == squareBracketOpen ||
            ch == squareBracketClose ||
            ch == questionMarkCodeUnit ||
            ch == spaceCodeUnit) {
          if (ch == questionMarkCodeUnit) {
            if (currentIndex + 1 < input.length && input[currentIndex + 1] == '?') {
              finishProcessing(variable, '??', object, operatorStack, valueStack);
              operatorStack.push('??');
              variable = '';
              object = '';
              currentIndex++;
              continue;
            }
            final colonIndex = CodeOperations.findChar(input, currentIndex, colonCodeUnit, [spaceCodeUnit]);

            if (colonIndex != -1) {
              int index = CodeOperations.findChar(input, colonIndex + 1, ','.codeUnits.first, [spaceCodeUnit]);
              if (index == -1) {
                index = input.length;
              }
              finishProcessing(variable, '?', object, operatorStack, valueStack);
              // operatorStack.push('?');
              if (valueStack.pop()?.value == true) {
                valueStack.push(FVBValue(value: process(input.substring(currentIndex + 1, colonIndex))));
              } else {
                valueStack.push(FVBValue(
                  value: process(
                    input.substring(colonIndex + 1, index),
                  ),
                ));
              }
              currentIndex = index;
              variable = '';
              object = '';
              continue;
            }
          }
          if ((ch >= zeroCodeUnit && ch <= nineCodeUnit)) {
            isNumber = true;
          } else {
            isNumber = false;
          }
          if (ch == spaceCodeUnit) {
            if (variable == 'await') {
              return FVBFuture(valueStack, operatorStack, input.substring(currentIndex + 1));
            }
          }
          variable += nextToken;
          if (editIndex == currentIndex && isSuggestionEnable) {
            _handleVariableAndFunctionSuggestions(variable, object, valueStack);
          }
        } else if (ch == dotCodeUnit) {
          if (isNumber) {
            variable += nextToken;
            continue;
          }
          if (object.isNotEmpty && variable.isNotEmpty) {
            final obj = getValue(object);
            object = 'instance';
            if (obj is FVBInstance) {
              localVariables[object] = obj.processor.getValue(variable);
            } else if (obj is FVBClass) {
              localVariables[object] = obj.getValue(variable);
            }
            variable = '';
            if (editIndex == currentIndex && onSuggestions != null) {
              print('HANDLING 2 FOR ${input[editIndex]}');
              _handleVariableAndFunctionSuggestions(variable, object, valueStack);
            }
            continue;
          } else if (variable.isNotEmpty) {
            object = variable;
            variable = '';
            if (editIndex == currentIndex && onSuggestions != null) {
              _handleVariableAndFunctionSuggestions(variable, object, valueStack);
            }
            continue;
          } else if (valueStack.isNotEmpty) {
            variable = 'instance';
            localVariables[variable] = valueStack.pop()?.value!;
            object = variable;
            variable = '';
            if (editIndex == currentIndex && onSuggestions != null) {
              _handleVariableAndFunctionSuggestions(variable, object, valueStack);
            }
            continue;
          }
        } else {
          /// Functions corner
          /// Condition 1 :: Variable is Not Empty
          if (variable.isNotEmpty && ch == '('.codeUnits[0]) {
            final int closeRoundBracket =
                CodeOperations.findCloseBracket(input, currentIndex, '('.codeUnits.first, ')'.codeUnits.first);

            if (variable == 'for') {
              if (declarativeOnly) {
                enableError('for is not allowed in declarative mode');
                return;
              }
              int endIndex = CodeOperations.findCloseBracket(
                  input, closeRoundBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);
              final insideFor = input.substring(currentIndex + 1, closeRoundBracket);
              final innerCode = input.substring(closeRoundBracket + 2, endIndex);
              final splits = CodeOperations.splitBy(insideFor, splitBy: ';');
              if (splits.length != 3) {
                if (insideFor.contains(':')) {
                  final split = CodeOperations.splitBy(insideFor, splitBy: ':');
                  final list = process(split[1]);
                  if (list is! Iterable) {
                    enableError('Invalid for each loop');
                  } else {
                    if (operationType == OperationType.regular) {
                      for (final item in list) {
                        localVariables[split[0]] = item;
                        final output = execute(innerCode);
                        if (output is FVBBreak || error || finished) {
                          break;
                        }
                      }
                    } else if (operationType == OperationType.checkOnly) {
                      execute(innerCode);
                    }
                  }
                } else {
                  enableError('For loop syntax error');
                }
              } else {
                process(splits[0]);
                int count = 0;
                while (process(splits[1]) == true) {
                  final output = execute(innerCode);
                  if (output is FVBBreak || error || finished) {
                    break;
                  }
                  process(splits[2]);
                  if (operationType == OperationType.checkOnly) {
                    break;
                  }
                  count++;
                  if (count > 1000) {
                    enableError('For loop goes infinite!!');
                    break;
                  }
                }
              }
              variable = '';
              currentIndex = endIndex;
              continue;
            }
            final argumentList = CodeOperations.splitBy(input.substring(currentIndex + 1, closeRoundBracket));

            /// Constructor Corner
            /// Named and Normal Contractors
            if (declarativeOnly && (object == scopeName || scopeName == variable)) {
              if (object == scopeName) {
                variable = '$object.$variable';
              }
              final String body;
              final openRoundBracket = currentIndex;
              if (closeRoundBracket + 1 < input.length && input[closeRoundBracket + 1] == '{') {
                final closeCurlyBracket = CodeOperations.findCloseBracket(
                    input, closeRoundBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                body = input.substring(closeRoundBracket + 2, closeCurlyBracket);
                currentIndex = closeCurlyBracket;
              } else {
                body = '';
                currentIndex = closeRoundBracket;
              }
              final argumentList = CodeOperations.splitBy(input.substring(openRoundBracket + 1, closeRoundBracket));
              functions[variable] =
                  FVBFunction(variable, body, processArgDefinitionList(argumentList, variables: variables));
              variable = '';
              object = '';
              continue;
            }

            /// Named Constructor
            else if (classes.containsKey(object) && classes[object]!.fvbFunctions.containsKey('$object.$variable')) {
              final fvbClass = classes[object]!;
              final constructorName = '$object.$variable';
              valueStack.push(
                FVBValue(
                  value: fvbClass.createInstance(
                      this, processArgList(argumentList, fvbClass.fvbFunctions[constructorName]!.arguments),
                      constructorName: '$object.$variable'),
                ),
              );
              variable = '';
              object = '';
              currentIndex = closeRoundBracket;
              continue;
            } else if (classes.containsKey(variable)) {
              final fvbClass = classes[variable]!;
              valueStack.push(FVBValue(
                value: fvbClass.createInstance(
                  this,
                  fvbClass.fvbFunctions.containsKey(variable)
                      ? processArgList(argumentList, fvbClass.fvbFunctions[variable]!.arguments)
                      : [],
                ),
              ));
              variable = '';
              currentIndex = closeRoundBracket;
              continue;
            } else if (!declarativeOnly &&
                (processorMap.containsKey(variable) ||
                    (processorMap.containsKey(object) &&
                        processorMap[object]!.functions.containsKey('$object.$variable'))) &&
                (input[closeRoundBracket + 1] != '{')) {
              final FVBFunction? function;
              if (processorMap.containsKey(object)) {
                function = processorMap[object]!.functions['$object.$variable']!;
                function.execute(processorMap[object]!, processArgList(argumentList, function.arguments));
              } else {
                final processor = processorMap[variable];
                function = processor!.functions[variable];
                if (function != null) {
                  function.execute(processor, processArgList(argumentList, function.arguments));
                } else {
                  throw Exception('No constructor $variable found in class $variable');
                }
              }
            } else if (object.isNotEmpty) {
              /// Object dot function is called.
              var objectInstance = getValue(object);
              if (objectInstance is FVBTest) {
                objectInstance = objectInstance.testValue(this);
              }
              if (objectInstance is FVBInstance || objectInstance is FVBClass) {
                final fvbArguments = objectInstance is FVBInstance
                    ? objectInstance.getFunction(this, variable)?.arguments
                    : (objectInstance as FVBClass).getFunction(this, variable)?.arguments;
                if (fvbArguments == null) {
                  throw Exception('Function "$variable" not found in class $object');
                }

                final processedArgs = processArgList(argumentList, fvbArguments);
                final dynamic output;
                if (objectInstance is FVBInstance) {
                  output = objectInstance.executeFunction(variable, processedArgs);
                } else {
                  output = (objectInstance as FVBClass).executeFunction(this, variable, processedArgs);
                }
                valueStack.push(FVBValue(value: output));
              } else {
                _handleObjectMethods(objectInstance, variable, argumentList, valueStack);
              }
              variable = '';
              object = '';
              currentIndex = closeRoundBracket;
              continue;
            } else if (variable == 'while') {
              if (declarativeOnly) {
                enableError('While statement is not allowed in declarative mode');
                return;
              }
              int endIndex = CodeOperations.findCloseBracket(
                  input, closeRoundBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);

              final innerCode = input.substring(closeRoundBracket + 2, endIndex);
              final conditionalCode = input.substring(currentIndex + 1, closeRoundBracket);
              int count = 0;
              while (process(conditionalCode) == true) {
                final output = execute(innerCode);
                if (output is FVBBreak || error || finished) {
                  break;
                }
                count++;
                if (count > 10000) {
                  enableError('While loop goes infinite!!');
                  break;
                }
              }
              variable = '';
              currentIndex = endIndex;
              continue;
            } else if (variable == 'if') {
              if (declarativeOnly) {
                enableError('If statement is not allowed in declarative mode');
                return;
              }
              final List<ConditionalStatement> conditionalStatements = [];
              int endBracket = CodeOperations.findCloseBracket(
                  input, closeRoundBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);
              conditionalStatements
                  .add(ConditionalStatement(argumentList[0], input.substring(closeRoundBracket + 2, endBracket)));
              currentIndex = endBracket;
              while (input.length > endBracket + 7 && input.substring(endBracket + 1, endBracket + 5) == 'else') {
                int startBracket = endBracket + 6;
                if (input.substring(startBracket, endBracket + 8) == 'if') {
                  startBracket += 2;
                  int endRoundBracket =
                      CodeOperations.findCloseBracket(input, startBracket, '('.codeUnits.first, ')'.codeUnits.first);
                  endBracket = CodeOperations.findCloseBracket(
                      input, endRoundBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                  conditionalStatements.add(ConditionalStatement(
                    input.substring(startBracket + 1, endRoundBracket),
                    input.substring(endRoundBracket + 2, endBracket),
                  ));
                  currentIndex = endBracket;
                } else {
                  startBracket = endBracket + 5;
                  endBracket =
                      CodeOperations.findCloseBracket(input, startBracket, '{'.codeUnits.first, '}'.codeUnits.first);
                  conditionalStatements.add(
                    ConditionalStatement(
                      null,
                      input.substring(startBracket + 1, endBracket),
                    ),
                  );
                  currentIndex = endBracket;
                  break;
                }
              }
              for (final statement in conditionalStatements) {
                if (operationType == OperationType.checkOnly) {
                  if (statement.condition != null) {
                    execute(statement.condition!);
                  }
                  execute(statement.body);
                  continue;
                }
                if (statement.condition == null) {
                  final output = execute(statement.body);
                  if (output != null) {
                    valueStack.push(FVBValue(value: output));
                  }
                  break;
                } else if (process(statement.condition!) == true) {
                  final output = execute(statement.body);
                  if (output != null) {
                    valueStack.push(FVBValue(value: output));
                  }
                  break;
                }
              }
              variable = '';
              continue;
            } else if (variable == 'switch') {
              if (declarativeOnly) {
                enableError('Switch statement is not allowed in declarative mode');
                return;
              }
              final value = process(argumentList[0]);
              int endBracket = CodeOperations.findCloseBracket(
                  input, closeRoundBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);
              int index = 0;
              final List<CaseStatement> list = [];
              final String innerCode = input.substring(closeRoundBracket + 2, endBracket);
              int caseIndex = -1;
              while (index < endBracket) {
                index = innerCode.indexOf('case', index);
                if (index != -1) {
                  if (caseIndex != -1) {
                    final split = CodeOperations.splitBy(innerCode.substring(caseIndex, index), splitBy: ':');
                    list.add(CaseStatement(split[0], split[1]));
                  }
                  caseIndex = index + 5;
                  index += 5;
                } else {
                  break;
                }
              }
              final defaultIndex = innerCode.indexOf('default', caseIndex);
              if (caseIndex != -1) {
                final split = CodeOperations.splitBy(
                    innerCode.substring(caseIndex, defaultIndex != -1 ? defaultIndex : innerCode.length),
                    splitBy: ':');
                list.add(CaseStatement(split[0], split[1]));
              }
              if (defaultIndex != -1) {
                list.add(
                  CaseStatement(
                    null,
                    innerCode.substring(defaultIndex + 8),
                  ),
                );
              }

              bool isTrue = false;
              for (final statement in list) {
                if (statement.condition == null) {
                  execute(statement.body);
                  break;
                } else if (process(statement.condition!) == value || isTrue) {
                  final value = execute(statement.body);
                  isTrue = true;
                  if (value is FVBBreak) {
                    break;
                  }
                }
              }
              currentIndex = endBracket;
              continue;
            } else if (input.length > closeRoundBracket + 1 &&
                (input[closeRoundBracket + 1] == '{' || input[closeRoundBracket + 6] == '{')) {
              final isAsync = input.length > closeRoundBracket + 6
                  ? input.substring(closeRoundBracket + 1, closeRoundBracket + 6) == 'async'
                  : false;
              final int closeBracketIndex = CodeOperations.findCloseBracket(input,
                  isAsync ? closeRoundBracket + 6 : closeRoundBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);
              // final argumentList = CodeOperations.splitBy(input.substring(currentIndex + 1, m));
              // functions[variable] = FVBFunction(
              //     variable, input.substring(m + 2, closeBracketIndex), processArgDefinitionList(argumentList));

              bool static = false;
              if (variable.startsWith('static$space')) {
                static = true;
                variable = variable.substring(7);
              }
              final function = FunctionProcessor.parse(
                  this,
                  variable,
                  input.substring(currentIndex + 1, closeRoundBracket),
                  isAsync
                      ? input.substring(closeRoundBracket + 7, closeBracketIndex)
                      : input.substring(closeRoundBracket + 2, closeBracketIndex),
                  async: isAsync);
              if (static) {
                _staticFunctions[function.name] = function;
              } else {
                functions[function.name] = function;
              }
              variable = '';
              currentIndex = closeBracketIndex;
              continue;
            } else if (closeRoundBracket + 2 < input.length &&
                input[closeRoundBracket + 1] == '=' &&
                input[closeRoundBracket + 2] == '>') {
              currentIndex = _handleLambdaFunction(variable, input, currentIndex, closeRoundBracket, valueStack);
              variable = '';
              continue;
            } else {
              /// function execution
              CodeProcessor? processor = this;
              while (processor != null) {
                if (processor.functions.containsKey(variable)) {
                  currentIndex = _handleFunction(
                      processor.functions[variable]!, variable, input, currentIndex, closeRoundBracket, valueStack);
                  variable = '';
                  break;
                } else if (processor.variables.containsKey(variable) ||
                    processor.localVariables.containsKey(variable)) {
                  final function =
                      (processor.variables[variable]?.value ?? processor.localVariables[variable]) as FVBFunction;
                  final argumentList = CodeOperations.splitBy(input.substring(currentIndex + 1, closeRoundBracket));
                  final output = function.execute(this, processArgList(argumentList, function.arguments));
                  if (output != null) {
                    valueStack.push(FVBValue(value: output));
                  }
                  variable = '';
                  currentIndex = closeRoundBracket;
                  break;
                }
                processor = processor.parentProcessor;
              }
              if (variable.isEmpty) {
                continue;
              }
              if (!predefinedFunctions.containsKey(variable) && !predefinedSpecificFunctions.containsKey(variable)) {
                enableError('No predefined function named $variable found');
                return;
              }
              final processedArgs = argumentList.map((e) => process(e)).toList();
              final output =
                  (predefinedFunctions[variable] ?? predefinedSpecificFunctions[variable])!.perform.call(processedArgs);

              valueStack.push(FVBValue(value: output));
              variable = '';
              currentIndex = closeRoundBracket;
            }
            continue;
          } else if (ch == '('.codeUnits[0]) {
            final closeOpenBracket =
                CodeOperations.findCloseBracket(input, currentIndex, '('.codeUnits.first, ')'.codeUnits.first);
            if (closeOpenBracket + 1 < input.length &&
                input[closeOpenBracket + 1] == '=' &&
                input[closeOpenBracket + 2] == '>') {
              currentIndex = _handleLambdaFunction(variable, input, currentIndex, closeOpenBracket, valueStack);
              continue;
            } else if (input.length > closeOpenBracket + 1 && input[closeOpenBracket + 1] == '{') {
              final int closeCurlyBracketIndex = CodeOperations.findCloseBracket(
                  input, closeOpenBracket + 1, '{'.codeUnits.first, '}'.codeUnits.first);
              final function = FunctionProcessor.parse(
                this,
                '',
                input.substring(currentIndex + 1, closeOpenBracket),
                input.substring(closeOpenBracket + 2, closeCurlyBracketIndex),
              );
              currentIndex = closeCurlyBracketIndex;
              valueStack.push(FVBValue(value: function));
              continue;
            }
          }

          if (variable.isNotEmpty) {
            if (!resolveVariable(variable, object, valueStack)) {
              return null;
            }
            variable = '';
          }
          if (isOperator(ch)) {
            object = '';
            String operator = input[currentIndex];

            if (currentIndex + 1 < input.length && isOperator(input[currentIndex + 1].codeUnits.first)) {
              if (currentIndex + 2 < input.length &&
                  isValidOperator(operator + input[currentIndex + 1] + input[currentIndex + 2])) {
                operator += (input[currentIndex + 1] + input[currentIndex + 2]);
                currentIndex += 2;
              } else if (isValidOperator(operator + input[currentIndex + 1])) {
                operator = operator + input[currentIndex + 1];
                currentIndex++;
              }
            }
            if (operatorStack.isEmpty || getPrecedence(operator) > getPrecedence(operatorStack.peek!)) {
              operatorStack.push(operator);
            } else {
              while (operatorStack.isNotEmpty && getPrecedence(operator) <= getPrecedence(operatorStack.peek!)) {
                if (error) {
                  return null;
                }
                processOperator(operatorStack.pop()!, object, valueStack, operatorStack);
              }
              operatorStack.push(operator);
            }
          } else if (ch == '('.codeUnits[0]) {
            final index =
                CodeOperations.findCloseBracket(input, currentIndex, '('.codeUnits.first, ')'.codeUnits.first);
            if (index == -1) {
              return null;
            }
            final innerProcess = process<T>(input.substring(currentIndex + 1, index), resolve: true);
            valueStack.push(FVBValue(value: innerProcess));
            currentIndex = index;
          }
        }
      }
      if (variable.isNotEmpty) {
        if (!resolveVariable(variable, object, valueStack)) {
          return null;
        }
        variable = '';
      }

      // Empty out the operator stack at the end of the input
      while (operatorStack.isNotEmpty) {
        if (error) {
          return null;
        }
        processOperator(operatorStack.pop()!, object, valueStack, operatorStack);
      }

      // Print the result if no error has been seen.
      if (!error && valueStack.isNotEmpty) {
        dynamic result;
        while (valueStack.isNotEmpty) {
          if (error) {
            return null;
          }

          final FVBValue value = valueStack.pop()!;
          result = value.evaluateValue(this, ignoreIfNotExist: true);
          if (value.variableName != null && value.createVar) {
            if (variables.containsKey(value.variableName!)) {
              throw Exception('Variable ${value.variableName} already exists');
            }

            final variableModel = VariableModel(
              value.variableName!,
              value.dataType ?? DataType.dynamic,
              isFinal: value.isVarFinal,
              nullable: value.nullable,
              value: value.value,
            );
            if (value.static) {
              _staticVariables[value.variableName!] = variableModel;
            } else {
              variables[value.variableName!] = variableModel;
            }
          }
        }

        if (operatorStack.isNotEmpty || valueStack.isNotEmpty) {
          logger('Expression error.');
        } else {
          return result;
        }
      }
      return null;
    } on Exception catch (_) {
      enableError(_.toString() + ' at code $input ');
      return null;
    }
  }

  List<dynamic> processArgList(List<String> argumentList, List<FVBArgument> arguments) {
    return ArgumentProcessor.process(this, argumentList, arguments);
  }

  List<FVBArgument> processArgDefinitionList(List<String> argumentList, {Map<String, FVBVariable>? variables}) {
    return ArgumentProcessor.processArgumentDefinition(this, argumentList, variables: variables);
  }

  bool parseNumber(String number, valueStack) {
    if (number.contains('.')) {
      final parse = double.tryParse(number);
      if (parse != null) {
        valueStack.push(FVBValue(value: parse));
        return true;
      }
    } else {
      final intParsed = int.tryParse(number);
      if (intParsed != null) {
        valueStack.push(FVBValue(value: intParsed));
        return true;
      }
    }
    return false;
  }

  void enableError(String message, {String line = ''}) {
    error = true;
    onError.call(message.replaceAll(space, ' ') + ' at $scopeName', line.replaceAll(space, ' '));
  }

  bool isString(String value) {
    if (value.length >= 2) {
      return value[0] == value[value.length - 1] && (value[0] == '\'' || value[0] == '"');
    }
    return false;
  }

  bool resolveVariable(String variable, String object, valueStack) {
    if (variable == 'break') {
      valueStack.push(FVBValue(value: FVBBreak()));
      return true;
    } else if (variable == 'continue') {
      valueStack.push(FVBValue(value: FVBContinue()));
      return true;
    } else if (variable == 'null') {
      valueStack.push(FVBValue(value: null));
      return true;
    } else if (variable.startsWith('return$space')) {
      valueStack.push(
        FVBValue(
          value: FVBReturn(
            process(
              variable.substring(7),
            ),
          ),
        ),
      );
      return true;
    } else if (variable.startsWith('var$space')) {
      valueStack.push(
          FVBValue(variableName: variable.substring(4), dataType: DataType.dynamic, createVar: true, nullable: true));
      return true;
    } else if (parseNumber(variable, valueStack)) {
      return true;
    } else {
      final value = DataTypeProcessor.getFVBValueFromCode(variable, classes, enableError);
      if (value != null) {
        valueStack.push(value);
        return true;
      }
      if (error) {
        return false;
      }
    }
    valueStack.push(FVBValue(variableName: variable, object: object.isNotEmpty ? object : null));
    return true;
  }

  int _handleLambdaFunction(String variable, final String input, final int currentIndex, final int closeOpenBracket,
      final Stack2<FVBValue> valueStack) {
    bool static = false;
    if (variable.startsWith('static$space')) {
      static = true;
      variable = variable.substring(7);
    }
    final function = FunctionProcessor.parse(this, variable, input.substring(currentIndex + 1, closeOpenBracket),
        input.substring(closeOpenBracket + 3, input.length),
        lambda: true);
    if (function.name.isNotEmpty) {
      if (static) {
        _staticFunctions[function.name] = function;
      } else {
        functions[function.name] = function;
      }
    }
    valueStack.push(FVBValue(value: function));
    return input.length - 1;
  }

  int _handleFunction(final FVBFunction function, final String variable, final String input, int currentIndex,
      final int closeRoundBracket, final Stack2<FVBValue> valueStack) {
    if (valueStack.isEmpty && declarativeOnly) {
      throw Exception('can not call function $variable in declarative mode');
    }
    final argumentList = CodeOperations.splitBy(input.substring(currentIndex + 1, closeRoundBracket));
    final output = function.execute(this, processArgList(argumentList, function.arguments));
    valueStack.push(FVBValue(value: output));

    return closeRoundBracket;
  }

  void _handleObjectMethods(
      final objectInstance, final String variable, final List<String> argumentList, final Stack2<FVBValue> valueStack) {
    final object = classes[objectInstance.runtimeType.toString()];
    if (object == null) {
      throw Exception('Object ${objectInstance.runtimeType} not found');
    }
    final method = object.fvbFunctions[variable];
    if (method == null || method.dartCall == null) {
      throw Exception('Method $variable not found');
    }
    final processedArgs = processArgList(argumentList, method.arguments);
    valueStack.push(
      FVBValue(
        value: method.execute(this, processedArgs,self: objectInstance),
      ),
    );
    // if (objectInstance is String) {
    //   final processedArgs = argumentList.map((e) => process(e)).toList();
    //   switch (variable) {
    //     case 'substring':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.substring(
    //               processedArgs[0], processedArgs[1])));
    //       break;
    //     case 'split':
    //       valueStack
    //           .push(FVBValue(value: objectInstance.split(processedArgs[0])));
    //       break;
    //     case 'contains':
    //       valueStack
    //           .push(FVBValue(value: objectInstance.contains(processedArgs[0])));
    //       break;
    //     case 'startsWith':
    //       valueStack.push(
    //           FVBValue(value: objectInstance.startsWith(processedArgs[0])));
    //       break;
    //     case 'endsWith':
    //       valueStack
    //           .push(FVBValue(value: objectInstance.endsWith(processedArgs[0])));
    //       break;
    //     case 'trim':
    //       valueStack.push(FVBValue(value: objectInstance.trim()));
    //       break;
    //     case 'toLowerCase':
    //       valueStack.push(FVBValue(value: objectInstance.toLowerCase()));
    //       break;
    //     case 'toUpperCase':
    //       valueStack.push(FVBValue(value: objectInstance.toUpperCase()));
    //       break;
    //     case 'replaceAll':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.replaceAll(
    //               processedArgs[0], processedArgs[1])));
    //       break;
    //     case 'replaceFirst':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.replaceFirst(
    //               processedArgs[0], processedArgs[1])));
    //       break;
    //     case 'indexOf':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.indexOf(processedArgs[0],
    //               processedArgs.length > 1 ? processedArgs[1] : null)));
    //       break;
    //     case 'lastIndexOf':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.lastIndexOf(processedArgs[0],
    //               processedArgs.length > 1 ? processedArgs[1] : null)));
    //       break;
    //     case 'replaceRange':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.replaceRange(
    //               processedArgs[0], processedArgs[1], processedArgs[2])));
    //       break;
    //   }
    // }
    // else if (objectInstance is Iterable) {
    //   final processedArgs = argumentList.map((e) => process(e)).toList();
    //   switch (variable) {
    //     case 'add':
    //       if (objectInstance is List) {
    //         objectInstance.add(processedArgs[0]);
    //       }
    //       break;
    //     case 'insert':
    //       if (objectInstance is List) {
    //         objectInstance.insert(processedArgs[0], processedArgs[1]);
    //       }
    //       break;
    //     case 'clear':
    //       if (objectInstance is List) {
    //         objectInstance.clear();
    //       }
    //       break;
    //     case 'addAll':
    //       if (objectInstance is List) {
    //         objectInstance.addAll(processedArgs[0]);
    //       }
    //       break;
    //     case 'removeAt':
    //       if (objectInstance is List) {
    //         objectInstance.removeAt(processedArgs[0]);
    //       }
    //       break;
    //     case 'remove':
    //       if (objectInstance is List) {
    //         objectInstance.remove(processedArgs[0]);
    //       }
    //       break;
    //     case 'indexOf':
    //       if (objectInstance is List) {
    //         valueStack.push(FVBValue(
    //             value: objectInstance.indexOf(processedArgs[0],
    //                 processedArgs.length > 1 ? processedArgs[1] : null)));
    //       }
    //       break;
    //     case 'contains':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.contains(
    //         processedArgs[0],
    //       )));
    //       break;
    //     case 'where':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.where((e) =>
    //               (processedArgs[0] as FVBFunction).execute(this, [e]))));
    //       break;
    //     case 'indexWhere':
    //       if (objectInstance is List) {
    //         valueStack.push(FVBValue(
    //             value: objectInstance.indexWhere((e) =>
    //                 (processedArgs[0] as FVBFunction).execute(this, [e]))));
    //       }
    //       break;
    //     case 'firstWhere':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.firstWhere((e) =>
    //               (processedArgs[0] as FVBFunction).execute(this, [e]))));
    //       break;
    //     case 'any':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.any((e) =>
    //               (processedArgs[0] as FVBFunction).execute(this, [e]))));
    //       break;
    //
    //     case 'forEach':
    //       for (var e in objectInstance) {
    //         (processedArgs[0] as FVBFunction).execute(this, [e]);
    //       }
    //       break;
    //
    //     case 'sort':
    //       if (objectInstance is List) {
    //         objectInstance.sort();
    //       }
    //       break;
    //
    //     case 'map':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.map((e) =>
    //               (processedArgs[0] as FVBFunction).execute(this, [e]))));
    //       break;
    //     case 'reduce':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.reduce((e, f) =>
    //               (processedArgs[0] as FVBFunction).execute(this, [e, f]))));
    //       break;
    //     case 'fold':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.fold(
    //               processedArgs[0],
    //               (e, f) => (processedArgs[1] as FVBFunction)
    //                   .execute(this, [e, f]))));
    //       break;
    //     case 'every':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.every((e) =>
    //               (processedArgs[0] as FVBFunction).execute(this, [e]))));
    //       break;
    //     case 'expand':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.expand((e) =>
    //               (processedArgs[0] as FVBFunction).execute(this, [e]))));
    //       break;
    //     case 'take':
    //       valueStack
    //           .push(FVBValue(value: objectInstance.take(processedArgs[0])));
    //       break;
    //     case 'takeWhile':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.takeWhile((e) =>
    //               (processedArgs[0] as FVBFunction).execute(this, [e]))));
    //       break;
    //     case 'skip':
    //       valueStack
    //           .push(FVBValue(value: objectInstance.skip(processedArgs[0])));
    //       break;
    //     case 'skipWhile':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.skipWhile((e) =>
    //               (processedArgs[0] as FVBFunction).execute(this, [e]))));
    //       break;
    //     case 'elementAt':
    //       valueStack.push(
    //           FVBValue(value: objectInstance.elementAt(processedArgs[0])));
    //       break;
    //     case 'sublist':
    //       if (objectInstance is List) {
    //         valueStack.push(FVBValue(
    //             value: objectInstance.sublist(
    //                 processedArgs[0], processedArgs[1])));
    //       }
    //       break;
    //     case 'getRange':
    //       if (objectInstance is List) {
    //         valueStack.push(FVBValue(
    //             value: objectInstance.getRange(
    //                 processedArgs[0], processedArgs[1])));
    //       }
    //       break;
    //     case 'removeRange':
    //       if (objectInstance is List) {
    //         objectInstance.removeRange(processedArgs[0], processedArgs[1]);
    //       }
    //       break;
    //     case 'setRange':
    //       if (objectInstance is List) {
    //         objectInstance.setRange(
    //             processedArgs[0], processedArgs[1], processedArgs[2]);
    //       }
    //       break;
    //     case 'fillRange':
    //       if (objectInstance is List) {
    //         objectInstance.fillRange(
    //             processedArgs[0], processedArgs[1], processedArgs[2]);
    //       }
    //       break;
    //     case 'toList':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.toList(
    //               growable:
    //                   processedArgs.isNotEmpty ? processedArgs[0] : true)));
    //       break;
    //     case 'toSet':
    //       valueStack.push(FVBValue(value: objectInstance.toSet()));
    //       break;
    //     case 'asMap':
    //       if (objectInstance is List) {
    //         valueStack.push(FVBValue(value: objectInstance.asMap()));
    //       }
    //       break;
    //   }
    // }
    // else if (objectInstance is Map) {
    //   final processedArgs = argumentList.map((e) => process(e)).toList();
    //   switch (variable) {
    //     case 'remove':
    //       objectInstance.remove(processedArgs[0]);
    //       break;
    //     case 'containsKey':
    //       valueStack.push(
    //           FVBValue(value: objectInstance.containsKey(processedArgs[0])));
    //       break;
    //     case 'containsValue':
    //       valueStack.push(
    //           FVBValue(value: objectInstance.containsValue(processedArgs[0])));
    //       break;
    //     case 'map':
    //       valueStack.push(FVBValue(
    //           value: objectInstance.map((key, value) =>
    //               (processedArgs[0] as FVBFunction)
    //                   .execute(this, [key, value]))));
    //       break;
    //     case 'forEach':
    //       objectInstance.forEach((key, value) {
    //         (processedArgs[0] as FVBFunction).execute(this, [key, value]);
    //       });
    //       break;
    //     case 'clear':
    //       objectInstance.clear();
    //       break;
    //   }
    // }
  }

  void finishProcessing(final String variable, final String operator, final String object, operatorStack, valueStack) {
    if (variable.isNotEmpty) {
      resolveVariable(variable, object, valueStack);
    }
    while (operatorStack.isNotEmpty && getPrecedence(operator) <= getPrecedence(operatorStack.peek!)) {
      if (error) {
        return;
      }

      processOperator(operatorStack.pop()!, object, valueStack, operatorStack);
    }
  }

  void _handleVariableAndFunctionSuggestions(
    final String variable,
    final String object,
    final Stack2<FVBValue> valueStack,
  ) {
    final CodeSuggestion suggestion;
    if (object.isNotEmpty) {
      suggestion = CodeSuggestion(variable);
      final obj = getVarType(object);
      if (classes.containsKey(object)) {
        final fvbClass = classes[object]!;
        if (fvbClass.fvbStaticFunctions != null) {
          suggestion.addAll(
            SuggestionProcessor.processFunctions(fvbClass.fvbStaticFunctions!.values, variable, object, '', false,
                static: true),
          );
        }
        suggestion.addAll(
          SuggestionProcessor.processNamedConstructor(fvbClass.getNamedConstructor, variable, object, '', false,
              static: true),
        );

        if (fvbClass.fvbStaticVariables != null) {
          suggestion.addAll(SuggestionProcessor.processVariables(fvbClass.fvbStaticVariables!, variable, object, false,
              static: true));
        }
      } else if (obj.name == 'fvbInstance') {
        final fvbClass = classes[obj.fvbName!]!;
        suggestion.addAll(
          SuggestionProcessor.processFunctions(fvbClass.fvbFunctions.values, variable, object, fvbClass.name, false),
        );
        suggestion.addAll(SuggestionProcessor.processVariables(
            fvbClass.fvbVariables.map((key, value) => MapEntry(key, value())), variable, object, false));
      }
    } else {
      if (suggestionConfig.namedParameterSuggestion != null) {
        suggestion = CodeSuggestion(variable);
        suggestion.addAll(suggestionConfig.namedParameterSuggestion!.parameters
            .where((element) => element.contains(variable))
            .map((e) => SuggestionTile(e, '', SuggestionType.keyword, e, 0)));
      } else {
        final list = variable.split(space);
        list.remove('final');
        list.remove('var');
        if (list.isEmpty) {
          return;
        }
        final keyword = list.last;
        suggestion = CodeSuggestion(keyword);
        if (list.length == 1) {
          CodeProcessor? processor = this;
          final globalName = ComponentOperationCubit.currentProject!.name;
          suggestion.addAll(keywords
              .where((element) => element != keyword && element.startsWith(keyword))
              .map((e) => SuggestionTile(e, globalName, SuggestionType.keyword, e, 0, global: true)));
          suggestion.addAll(
            predefinedFunctions.entries.where((e) => e.key.contains(keyword)).map(
                  (e) => SuggestionTile(e.value, '', SuggestionType.builtInFun, e.value.name + '()', 1),
                ),
          );
          SuggestionProcessor.processClasses(classes, keyword, object, valueStack, suggestion);
          suggestion.addAll(localVariables.keys.where((element) => element.contains(keyword)).map(
              (element) => SuggestionTile(element, processor!.scopeName, SuggestionType.localVariable, element, 0)));
          while (processor != null) {
            final global = processor.scopeName == globalName;
            suggestion.addAll(SuggestionProcessor.processFunctions(
                processor.functions.values, keyword, processor.scopeName, processor.scopeName, global));

            suggestion.addAll(
              SuggestionProcessor.processVariables(processor.variables, keyword, processor.scopeName, global),
            );
            processor = processor.parentProcessor;
          }
        } else if (list.length == 2) {
          if (list.first.contains(keyword)) {
            final suggest1 = StringOperation.toCamelCase(list.first, startWithLower: true);
            suggestion.add(SuggestionTile(suggest1, '', SuggestionType.keyword, suggest1, 0));
          }
        }
      }
    }
    onSuggestions?.call(suggestion);
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

  int get length => _list.length;

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

  @override
  String toString() {
    return '$condition :: $body';
  }
}

class CaseStatement {
  final String? condition;
  final String body;

  CaseStatement(this.condition, this.body);
}

class SuggestionTile {
  final dynamic value;
  final String scope;
  final SuggestionType type;
  final bool global;
  final String result;
  final int resultCursorEnd;
  final int? resultCursorStart;
  int priority = 0;

  String get title {
    if (type == SuggestionType.keyword || type == SuggestionType.localVariable) {
      return value;
    }
    return value.name;
  }

  SuggestionTile(this.value, this.scope, this.type, this.result, this.resultCursorEnd,
      {this.global = false, this.resultCursorStart});
}

class CodeSuggestion {
  final String code;
  final List<SuggestionTile> suggestions = [];

  CodeSuggestion(this.code);

  void addAll(final Iterable<SuggestionTile> suggestions) {
    for (final suggestion in suggestions) {
      add(suggestion);
    }
  }

  void add(SuggestionTile suggestion) {
    int priority = 0;
    if (suggestion.type == SuggestionType.keyword) {
      priority += 1;
    } else if (suggestion.type == SuggestionType.variable && !suggestion.global) {
      priority += 1;
    }
    final name = suggestion.title;
    if (name != code) {
      priority += ((name.length - name.indexOf(code)) ~/ name.length);
    }

    int i = suggestions.length - 1;
    while (i >= 0 && suggestions[i].priority < priority) {
      i--;
    }

    i++;
    if (i < suggestions.length) {
      suggestions.insert(i, suggestion);
    } else {
      suggestions.add(suggestion);
    }
  }
}

enum SuggestionType {
  variable,
  localVariable,
  function,
  classes,
  staticVar,
  staticFun,
  builtInFun,
  builtInVar,
  argument,
  keyword,
}
