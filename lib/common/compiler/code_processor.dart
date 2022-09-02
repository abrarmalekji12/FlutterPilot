import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/common/compiler/fvb_class.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../bloc/error/error_bloc.dart';
import '../../bloc/state_management/state_management_bloc.dart';
import '../../code_to_component.dart';
import '../../component_list.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../cubit/stack_action/stack_action_cubit.dart';
import '../../injector.dart';
import '../../models/builder_component.dart';
import '../../models/component_model.dart';
import '../../models/function_model.dart';
import '../../models/local_model.dart';
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
import 'fvb_enums.dart';
import 'fvb_function_variables.dart';

part 'fvb_behaviour.dart';

Color hexToColor(String hexString) {
  if (hexString.length < 7) {
    return Colors.black;
  }
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  final colorInt = int.parse(buffer.toString(), radix: 16);
  return Color(colorInt);
}

final Map<String, CodeProcessor> processorMap = {};
const List<String> keywords = [
  'class ',
  'final',
  'static ',
  'while(',
  'await ',
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
  CodeProcessor? parentProcessor;
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
  static final Map<String, FVBEnum> enums = {};
  final Map<String, dynamic> localVariables = {};
  static OperationType operationType = OperationType.regular;
  final Scope scope;
  static bool error = false;
  bool finished = false;
  static final VariableModel _piVariable = VariableModel(
      'pi', DataType.fvbDouble,
      deletable: false,
      uiAttached: true,
      value: math.pi,
      description: 'it is mathematical value of pi',
      isFinal: true);

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
      smallACodeUnit = 'a'.codeUnits.first,
      capitalZCodeUnit = 'Z'.codeUnits.first,
      smallZCodeUnit = 'z'.codeUnits.first,
      underScoreCodeUnit = '_'.codeUnits.first,
      questionMarkCodeUnit = '?'.codeUnits.first,
      roundBracketClose = ')'.codeUnits.first,
      roundBracketOpen = '('.codeUnits.first,
      squareBracketClose = ']'.codeUnits.first,
      squareBracketOpen = '['.codeUnits.first,
      curlyBracketClose = '}'.codeUnits.first,
      curlyBracketOpen = '{'.codeUnits.first,
      triangleBracketClose = '>'.codeUnits.first,
      triangleBracketOpen = '<'.codeUnits.first,
      commaCodeUnit = ','.codeUnits.first;

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

  factory CodeProcessor.build(
      {CodeProcessor? processor, required String name}) {
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

  CodeProcessor clone(consoleCallback, onError) {
    final processor = CodeProcessor(
      parentProcessor: parentProcessor?.clone(consoleCallback, onError),
      consoleCallback: consoleCallback,
      onError: onError,
      scopeName: scopeName,
    );
    processor.variables.addAll(variables.map((key, value) {
      return MapEntry(key, value.clone());
    }));
    processor.functions
        .addAll(functions.map((key, value) => MapEntry(key, value)));
    return processor;
  }

  CodeProcessor(
      {this.scope = Scope.main,
      required this.scopeName,
      this.parentProcessor,
      required this.consoleCallback,
      required this.onError}) {
    error = false;

    predefinedSpecificFunctions['print'] =
        FunctionModel<void>('print', (arguments, processor) {
      if (arguments.isEmpty) {
        throw Exception('print function requires at least one argument');
      }
      consoleCallback
          .call('print:${arguments.map((e) => e.toString()).join('')}');
    }, description: 'print the given arguments');

    predefinedSpecificFunctions['showSnackbar'] =
        FunctionModel<void>('showSnackbar', (arguments, processor) {
      if (arguments.length < 2) {
        throw Exception('showSnackbar requires 2 arguments!!');
      }
      importFiles['showSnackbar']=true;
      consoleCallback.call('api:snackbar',arguments: arguments);
    }, description: 'show a snackbar');

    predefinedSpecificFunctions['newPage'] =
        FunctionModel<void>('newPage', (arguments, processor) {
      if (arguments.isEmpty) {
        throw Exception('newPage requires 1 argument!!');
      }
      consoleCallback.call('api:newpage|${arguments[0]}',
          arguments: arguments.length == 2 ? arguments[1] : null);
    }, description: 'open a new page');
    predefinedSpecificFunctions['replacePage'] =
        FunctionModel<void>('replacePage', (arguments, processor) {
      if (arguments.isEmpty) {
        throw Exception('replacePage requires atleast 1 argument!!');
      }
      consoleCallback.call('api:replacepage|${arguments[0]}',
          arguments: arguments.length == 2 ? arguments[1] : null);
    }, description: 'open a new page');
    predefinedSpecificFunctions['goBack'] =
        FunctionModel<void>('goBack', (arguments, processor) {
      consoleCallback.call('api:goback|');
    }, description: 'go back to previous page');
    predefinedSpecificFunctions['lookUp'] =
        FunctionModel<dynamic>('lookUp', (arguments, processor) {
      final id = arguments[0];
      FVBInstance? out;
      get<StackActionCubit>()
          .navigationStack
          .last
          .uiScreen
          .rootComponent
          ?.forEach((p0) {
        if (p0.id == id) {
          if (p0 is CTextField) {
            out = classes['TextField']?.createInstance(this, [])
              ?..variables['text']?.value = p0.textEditingController.text
              ..functions['setText']?.dartCall = (arguments, instance) {
                p0.textEditingController.text = arguments[0];
              };
          } else if (p0 is CPageViewBuilder || p0 is CPageView) {
            print(
                'HERE TY YT ${(p0 as Controller).controlMap['controller']?.value}');
            out = classes['PageView']!.createInstance(this, [])
              ..variables['controller']!.value =
                  (classes['PageController']!.createInstance(this, [])
                    ..variables['_dart']?.value =
                        (p0 as Controller).controlMap['controller']?.value);
          }
        }
      });
      return out;
    }, description: 'look up a component by id');
    predefinedSpecificFunctions['refresh'] =
        FunctionModel<void>('refresh', (arguments, processor) {
      if (arguments.isNotEmpty && (arguments[0] as String).isNotEmpty) {
        if (!refresherUsed.contains(arguments[0])) {
          refresherUsed.add(arguments[0]);
        }
      }
      consoleCallback
          .call('api:refresh|${arguments.isNotEmpty ? arguments[0] : ''}');
    }, description: 'refresh specific widget by ID');
    predefinedSpecificFunctions['get'] =
        FunctionModel<dynamic>('get', (arguments, processor) {
      final url = arguments[0] as String;
      final futureOfGet = classes['Future']!.createInstance(this, []);
      http.get(Uri.parse(url)).then((value) {
        (futureOfGet.variables['onValue']?.value as FVBFunction?)
            ?.execute(this, null, [value.body]);
      }).onError((error, stackTrace) {
        (futureOfGet.variables['onError']?.value as FVBFunction?)
            ?.execute(this, null, [error!]);
      });
      return futureOfGet;
    }, description: 'get data from a url');
    predefinedSpecificFunctions['hexToColor'] =
        FunctionModel<FVBInstance?>('hexToColor', (arguments, processor) {
      final color = hexToColor(arguments[0]);
      return classes['Color']?.createInstance(this, [color.value]);
    }, description: 'return a color from a hex string');
    if (scopeName == 'MainScope') {
      variables['pi'] = _piVariable;
    }
  }

  void enableSuggestion(void Function(CodeSuggestion?) suggestions) {
    onSuggestions = suggestions;
  }

  void disableSuggestion() {
    onSuggestions = null;
  }

  static init() {
    enums.clear();
    classes.clear();
    enums.addAll(FVBModuleClasses.fvbEnums);
    classes.addAll(FVBModuleClasses.fvbClasses);

    predefinedFunctions['res'] = FunctionModel<dynamic>('res',
        (arguments, processor) {
      final CodeProcessor processor =
          ComponentOperationCubit.currentProject!.processor;
      if (processor.variables['dw']!.value >
          processor.variables['tabletWidthLimit']!.value) {
        return arguments[0];
      } else if (processor.variables['dw']!.value >
              processor.variables['phoneWidthLimit']!.value ||
          arguments.length == 2) {
        return arguments[1];
      } else {
        return arguments[2];
      }
    },
        functionCode: '''
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
    ''',
        description: 'return one of the argument according to the screen size');
    predefinedFunctions['openDrawer'] =
        FunctionModel<void>('openDrawer', (arguments, processor) {
      processor.consoleCallback
          .call('api:drawerOpen|', arguments: [arguments[0]]);
    }, description: 'open the drawer');
    predefinedFunctions['closeDrawer'] =
        FunctionModel<void>('openDrawer', (arguments, processor) {
      processor.consoleCallback.call('api:drawerClose|');
    }, description: 'open the drawer');
    predefinedFunctions['ifElse'] =
        FunctionModel<dynamic>('ifElse', (arguments, processor) {
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

    predefinedFunctions['randInt'] =
        FunctionModel<int>('randInt', (arguments, processor) {
      if (arguments.length == 1) {
        return math.Random.secure().nextInt(arguments[0] ?? 100);
      }
      return 0;
    }, functionCode: '''
    int randInt(int? max){
    return Random.secure().nextInt(max??100);
    }
    ''', description: 'return a random integer between 0 and max');
    predefinedFunctions['jsonEncode'] =
        FunctionModel<String>('jsonEncode', (arguments, processor) {
      if (arguments.length == 1) {
        return jsonEncode(arguments[0]);
      }
      return '';
    }, description: 'encode a json object');
    predefinedFunctions['jsonDecode'] =
        FunctionModel<dynamic>('jsonDecode', (arguments, processor) {
      if (arguments.length == 1 && arguments[0] != null) {
        return jsonDecode(arguments[0]);
      }
      return '';
    }, description: 'decode a json object');

    predefinedFunctions['randDouble'] =
        FunctionModel<double>('randDouble', (arguments, processor) {
      return math.Random.secure().nextDouble();
    }, functionCode: '''
    double randDouble(){
    return Random.secure().nextDouble();
    }
    ''', description: 'return a random double');
    predefinedFunctions['randBool'] =
        FunctionModel<bool>('randBool', (arguments, processor) {
      return math.Random.secure().nextBool();
    }, functionCode: '''
    bool randBool(){
    return Random.secure().nextBool();
    }
    ''', description: 'return a random boolean');
    predefinedFunctions['randColor'] =
        FunctionModel<String>('randColor', (arguments, processor) {
      return '#' +
          Colors.primaries[math.Random().nextInt(Colors.primaries.length)].value
              .toRadixString(16);
    }, functionCode: '''
    String randColor(){
    return '#'+Colors.primaries[Random().nextInt(Colors.primaries.length)].value.toRadixString(16);
    }
    ''', description: 'return a random color');
    predefinedFunctions['sin'] =
        FunctionModel<double>('sin', (arguments, processor) {
      return math.sin(arguments[0]);
    }, description: 'return the sine of the given angle (radian)');
    predefinedFunctions['cos'] =
        FunctionModel<double>('cos', (arguments, processor) {
      return math.cos(arguments[0]);
    }, description: 'return the cosine of the given angle (radian)');

    predefinedFunctions['tan'] =
        FunctionModel<double>('tan', (arguments, processor) {
      return math.tan(arguments[0]);
    }, description: 'return the tangent of the given angle (radian)');
    predefinedFunctions['asin'] =
        FunctionModel<double>('asin', (arguments, processor) {
      return math.asin(arguments[0]);
    }, description: 'return the arc sine of the given angle (radian)');
    predefinedFunctions['acos'] =
        FunctionModel<double>('acos', (arguments, processor) {
      return math.acos(arguments[0]);
    }, description: 'return the arc cosine of the given angle (radian)');
  }

  static String? defaultConsoleCallback(String message,
      {List<dynamic>? arguments}) {
    doAPIOperation(message,
        stackActionCubit: get<StackActionCubit>(),
        stateManagementBloc: get<StateManagementBloc>(),
        arguments: arguments);
    return null;
  }

  static String? testConsoleCallback(String message,
      {List<dynamic>? arguments}) {
    return null;
  }

  static void testOnError(error, line) {
    get<ErrorBloc>().add(ConsoleUpdatedEvent(
        ConsoleMessage(error.toString(), ConsoleMessageType.error)));
  }

  static void defaultOnError(error, line) {
    get<ErrorBloc>().add(
        ConsoleUpdatedEvent(ConsoleMessage(error, ConsoleMessageType.error)));
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
    variables.removeWhere((key, value) =>
        (value is VariableModel) && !value.uiAttached && value.deletable);
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

  FVBCacheValue getValue(final String variable, {String object = ''}) {
    if (object.isNotEmpty) {
      final cache = getValue(object);
      final value = cache.value;
      if (variable == 'runtimeType') {
        // valueStack.push(FVBValue(value: value.runtimeType.toString()));
        return FVBCacheValue(value.runtimeType.toString(), DataType.string);
      }
      final runTimeName = CodeOperations.getRuntimeTypeWithoutGenerics(value);
      if (classes.containsKey(runTimeName)) {
        final instance = classes[runTimeName]?.fvbVariables[variable]?.call();
        if (classes[runTimeName]!.fvbVariables[variable] == null ||
            instance?.getCall == null) {
          throw Exception('No variable $variable in $runTimeName');
        }
        return FVBCacheValue(
            instance!.getCall!
                .call(value is FVBTest ? value.testValue(this) : value, this),
            instance.dataType);
      }
      if (value is CodeProcessor) {
        return value.getValue(variable);
      } else if (value is FVBInstance) {
        return value.processor.getValue(variable);
      } else if (value is FVBClass) {
        return value.getValue(variable, this);
      } else if (value is FVBEnum) {
        if (value.values.containsKey(variable)) {
          return FVBCacheValue(
              value.values[variable], DataType.fvbEnumValue(variable));
        }
        throw Exception('Enum ${value.name} does not contain field $variable');
      }
      return FVBCacheValue(null, DataType.fvbNull);
    }

    if (variable.contains('[')) {
      return getOrSetListMapBracketValue(variable);
    } else if (variable == 'true') {
      return FVBCacheValue(true, DataType.fvbBool);
    } else if (variable == 'false') {
      return FVBCacheValue(false, DataType.fvbBool);
    } else if (variable == 'this') {
      return FVBCacheValue(parentProcessor!, DataType.dynamic);
    } else if (classes.containsKey(variable)) {
      return FVBCacheValue(classes[variable], DataType.fvbType);
    } else if (enums.containsKey(variable)) {
      return FVBCacheValue(enums[variable], DataType.fvbEnumValue(variable));
    }
    CodeProcessor? pointer = this;
    while (pointer != null) {
      if (pointer.localVariables.containsKey(variable)) {
        return FVBCacheValue(
            pointer.localVariables[variable], DataType.dynamic);
      } else if (pointer.variables.containsKey(variable)) {
        if (pointer.variables[variable]!.getCall != null) {
          return FVBCacheValue(
              pointer.variables[variable]!.getCall!.call(null, pointer),
              pointer.variables[variable]!.dataType);
        }
        if (!pointer.variables[variable]!.nullable &&
            pointer.variables[variable]!.value == null) {
          throw Exception('variable $variable is not initialized');
        }
        return FVBCacheValue(pointer.variables[variable]!.value,
            pointer.variables[variable]!.dataType);
      } else if (pointer.functions.containsKey(variable)) {
        return FVBCacheValue(pointer.functions[variable], DataType.fvbFunction);
      }
      pointer = pointer.parentProcessor;
    }
    if (operationType == OperationType.checkOnly &&
        ignoreVariables.containsKey(variable)) {
      return FVBCacheValue(ignoreVariables[variable], DataType.dynamic);
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
      if (isStatic &&
          scopeName == ComponentOperationCubit.currentProject!.name) {
        throw Exception('Cannot create a static variable global scope');
      }

      DataType type;
      if (dataType == null ||
          (dataType == DataType.undetermined && value != null)) {
        type = DataTypeProcessor.getDartTypeToDatatype(value);
      } else if (DataTypeProcessor.checkIfValidDataTypeOfValue(
          value, dataType, variable, nullable)) {
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
      final objectValue = getValue(object).value;
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

    CodeProcessor? parent = this;
    while (parent != null) {
      if (parent.variables.containsKey(variable)) {
        if (parent.variables[variable]!.dataType == DataType.undetermined ||
            !parent.variables[variable]!.initialized) {
          parent.variables[variable]!.value = value;
          parent.variables[variable]!.initialized = true;
          parent.variables[variable]!.dataType =
              DataTypeProcessor.getDartTypeToDatatype(value);
          return true;
        } else if (parent.variables[variable]!.isFinal) {
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

  FVBCacheValue getOrSetListMapBracketValue(String variable, {dynamic value}) {
    int openBracket = variable.indexOf('[');

    if (openBracket != -1) {
      final closeBracket = CodeOperations.findCloseBracket(
          variable, openBracket, '['.codeUnits.first, ']'.codeUnits.first);
      final key = process(variable.substring(openBracket + 1, closeBracket));
      final subVar = variable.substring(0, openBracket);
      openBracket = variable.indexOf('[', closeBracket);
      final cache = getValue(subVar);
      dynamic mapValue = cache.value;
      if (value != null && openBracket == -1) {
        mapValue[key] = value;
        return FVBCacheValue(null, DataType.fvbNull);
      } else {
        if ((mapValue is Map && mapValue.containsKey(key)) ||
            ((mapValue is List || mapValue is String) &&
                key is int &&
                key < mapValue.length)) {
          mapValue = mapValue[key];
        } else {
          final type = cache.dataType.generics?[0] ?? DataType.dynamic;
          return FVBCacheValue(FVBTest(type, false), type);
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
              ((mapValue is List || mapValue is String) &&
                  key is int &&
                  key < mapValue.length)) {
            mapValue = mapValue[key];
          } else {
            return FVBCacheValue(
                FVBTest(
                    (mapValue is FVBInstance && mapValue.generics.isNotEmpty)
                        ? mapValue.generics[0]
                        : DataType.dynamic,
                    false),
                DataType.dynamic);
          }
        }
      }
      return FVBCacheValue(mapValue, DataType.dynamic);
    }
    return FVBCacheValue.fvbNull;
  }

  void processOperator(final String operator, final String object,
      final Stack2<FVBValue> valueStack, final Stack2<String> operatorStack) {
    dynamic a, b;
    late FVBValue aVar, bVar;
    if (valueStack.isEmpty) {
      throw Exception('ValueStack is Empty, syntax error !!');
    } else {
      bVar = valueStack.pop()!;
      b = bVar.evaluateValue(this, ignoreIfNotExist: bVar.createVar);
    }

    if (valueStack.isEmpty &&
        operator != '-' &&
        operator != '--' &&
        operator != '++' &&
        operator != '!') {
      throw Exception(
          'Not enough values for operation "$operator", syntax error !!');
    } else if ((operator != '-' || valueStack.length > operatorStack.length) &&
        valueStack.isNotEmpty) {
      aVar = valueStack.pop()!;
      if (operator != '=') {
        a = aVar.evaluateValue(this, ignoreIfNotExist: bVar.createVar);
      } else {
        a = null;
      }
    }

    if (a is FVBTest || b is FVBTest) {
      valueStack.push(
          FVBValue(value: FVBTest(getOperatorOutputType(operator), false)));
      return;
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
            setValue(
                bVar.variableName!, getValue(bVar.variableName!).value - 1);
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
              object: aVar.object ?? '');
          r = b;
          break;
        case '++':
          final name = bVar.variableName!;
          final value = getValue(name).value;

          if (value != null) {
            setValue(name, value! + 1);
            r = value! + 1;
          } else {
            throw Exception('Variable $name is not defined');
          }

          break;
        case '+=':
          final name = aVar.variableName!;
          final value = getValue(name).value;
          if (value != null) {
            setValue(name, value! + b);
            r = value! + b;
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '-=':
          final name = aVar.variableName!;
          final value = getValue(name).value;
          if (value != null) {
            setValue(name, value! - b);
            r = value! + b;
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '*=':
          final name = aVar.variableName!;
          final value = getValue(name).value;

          if (value != null) {
            setValue(name, value! * b);
            r = value! * b;
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '/=':
          final name = aVar.variableName!;
          final value = getValue(name).value;
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
      throw Exception(e.toString());
    }
    valueStack.push(FVBValue(value: r));
  }

  DataType getOperatorOutputType(String operator) {
    if (operator == '<=' ||
        operator == '>=' ||
        operator == '==' ||
        operator == '!=') {
      return DataType.fvbBool;
    }
    return DataType.fvbInt;
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
      throw Exception('Invalid syntax in string');
    }
    while (startList.isNotEmpty) {
      si = startList.removeAt(0);
      ei = endList.removeAt(0);
      if (si + 2 == ei) {
        throw Exception('No expression between {{ and }} !!');
        // return CodeOutput.right('No variables');
      }
      if (ei > code.length) {
        throw Exception('Not enough characters in string');
      }
      final variableName = code.substring(si + 2, ei);
      final value = process(
        variableName,
        resolve: true,
      );
      if (value is FVBUndefined) {
        throw Exception('undefined ${value.varName}');
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

  void callConstructor(Map<String, String> arguments, CodeProcessor processor) {
    if (functions.containsKey(scopeName)) {
      try {
        final args = functions[scopeName]!.arguments;
        functions[scopeName]!.execute(
            this,
            null,
            ArgumentProcessor.process(
                processor,
                args
                    .map((e) => arguments[e.argName] ?? '')
                    .toList(growable: false),
                args));
      } on Exception catch (e) {
        enableError(e.toString());
        return;
      }
    }
  }

  String? executeCode<T>(final String input,
      {OperationType type = OperationType.regular,
      bool declarativeOnly = true,
      String? oldCode,
      void Function()? onExecutionStart}) {
    final code = cleanCode(input, this);
    if (code == null || oldCode == code) {
      return code;
    }
    error = false;
    operationType = type;
    finished = false;
    final codeCount = lastCodeCount;
    if (isSuggestionEnable) {
      lastCodeCount = 0;
    }

    cacheMemory = CacheMemory(this);
    onExecutionStart?.call();
    execute<T>(code, declarativeOnly: declarativeOnly);

    if (codeCount > lastCodeCount) {
      for (int i = 0; i < codeCount - lastCodeCount; i++) {
        lastCodes.removeLast();
      }
    }
    return code;
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
    }
    return CodeOperations.trim(singleSpaceCode)!;
  }

  dynamic executeAsync<T>(final String trimCode,
      {bool declarativeOnly = false}) async {
    final oldDeclarativeMode = this.declarativeOnly;
    this.declarativeOnly = declarativeOnly;
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
        final endIndex = trimCode[i] == ';' ? i : i + 1;
        final code = trimCode.substring(lastPoint, endIndex);
        dynamic output = process<T>(
          code,
        );
        if (output is FVBFuture) {
          final asyncOutput = process(output.asynCode);
          if (asyncOutput is FVBInstance &&
              asyncOutput.fvbClass.name == 'Future') {
            if (operationType == OperationType.regular) {
              final future =
                  await (asyncOutput.variables['future']!.value as Future);
              output.values.push(FVBValue(value: future));
            } else {
              output.values.push(
                  FVBValue(value: FVBTest(asyncOutput.generics[0], false)));
            }
          }
          process('',
              oldValueStack: output.values, oldOperatorStack: output.operators);
        }

        lastPoint = i + 1;
        if (error) {
          break;
        }
        globalOutput = output;

        if (output is FVBContinue ||
            output is FVBBreak ||
            output is FVBReturn) {
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
      } else if (trimCode[i] == '}' ||
          trimCode[i] == ']' ||
          trimCode[i] == ')') {
        count--;
      }
      if (count == 0 && (trimCode[i] == ';' || trimCode.length == i + 1)) {
        final endIndex = trimCode[i] == ';' ? i : i + 1;
        final code = trimCode.substring(lastPoint, endIndex);
        final output = process<T>(
          code,
        );
        if (output is FVBFuture) {
          throw Exception(
              'can not use await in sync code "${output.asynCode}"');
        }
        lastPoint = i + 1;
        if (error) {
          break;
        }
        globalOutput = output;

        if (output is FVBContinue ||
            output is FVBBreak ||
            output is FVBReturn) {
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
      {bool resolve = false,
      Stack2<FVBValue>? oldValueStack,
      Stack2<String>? oldOperatorStack,
      String extendedError = ''}) {
    int editIndex = -1;
    if (isSuggestionEnable) {
      if (lastCodeCount >= lastCodes.length) {
        lastCodes.add(input);
        if (input.length == 1) {
          editIndex = 0;
        }
      } else if (lastCodes[lastCodeCount] != input) {
        final lastCode = lastCodes[lastCodeCount];
        if (input != lastCode) {
          for (int i = 0; i < input.length && i < lastCode.length; i++) {
            if (input[i] != lastCode[i]) {
              editIndex = i;
              break;
            }
          }
          if (editIndex == -1) {
            editIndex = (input.length > lastCode.length)
                ? input.length - 1
                : lastCode.length - 1;
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
      bool doubleQuote = false;
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
          if (stringCount == 0 &&
              ((ch == '"'.codeUnits.first && doubleQuote) ||
                  (!doubleQuote && ch == '\''.codeUnits.first))) {
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
          } else if (currentIndex + 1 < input.length &&
              ch == '{'.codeUnits.first &&
              input[currentIndex + 1] == '{') {
            stringCount++;
          } else if (currentIndex + 1 < input.length &&
              ch == '}'.codeUnits.first &&
              input[currentIndex + 1] == '}') {
            stringCount--;
          }
          variable += nextToken;

          continue;
        } else if (ch == '"'.codeUnits.first || ch == '\''.codeUnits.first) {
          isNumber = false;
          stringOpen = true;
          doubleQuote = (ch == '"'.codeUnits.first);
        } else if (ch == '['.codeUnits.first) {
          int count = 0;

          for (int i = currentIndex + 1; i < input.length; i++) {
            if (input[i] == ']' && count == 0) {
              final substring = input.substring(currentIndex + 1, i);
              if (!substring.contains(',') &&
                  (valueStack.peek?.value is List ||
                      valueStack.peek?.value is Map)) {
                valueStack.push(FVBValue(
                    value: valueStack.pop()!.value[process(substring)]));
                currentIndex = i;
                break;
              } else if (variable.isNotEmpty) {
                variable = variable + '[$substring]';
                currentIndex = i;
                break;
              } else {
                valueStack.push(FVBValue(
                    value: CodeOperations.splitBy(substring)
                        .map((e) => process(e))
                        .toList()));
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
            final closeCurlyBracket = CodeOperations.findCloseBracket(
                input, currentIndex, '{'.codeUnits.first, '}'.codeUnits.first);
            final CodeProcessor processor = CodeProcessor(
                scope: Scope.object,
                consoleCallback: consoleCallback,
                onError: onError,
                scopeName: className);
            processor.execute(
                input.substring(currentIndex + 1, closeCurlyBracket),
                declarativeOnly: true);
            classes[className] = FVBClass(
              className,
              processor.functions,
              Map.fromEntries(processor.variables.entries.map(
                  (entry) => MapEntry(entry.key, () => entry.value.clone()))),
              parent: this,
              fvbStaticVariables: processor._staticVariables,
              fvbStaticFunctions: processor._staticFunctions,
            );

            currentIndex = closeCurlyBracket;
            variable = '';
            continue;
          } else if (variable.isNotEmpty && variable.startsWith('enum$space')) {
            final name = variable.substring(5);
            final closeCurlyBracket = CodeOperations.findCloseBracket(
                input, currentIndex, '{'.codeUnits.first, '}'.codeUnits.first);
            final values = input
                .substring(currentIndex + 1, closeCurlyBracket)
                .split(',')
                .where((element) => element.isNotEmpty)
                .toList(growable: false)
                .asMap()
                .map((key, value) =>
                    MapEntry(value, FVBEnumValue(value, key, name)));
            enums[name] = FVBEnum(name, values);
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
                    CodeOperations.splitBy(input.substring(currentIndex + 1, i))
                        .asMap()
                        .map((e, n) {
                      final split = CodeOperations.splitBy(n, splitBy: ':');
                      if (split.length != 2) {
                        throw Exception('Invalid map entry');
                      }
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
            ch == commaCodeUnit ||
            ch == spaceCodeUnit) {
          if (ch == questionMarkCodeUnit) {
            if (currentIndex + 1 < input.length &&
                input[currentIndex + 1] == '?') {
              finishProcessing(
                  variable, '??', object, operatorStack, valueStack);
              operatorStack.push('??');
              variable = '';
              object = '';
              currentIndex++;
              continue;
            }
            final colonIndex = CodeOperations.findChar(
                input, currentIndex, colonCodeUnit, [spaceCodeUnit]);

            if (colonIndex != -1) {
              int index = CodeOperations.findChar(
                  input, colonIndex + 1, ','.codeUnits.first, [spaceCodeUnit]);
              if (index == -1) {
                index = input.length;
              }
              finishProcessing(
                  variable, '?', object, operatorStack, valueStack);
              // operatorStack.push('?');
              if (valueStack.pop()?.evaluateValue(this) == true) {
                valueStack.push(FVBValue(
                    value: process(
                        input.substring(currentIndex + 1, colonIndex))));
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
          if ((ch >= zeroCodeUnit && ch <= nineCodeUnit) &&
              variable.codeUnits
                      .where((element) =>
                          (element >= zeroCodeUnit &&
                              element <= nineCodeUnit) ||
                          element == dotCodeUnit)
                      .length ==
                  variable.length) {
            isNumber = true;
          } else {
            isNumber = false;
          }
          if (ch == spaceCodeUnit) {
            if (variable == 'await') {
              return FVBFuture(
                  valueStack, operatorStack, input.substring(currentIndex + 1));
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
            final cache = getValue(object);
            final obj = cache.value;
            object = 'instance';
            if (obj is FVBInstance) {
              localVariables[object] = obj.processor.getValue(variable).value;
            } else if (obj is FVBClass) {
              localVariables[object] = obj.getValue(variable, this).value;
            }
            variable = '';
            if (editIndex == currentIndex && onSuggestions != null) {
              _handleVariableAndFunctionSuggestions(
                  variable, object, valueStack);
            }
            continue;
          } else if (variable.isNotEmpty) {
            object = variable;
            variable = '';
            if (editIndex == currentIndex && onSuggestions != null) {
              _handleVariableAndFunctionSuggestions(
                  variable, object, valueStack);
            }
            continue;
          } else if (valueStack.isNotEmpty) {
            variable = 'instance';
            localVariables[variable] = valueStack.pop()?.value!;
            object = variable;
            variable = '';
            if (editIndex == currentIndex && onSuggestions != null) {
              _handleVariableAndFunctionSuggestions(
                  variable, object, valueStack);
            }
            continue;
          }
        } else {
          /// Functions corner
          /// Condition 1 :: Variable is Not Empty
          if (variable.isNotEmpty && ch == '('.codeUnits[0]) {
            final int closeRoundBracket = CodeOperations.findCloseBracket(
                input, currentIndex, '('.codeUnits.first, ')'.codeUnits.first);

            if (variable == 'for') {
              if (declarativeOnly) {
                throw Exception('for is not allowed in declarative mode');
              }
              int endIndex = CodeOperations.findCloseBracket(
                  input,
                  closeRoundBracket + 1,
                  '{'.codeUnits.first,
                  '}'.codeUnits.first);
              final insideFor =
                  input.substring(currentIndex + 1, closeRoundBracket);
              final innerCode =
                  input.substring(closeRoundBracket + 2, endIndex);
              final splits = CodeOperations.splitBy(insideFor, splitBy: ';');
              if (splits.length != 3) {
                if (insideFor.contains(':')) {
                  final split = CodeOperations.splitBy(insideFor, splitBy: ':');
                  final list = process(split[1]);
                  final variable = DataTypeProcessor.getFVBValueFromCode(
                      split[0], classes, enums);
                  if (variable == null) {
                    throw Exception('Invalid variable declaration in for-each');
                  }
                  if (list is! Iterable) {
                    throw Exception('Invalid for each loop');
                  } else {
                    if (operationType == OperationType.regular) {
                      final processor = CodeProcessor.build(
                          name: 'For-each', processor: this);
                      for (final item in list) {
                        processor.variables.clear();
                        processor.localVariables.clear();
                        processor.localVariables[variable.variableName!] = item;

                        final output = processor.execute(innerCode);
                        if (output is FVBBreak || error || finished) {
                          break;
                        }
                      }
                    } else if (operationType == OperationType.checkOnly) {
                      localVariables[variable.variableName!] = list.isNotEmpty
                          ? list.first
                          : FVBTest(variable.dataType!, false);
                      execute(innerCode);
                      localVariables.remove(variable.variableName!);
                    }
                  }
                } else {
                  if (operationType == OperationType.checkOnly) {
                    execute(insideFor);
                  }
                  throw Exception('For loop syntax error');
                }
              } else {
                process(splits[0]);
                int count = 0;
                if (operationType == OperationType.regular) {
                  while (process(splits[1]) == true) {
                    final output = execute(innerCode);
                    if (output is FVBBreak || error || finished) {
                      break;
                    }
                    process(splits[2]);

                    count++;
                    if (count > 1000000) {
                      throw Exception('For loop goes infinite!!');
                    }
                  }
                } else {
                  process(splits[1]);
                  execute(innerCode);
                  process(splits[2]);
                }
              }
              variable = '';
              currentIndex = endIndex;
              continue;
            }
            final argumentList = CodeOperations.splitBy(
                input.substring(currentIndex + 1, closeRoundBracket));
            if (variable == 'switch') {
              if (declarativeOnly) {
                throw Exception(
                    'Switch statement is not allowed in declarative mode');
              }
              final value = process(argumentList[0]);
              int endBracket = CodeOperations.findCloseBracket(
                  input,
                  closeRoundBracket + 1,
                  '{'.codeUnits.first,
                  '}'.codeUnits.first);
              int index = 0;
              final List<CaseStatement> list = [];
              final String innerCode =
                  input.substring(closeRoundBracket + 2, endBracket);
              int caseIndex = -1;
              while (index < endBracket) {
                if (index > innerCode.length - 1) {
                  break;
                }
                index = innerCode.indexOf('case', index);
                if (index != -1) {
                  if (caseIndex != -1) {
                    final split = CodeOperations.splitBy(
                        innerCode.substring(caseIndex, index),
                        splitBy: ':');
                    list.add(CaseStatement(split[0], split[1]));
                  }
                  caseIndex = index + 5;
                  index += 5;
                } else {
                  break;
                }
              }
              int defaultIndex = -1;
              if (caseIndex != -1 && caseIndex + 1 < innerCode.length) {
                defaultIndex = innerCode.indexOf('default', caseIndex);
                final split = CodeOperations.splitBy(
                    innerCode.substring(caseIndex,
                        defaultIndex != -1 ? defaultIndex : innerCode.length),
                    splitBy: ':');
                if (split.length == 2) {
                  list.add(CaseStatement(split[0], split[1]));
                }
              }
              if (defaultIndex != -1) {
                list.add(
                  CaseStatement(
                    null,
                    innerCode.substring(defaultIndex + 8),
                  ),
                );
              }

              currentIndex = endBracket;
              variable = '';
              bool isTrue = false;
              for (final statement in list) {
                if (operationType == OperationType.checkOnly) {
                  if (statement.condition != null) {
                    process(statement.condition!);
                  }
                  execute(statement.body);
                  continue;
                }
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
              continue;
            }

            /// Constructor Corner
            /// Named and Normal Contractors
            else if (declarativeOnly &&
                (object == scopeName || scopeName == variable)) {
              if (object == scopeName) {
                variable = '$object.$variable';
              }
              final String body;
              final openRoundBracket = currentIndex;
              if (closeRoundBracket + 1 < input.length &&
                  input[closeRoundBracket + 1] == '{') {
                final closeCurlyBracket = CodeOperations.findCloseBracket(
                    input,
                    closeRoundBracket + 1,
                    '{'.codeUnits.first,
                    '}'.codeUnits.first);
                body =
                    input.substring(closeRoundBracket + 2, closeCurlyBracket);
                currentIndex = closeCurlyBracket;
              } else {
                body = '';
                currentIndex = closeRoundBracket;
              }
              final argumentList = CodeOperations.splitBy(
                  input.substring(openRoundBracket + 1, closeRoundBracket));
              functions[variable] = FVBFunction(variable, body,
                  processArgDefinitionList(argumentList, variables: variables));
              variable = '';
              object = '';
              continue;
            }

            /// Named Constructor
            else if (classes.containsKey(object) &&
                classes[object]!
                    .fvbFunctions
                    .containsKey('$object.$variable')) {
              final fvbClass = classes[object]!;
              final constructorName = '$object.$variable';
              valueStack.push(
                FVBValue(
                  value: fvbClass.createInstance(
                    this,
                    processArgList(argumentList,
                        fvbClass.fvbFunctions[constructorName]!.arguments),
                    constructorName: '$object.$variable',
                  ),
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
                      ? processArgList(argumentList,
                          fvbClass.fvbFunctions[variable]!.arguments)
                      : [],
                ),
              ));
              variable = '';
              currentIndex = closeRoundBracket;
              continue;
            } else if (!declarativeOnly &&
                (processorMap.containsKey(variable) ||
                    (processorMap.containsKey(object) &&
                        processorMap[object]!
                            .functions
                            .containsKey('$object.$variable'))) &&
                (input[closeRoundBracket + 1] != '{')) {
              final FVBFunction? function;
              if (processorMap.containsKey(object)) {
                function =
                    processorMap[object]!.functions['$object.$variable']!;
                function.execute(processorMap[object]!, null,
                    processArgList(argumentList, function.arguments));
              } else {
                final processor = processorMap[variable];
                function = processor!.functions[variable];
                if (function != null) {
                  function.execute(processor, null,
                      processArgList(argumentList, function.arguments));
                } else {
                  throw Exception(
                      'No constructor $variable found in class $variable');
                }
              }
            } else if (object.isNotEmpty) {
              /// Object dot function is called.
              var objectInstance = getValue(object).value;
              if (objectInstance is FVBTest) {
                objectInstance = objectInstance.testValue(this);
              }
              if (objectInstance is FVBInstance || objectInstance is FVBClass) {
                final fvbArguments = objectInstance is FVBInstance
                    ? objectInstance.getFunction(this, variable)?.arguments
                    : (objectInstance as FVBClass)
                        .getFunction(this, variable)
                        ?.arguments;
                if (fvbArguments == null) {
                  throw Exception(
                      'Function "$variable" not found in class $object');
                }

                final processedArgs =
                    processArgList(argumentList, fvbArguments);
                final dynamic output;
                if (objectInstance is FVBInstance) {
                  output =
                      objectInstance.executeFunction(variable, processedArgs);
                } else {
                  output = (objectInstance as FVBClass)
                      .executeFunction(this, variable, processedArgs);
                }
                valueStack.push(FVBValue(value: output));
              } else {
                _handleObjectMethods(
                    objectInstance, variable, argumentList, valueStack);
              }
              variable = '';
              object = '';
              currentIndex = closeRoundBracket;
              continue;
            } else if (variable == 'while') {
              if (declarativeOnly) {
                throw Exception(
                    'While statement is not allowed in declarative mode');
              }
              int endIndex = CodeOperations.findCloseBracket(
                  input,
                  closeRoundBracket + 1,
                  '{'.codeUnits.first,
                  '}'.codeUnits.first);

              final innerCode =
                  input.substring(closeRoundBracket + 2, endIndex);
              final conditionalCode =
                  input.substring(currentIndex + 1, closeRoundBracket);
              int count = 0;
              while (process(conditionalCode) == true) {
                final output = execute(innerCode);
                if (output is FVBBreak || error || finished) {
                  break;
                }
                count++;
                if (count > 10000) {
                  throw Exception('While loop goes infinite!!');
                }
              }
              variable = '';
              currentIndex = endIndex;
              continue;
            } else if (variable == 'if') {
              if (declarativeOnly) {
                throw Exception(
                    'If statement is not allowed in declarative mode');
              }
              final List<ConditionalStatement> conditionalStatements = [];
              int endBracket = CodeOperations.findCloseBracket(
                  input,
                  closeRoundBracket + 1,
                  '{'.codeUnits.first,
                  '}'.codeUnits.first);
              conditionalStatements.add(ConditionalStatement(argumentList[0],
                  input.substring(closeRoundBracket + 2, endBracket)));
              currentIndex = endBracket;
              while (input.length > endBracket + 7 &&
                  input.substring(endBracket + 1, endBracket + 5) == 'else') {
                int startBracket = endBracket + 6;
                if (input.substring(startBracket, endBracket + 8) == 'if') {
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
                  currentIndex = endBracket;
                } else {
                  startBracket = endBracket + 5;
                  endBracket = CodeOperations.findCloseBracket(input,
                      startBracket, '{'.codeUnits.first, '}'.codeUnits.first);
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
            } else if (input.length > closeRoundBracket + 1 &&
                (input[closeRoundBracket + 1] == '{' ||
                    (input.length > closeRoundBracket + 6 &&
                        input[closeRoundBracket + 6] == '{'))) {
              final isAsync = input.length > closeRoundBracket + 6
                  ? input.substring(
                          closeRoundBracket + 1, closeRoundBracket + 6) ==
                      'async'
                  : false;
              final int closeBracketIndex = CodeOperations.findCloseBracket(
                  input,
                  isAsync ? closeRoundBracket + 6 : closeRoundBracket + 1,
                  '{'.codeUnits.first,
                  '}'.codeUnits.first);
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
                      ? input.substring(
                          closeRoundBracket + 7, closeBracketIndex)
                      : input.substring(
                          closeRoundBracket + 2, closeBracketIndex),
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
              currentIndex = _handleLambdaFunction(
                  variable, input, currentIndex, closeRoundBracket, valueStack);
              variable = '';
              continue;
            } else {
              /// function execution
              CodeProcessor? processor = this;
              while (processor != null) {
                if (processor.functions.containsKey(variable)) {
                  currentIndex = _handleFunction(
                      processor.functions[variable]!,
                      variable,
                      input,
                      currentIndex,
                      closeRoundBracket,
                      valueStack);
                  variable = '';
                  break;
                } else if (processor.variables.containsKey(variable) ||
                    processor.localVariables.containsKey(variable)) {
                  final FVBFunction? function;
                  if (processor.variables[variable]?.value is FVBFunction) {
                    function = processor.variables[variable]?.value;
                  } else if (processor.localVariables[variable]
                      is FVBFunction) {
                    function = processor.localVariables[variable];
                  } else {
                    function = null;
                  }
                  if (function == null) {
                    throw Exception('Function $variable not found');
                  }
                  final argumentList = CodeOperations.splitBy(
                      input.substring(currentIndex + 1, closeRoundBracket));
                  final output = function.execute(this, null,
                      processArgList(argumentList, function.arguments));
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
              if (!predefinedFunctions.containsKey(variable) &&
                  !predefinedSpecificFunctions.containsKey(variable)) {
                throw Exception('No function named $variable found');
              }
              final processedArgs =
                  argumentList.map((e) => process(e)).toList();
              final output = (predefinedFunctions[variable] ??
                      predefinedSpecificFunctions[variable])!
                  .perform
                  .call(processedArgs, this);

              valueStack.push(FVBValue(value: output));
              variable = '';
              currentIndex = closeRoundBracket;
            }
            continue;
          } else if (ch == '('.codeUnits[0]) {
            final closeOpenBracket = CodeOperations.findCloseBracket(
                input, currentIndex, '('.codeUnits.first, ')'.codeUnits.first);
            if (closeOpenBracket + 1 < input.length &&
                input[closeOpenBracket + 1] == '=' &&
                input[closeOpenBracket + 2] == '>') {
              currentIndex = _handleLambdaFunction(
                  variable, input, currentIndex, closeOpenBracket, valueStack);
              continue;
            } else if (input.length > closeOpenBracket + 1 &&
                input[closeOpenBracket + 1] == '{') {
              final int closeCurlyBracketIndex =
                  CodeOperations.findCloseBracket(input, closeOpenBracket + 1,
                      '{'.codeUnits.first, '}'.codeUnits.first);
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
          if (ch == triangleBracketOpen) {
            final closingIndex = CodeOperations.findChar(
                input, currentIndex + 1, triangleBracketClose, [],
                stop: (unit) => isOperator(unit));
            if (closingIndex != -1) {
              variable += input.substring(currentIndex, closingIndex + 1);
              currentIndex = closingIndex;
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

            if (currentIndex + 1 < input.length &&
                isOperator(input[currentIndex + 1].codeUnits.first)) {
              if (currentIndex + 2 < input.length &&
                  isValidOperator(operator +
                      input[currentIndex + 1] +
                      input[currentIndex + 2])) {
                operator += (input[currentIndex + 1] + input[currentIndex + 2]);
                currentIndex += 2;
              } else if (isValidOperator(operator + input[currentIndex + 1])) {
                operator = operator + input[currentIndex + 1];
                currentIndex++;
              }
            }
            if (operatorStack.isEmpty ||
                getPrecedence(operator) > getPrecedence(operatorStack.peek!)) {
              operatorStack.push(operator);
            } else {
              while (operatorStack.isNotEmpty &&
                  getPrecedence(operator) <=
                      getPrecedence(operatorStack.peek!)) {
                if (error) {
                  return null;
                }
                processOperator(
                    operatorStack.pop()!, object, valueStack, operatorStack);
              }
              operatorStack.push(operator);
            }
          } else if (ch == '('.codeUnits[0]) {
            final index = CodeOperations.findCloseBracket(
                input, currentIndex, '('.codeUnits.first, ')'.codeUnits.first);
            if (index == -1) {
              return null;
            }
            final innerProcess = process<T>(
                input.substring(currentIndex + 1, index),
                resolve: true);
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
        processOperator(
            operatorStack.pop()!, object, valueStack, operatorStack);
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
              value.dataType!,
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
      enableError(_.toString() + ' at code $input $extendedError');
      return null;
    } on Error catch (_) {
      enableError(_.toString() + ' at code $input $extendedError');
      if (kDebugMode) {
        _.printError();
      }
      return null;
    }
  }

  List<dynamic> processArgList(
      List<String> argumentList, List<FVBArgument> arguments) {
    return ArgumentProcessor.process(this, argumentList, arguments);
  }

  List<FVBArgument> processArgDefinitionList(List<String> argumentList,
      {Map<String, FVBVariable>? variables}) {
    return ArgumentProcessor.processArgumentDefinition(this, argumentList,
        variables: variables);
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
    onError.call(message.replaceAll(space, ' ') + ' at $scopeName',
        line.replaceAll(space, ' '));
  }

  bool isString(String value) {
    if (value.length >= 2) {
      return value[0] == value[value.length - 1] &&
          (value[0] == '\'' || value[0] == '"');
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
      valueStack.push(FVBValue(
          variableName: variable.substring(4),
          dataType: DataType.undetermined,
          createVar: true,
          nullable: true));
      return true;
    } else if (parseNumber(variable, valueStack)) {
      return true;
    } else {
      final value = DataTypeProcessor.getFVBValueFromCode(
          variable, classes, CodeProcessor.enums);
      if (value != null) {
        valueStack.push(value);
        return true;
      }
      if (error) {
        return false;
      }
    }
    valueStack.push(FVBValue(
        variableName: variable, object: object.isNotEmpty ? object : null));
    return true;
  }

  int _handleLambdaFunction(
      String variable,
      final String input,
      final int currentIndex,
      final int closeOpenBracket,
      final Stack2<FVBValue> valueStack) {
    bool static = false;
    if (variable.startsWith('static$space')) {
      static = true;
      variable = variable.substring(7);
    }
    final function = FunctionProcessor.parse(
        this,
        variable,
        input.substring(currentIndex + 1, closeOpenBracket),
        input.substring(closeOpenBracket + 3, input.length),
        lambda: true);
    if (function.name.isNotEmpty) {
      if (static) {
        _staticFunctions[function.name] = function;
      } else {
        functions[function.name] = function;
      }
    } else {
      valueStack.push(FVBValue(value: function));
    }
    return input.length - 1;
  }

  int _handleFunction(
      final FVBFunction function,
      final String variable,
      final String input,
      int currentIndex,
      final int closeRoundBracket,
      final Stack2<FVBValue> valueStack) {
    if (valueStack.isEmpty && declarativeOnly) {
      throw Exception('can not call function $variable in declarative mode');
    }
    final argumentList = CodeOperations.splitBy(
        input.substring(currentIndex + 1, closeRoundBracket));
    final output = function.execute(
        this, null, processArgList(argumentList, function.arguments));
    valueStack.push(FVBValue(value: output));

    return closeRoundBracket;
  }

  void _handleObjectMethods(final objectInstance, final String variable,
      final List<String> argumentList, final Stack2<FVBValue> valueStack) {
    final runTimeName =
        CodeOperations.getRuntimeTypeWithoutGenerics(objectInstance);
    final object = classes[runTimeName];
    if (object == null) {
      throw Exception('Object $runTimeName not found');
    }
    final method = object.fvbFunctions[variable];
    if (method == null || method.dartCall == null) {
      throw Exception('Method $variable not found');
    }
    final processedArgs = processArgList(argumentList, method.arguments);
    valueStack.push(
      FVBValue(
        value: method.execute(this, null, processedArgs, self: objectInstance),
      ),
    );
  }

  void finishProcessing(final String variable, final String operator,
      final String object, operatorStack, valueStack) {
    if (variable.isNotEmpty) {
      resolveVariable(variable, object, valueStack);
    }
    while (operatorStack.isNotEmpty &&
        getPrecedence(operator) <= getPrecedence(operatorStack.peek!)) {
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
      if (object == 'instance') {
        final value = localVariables['instance'];
        final runtimeName = CodeOperations.getRuntimeTypeWithoutGenerics(value);
        if (classes.containsKey(runtimeName)) {
          addFVBInstanceSuggestion(
              suggestion, classes[runtimeName]!, object, variable, valueStack);
        } else if (value is FVBInstance) {
          addFVBInstanceSuggestion(
              suggestion, (value.fvbClass), object, variable, valueStack);
        }
      } else if (object == 'this') {
        suggestion.addAll(SuggestionProcessor.processVariables(
            parentProcessor!.variables, variable, object, false));
        suggestion.addAll(
          SuggestionProcessor.processFunctions(
              parentProcessor!.functions.values, variable, object, '', false),
        );
      } else {
        dynamic obj = getValue(object).value;
        if (obj is FVBTest) {
          obj = obj.testValue(this);
        }
        final runtimeName = CodeOperations.getRuntimeTypeWithoutGenerics(obj);

        if (classes.containsKey(runtimeName)) {
          addFVBInstanceSuggestion(
              suggestion, classes[runtimeName]!, object, variable, valueStack);
        } else {
          if (obj is FVBInstance) {
            addFVBInstanceSuggestion(
                suggestion, obj.fvbClass, object, variable, valueStack);
          } else if (obj is FVBClass) {
            final fvbClass = obj;
            if (fvbClass.fvbStaticFunctions != null) {
              suggestion.addAll(
                SuggestionProcessor.processFunctions(
                    fvbClass.fvbStaticFunctions!.values,
                    variable,
                    object,
                    '',
                    false,
                    static: true),
              );
            }
            suggestion.addAll(
              SuggestionProcessor.processNamedConstructor(
                  fvbClass.getNamedConstructor, variable, object, '', false,
                  static: true),
            );

            if (fvbClass.fvbStaticVariables != null) {
              suggestion.addAll(SuggestionProcessor.processVariables(
                  fvbClass.fvbStaticVariables!, variable, object, false,
                  static: true));
            }
          }
        }
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
              .where((element) =>
                  element != keyword && element.startsWith(keyword))
              .map((e) => SuggestionTile(
                  e, globalName, SuggestionType.keyword, e, 0,
                  global: true)));
          suggestion.addAll(
            predefinedFunctions.entries
                .where((e) => e.key.contains(keyword))
                .map(
                  (e) => SuggestionTile(e.value, '', SuggestionType.builtInFun,
                      e.value.name + '()', 1),
                ),
          );
          suggestion.addAll(
            predefinedSpecificFunctions.entries
                .where((e) => e.key.contains(keyword))
                .map(
                  (e) => SuggestionTile(e.value, '', SuggestionType.builtInFun,
                      e.value.name + '()', 1),
                ),
          );
          SuggestionProcessor.processClasses(
              classes, keyword, object, valueStack, suggestion);
          suggestion.addAll(localVariables.keys
              .where((element) => element.contains(keyword))
              .map((element) => SuggestionTile(element, processor!.scopeName,
                  SuggestionType.localVariable, element, 0)));
          suggestion.addAll(ignoreVariables.keys
              .where((element) => element.contains(keyword))
              .map((element) => SuggestionTile(element, processor!.scopeName,
                  SuggestionType.localVariable, element, 0)));
          while (processor != null) {
            final global = processor.scopeName == globalName;
            suggestion.addAll(SuggestionProcessor.processFunctions(
                processor.functions.values,
                keyword,
                processor.scopeName,
                processor.scopeName,
                global));

            suggestion.addAll(
              SuggestionProcessor.processVariables(
                  processor.variables, keyword, processor.scopeName, global),
            );
            processor = processor.parentProcessor;
          }
        } else if (list.length == 2) {
          if (list.first.contains(keyword)) {
            final suggest1 =
                StringOperation.toCamelCase(list.first, startWithLower: true);
            suggestion.add(SuggestionTile(
                suggest1, '', SuggestionType.keyword, suggest1, 0));
          }
        }
      }
    }
    onSuggestions?.call(suggestion);
  }

  void addFVBClassSuggestion(CodeSuggestion suggestion, FVBClass fvbClass,
      String object, String variable, Stack2<FVBValue> valueStack) {
    if (fvbClass.fvbStaticFunctions != null) {
      suggestion.addAll(
        SuggestionProcessor.processFunctions(
            fvbClass.fvbStaticFunctions!.values,
            variable,
            object,
            fvbClass.name,
            false),
      );
    }
    if (fvbClass.fvbStaticVariables != null) {
      suggestion.addAll(SuggestionProcessor.processVariables(
          fvbClass.fvbStaticVariables!
              .map((key, value) => MapEntry(key, value)),
          variable,
          object,
          false));
    }
  }

  void addFVBInstanceSuggestion(CodeSuggestion suggestion, FVBClass fvbClass,
      String object, String variable, Stack2<FVBValue> valueStack) {
    suggestion.addAll(
      SuggestionProcessor.processFunctions(
          fvbClass.fvbFunctions.values, variable, object, fvbClass.name, false),
    );
    suggestion.addAll(SuggestionProcessor.processVariables(
        fvbClass.fvbVariables.map((key, value) => MapEntry(key, value())),
        variable,
        object,
        false));
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
    if (type == SuggestionType.keyword ||
        type == SuggestionType.localVariable) {
      return value;
    }
    return value.name;
  }

  SuggestionTile(
      this.value, this.scope, this.type, this.result, this.resultCursorEnd,
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
    } else if (suggestion.type == SuggestionType.variable &&
        !suggestion.global) {
      priority += 1;
    }
    final name = suggestion.title;
    if (name.startsWith(code)) {
      priority += 100;
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
