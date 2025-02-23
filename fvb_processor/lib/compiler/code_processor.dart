import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/bloc/error/error_bloc.dart';
import 'package:flutter_builder/bloc/state_management/state_management_bloc.dart';
import 'package:flutter_builder/code_operations.dart';
import 'package:flutter_builder/common/common_methods.dart';
import 'package:flutter_builder/common/converter/string_operation.dart';
import 'package:flutter_builder/common/ide/suggestion_processor.dart';
import 'package:flutter_builder/common/logger.dart';
import 'package:flutter_builder/common/utils/operations.dart';
import 'package:flutter_builder/components/component_impl.dart';
import 'package:flutter_builder/components/component_list.dart';
import 'package:flutter_builder/components/holder_impl.dart';
import 'package:flutter_builder/cubit/component_operation/operation_cubit.dart';
import 'package:flutter_builder/cubit/stack_action/stack_action_cubit.dart';
import 'package:flutter_builder/data/remote/firestore/firebase_bridge.dart';
import 'package:flutter_builder/injector.dart';
import 'package:flutter_builder/models/builder_component.dart';
import 'package:flutter_builder/models/function_model.dart';
import 'package:flutter_builder/models/fvb_ui_core/component/component_model.dart';
import 'package:flutter_builder/models/other_model.dart';
import 'package:flutter_builder/models/variable_model.dart';
import 'package:flutter_builder/ui/boundary_widget.dart';
import 'package:flutter_builder/ui/build_view/build_view.dart';
import 'package:flutter_builder/ui/fvb_code_editor.dart';

import 'argument_processor.dart';
import 'constants/processor_constant.dart';
import 'datatype_processor.dart';
import 'function_processor.dart';
import 'fvb_class.dart';
import 'fvb_classes.dart';
import 'fvb_enums.dart';
import 'fvb_function_variables.dart';

part 'fvb_behaviour.dart';

const currentConfig = ProcessorConfig();
const kInstance = '_i';

class ProcessorConfig {
  final bool unmodifiable;
  final bool singleLineProcess;
  final List<FVBFunction>? functions;
  final List<FVBClass>? classes;
  final bool analyzeMode;
  final FvbErrorCallback? errorCallback;

  const ProcessorConfig({
    this.errorCallback,
    this.unmodifiable = false,
    this.singleLineProcess = false,
    this.functions,
    this.analyzeMode = false,
    this.classes,
  });

  ProcessorConfig copyWith(
          {bool? unmodifiable,
          bool? singleLineProcess,
          List<FVBFunction>? functions,
          bool? analyzeMode,
          List<FVBClass>? classes}) =>
      ProcessorConfig(
        unmodifiable: unmodifiable ?? this.unmodifiable,
        singleLineProcess: singleLineProcess ?? this.singleLineProcess,
        functions: functions ?? this.functions,
        analyzeMode: analyzeMode ?? this.analyzeMode,
        classes: classes ?? this.classes,
      );
}

Color hexToColor(String hexString) {
  if (hexString.length < 7) {
    return Colors.black;
  }
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  final colorInt = int.tryParse(buffer.toString(), radix: 16);
  if (colorInt == null) {
    return Colors.transparent;
  }
  return Color(colorInt);
}

final Map<String, Processor> processorMap = {};
const List<String> keywords = [
  'class ',
  'final ',
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
  'void '
];
const List<String> valueKeywords = [
  'true',
  'false',
  'null',
];
String? errorReported;
final VariableModel _piVariable = VariableModel('pi', DataType.fvbDouble,
    deletable: false,
    uiAttached: true,
    value: math.pi,
    description: 'it is mathematical value of pi',
    isFinal: true);
final Map<String, Processor> packages = {};

void initializePackages() {
  final mathPackage = Processor.build(name: 'math', isPackage: true);
  packages['dart:math'] = mathPackage;
  mathPackage.variables['pi'] = _piVariable;
  final utilsPackage = Processor.build(name: 'utils', isPackage: true);

  ///  TODO(CodeGeneration):  Handle code generation
  ///  TODO(AddPredefinedOld Functions here):
  packages['package:common/utils.dart'] = utilsPackage;
  utilsPackage.variables['randomId'] = VariableModel(
    'randomId',
    DataType.string,
    getCall: (data, processor) => randomId,
  );
}

final Map<String, Component> componentIdCache = {};

FVBInstance? lookUp(Processor processor, String id) {
  FVBInstance? out;
  Component? comp;
  if (componentIdCache.containsKey(id)) {
    comp = componentIdCache[id]!;
  } else {
    final List<Viewable> screens;
    final cubit = sl<StackActionCubit>();
    if (cubit.navigationStack.isEmpty ||
        Processor.operationType == OperationType.checkOnly) {
      screens = [
        ...collection.project!.screens,
        ...collection.project!.customComponents
      ];
    } else {
      screens = [cubit.navigationStack.last.viewable];
    }
    bool found = false;
    for (final screen in screens) {
      if (found) {
        break;
      }
      screen.rootComponent?.forEachWithClones((p0) {
        if (p0.id == id) {
          comp = componentIdCache[id] = p0;
          found = true;
          return true;
        }
        return false;
      });
    }
  }
  if (comp != null) {
    if (comp is CTextField || comp is CTextFormField) {
      final controller =
          ((comp as Controller).values['controller'] as TextEditingController);
      out = Processor.classes['TextField']?.createInstance(processor, [])
        ?..variables['text']?.value = controller.text
        ..functions['setText']?.dartCall = (arguments, instance) {
          controller.text = arguments[0];
        };
    } else if (comp is CPageViewBuilder || comp is CPageView) {
      out = pageViewClass.createInstance(processor, [])
        ..variables['controller']!.value =
            (Processor.classes['PageController']!.createInstance(processor, [])
              ..variables['_dart']?.value =
                  (comp as Controller).values['controller']);
    } else if (comp is CTabBar) {
      out = tabBarClass.createInstance(processor, [])
        ..variables['controller']!.value = (Processor.classes['TabController']!
            .createInstance(processor, [])
          ..variables['_dart']?.value = (comp as CTabBar).values['controller']);
    } else if (comp is CForm) {
      out = formClass.createInstance(processor, [])
        ..functions['validate']?.dartCall = (args, value) {
          if (Processor.operationType == OperationType.checkOnly) {
            return false;
          }
          return (comp as CForm).values['key'].currentState?.validate();
        };
    }
  }
  return out;
}

bool disableError = false;

class CheckOnlyConfig {
  final List<String>? avoidScopes;

  CheckOnlyConfig([this.avoidScopes]);
}

typedef FvbErrorCallback = void Function(String, (int, int)?);

class Processor {
  /// All Constants used for compilation process

  Processor? parentProcessor;
  CacheMemory? cacheMemory;
  bool errorSuppress;
  static CheckOnlyConfig? checkOnlyConfig;
  final String scopeName;
  final SuggestionConfig suggestionConfig = SuggestionConfig();

  /// TODO:(Remove this) it is to ignore this two variables from compiler but we don't store datatype of variables
  /// It is 'dw' and 'dh' only for now, where "dw" means device-width and "dh" means device-height
  final Map<String, dynamic> ignoreVariables = {'dw': 0, 'dh': 0};
  final Map<String, FVBVariable> variables = {};
  final Map<String, FVBVariable> staticVariables = {};
  final Map<String, FVBFunction> _staticFunctions = {};
  static final Map<String, FunctionModel> predefinedFunctions = {};
  final Map<String, FunctionModel> predefinedSpecificFunctions = {};
  final Map<String, FVBFunction> functions = {};
  static final Map<String, FVBClass> classes = {};
  static final Map<String, FVBEnum> enums = {};
  final Map<String, FVBCacheValue> localVariables = {};
  final Map<String, DataType>? generics;
  static OperationType operationType = OperationType.regular;
  final Scope scope;
  static bool error = false;
  static String errorMessage = '';
  bool finished = false;

  /// TODO:(ManageTimers) user can create Timer.periodic and Simple Timer, and to cancel that timer it is stored below
  static final List<Timer> timers = [];
  final String? Function(String, {List<dynamic>? arguments}) consoleCallback;
  final FvbErrorCallback onError;
  bool declarationMode = false;

  /// This fields are to determine index where user has updated code, to provide suggestion based
  /// on last typed value by user
  static final List<String> lastCodes = [];
  static int lastCodeCount = 0;

  /// Callback for suggestions, it needs to be enabled by [enableSuggestion] method
  void Function(CodeSuggestion?)? onSuggestions;
  final String? package;

  factory Processor.build(
      {Processor? parent,
      required String name,
      String? package,
      Map<String, DataType>? generics,
      bool avoidBinding = false,
      bool isPackage = false}) {
    final codeProcessor = Processor(
        parentProcessor: parent,
        generics: generics,
        consoleCallback: parent?.consoleCallback ?? defaultConsoleCallback,
        onError: parent?.onError ?? defaultOnError,
        scopeName: name,
        package: package);
    if (parent?.onSuggestions != null) {
      codeProcessor.onSuggestions = parent!.onSuggestions;
    }
    if (!name.startsWith('fun:') &&
        !processorMap.containsKey(name) &&
        !avoidBinding &&
        !isPackage) {
      processorMap[name] = codeProcessor;
    }
    return codeProcessor;
  }

  List<VariableModel> get getAllColorVariables {
    Processor? processor = this;
    final List<VariableModel> list = [];
    while (processor != null) {
      list.addAll(processor.variables.values.whereType<VariableModel>().where(
          (element) =>
              element.uiAttached && element.dataType.equals(fvbColor)));
      processor = processor.parentProcessor;
    }
    return list;
  }

  Processor clone(
      String? Function(String, {List<dynamic>? arguments}) consoleCallback,
      void Function(String, (int, int)?) onError,
      bool errorSuppress) {
    final processor = Processor(
      parentProcessor:
          parentProcessor?.clone(consoleCallback, onError, errorSuppress),
      consoleCallback: consoleCallback,
      onError: onError,
      errorSuppress: errorSuppress,
      scopeName: scopeName,
    );
    processor.variables.addAll(variables.map((key, value) {
      return MapEntry(key, value.clone());
    }));
    processor.localVariables.addAll(localVariables.map((key, value) {
      return MapEntry(key, value);
    }));
    processor.functions
        .addAll(functions.map((key, value) => MapEntry(key, value)));
    return processor;
  }

  Processor(
      {this.scope = Scope.main,
      required this.scopeName,
      this.parentProcessor,
      this.generics,
      this.package,
      this.onSuggestions,
      this.errorSuppress = false,
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
    predefinedSpecificFunctions['lookUp'] =
        FunctionModel<dynamic>('lookUp', (arguments, processor) {
      final id = arguments[0];
      return lookUp(processor, id);
    }, description: 'look up a component by id');
    predefinedSpecificFunctions['refresh'] =
        FunctionModel<void>('refresh', (arguments, processor) {
      if (arguments.isNotEmpty && (arguments[0] is String)) {
        if (!refresherUsed.contains(arguments[0])) {
          refresherUsed.add(arguments[0]);
        }
      }
      consoleCallback
          .call('api:refresh|${arguments.isNotEmpty ? arguments[0] : ''}');
    }, description: 'refresh specific widget by ID');
    // predefinedSpecificFunctions['get'] =
    //     FunctionModel<dynamic>('get', (arguments, processor) {
    //   final url = arguments[0] as String;
    //   final futureOfGet = classes['Future']!.createInstance(this, []);
    //   http.get(Uri.parse(url)).then((value) {
    //     (futureOfGet.variables['onValue']?.value as FVBFunction?)
    //         ?.execute(this, null, [value.body]);
    //   }).onError((error, stackTrace) {
    //     (futureOfGet.variables['onError']?.value as FVBFunction?)
    //         ?.execute(this, null, [error!]);
    //   });
    //   return futureOfGet;
    // }, description: 'get data from a url');
    predefinedSpecificFunctions['hexToColor'] =
        FunctionModel<FVBInstance?>('hexToColor', (arguments, processor) {
      final color = hexToColor(arguments[0]);
      return classes['Color']?.createInstance(this, [color.value]);
    }, description: 'return a color from a hex string');
  }

  void enableSuggestion(void Function(CodeSuggestion?) suggestions) {
    onSuggestions = suggestions;
  }

  void disableSuggestion() {
    onSuggestions = null;
  }

  static void init() {
    enums.clear();
    classes.clear();
    enums.addAll(FVBModuleClasses.fvbEnums);
    classes.addAll(FVBModuleClasses.fvbClasses);
    predefinedFunctions['res'] = FunctionModel<dynamic>('res',
        (arguments, temp) {
      if (arguments.length < 2) {
        temp.enableError('provide large-screen, tablet sizes');
        return;
      }
      final Processor processor = systemProcessor;

      final Processor projectProcessor = sl<Processor>();
      if (processor.variables['dw']!.value >
          projectProcessor.variables['tabletWidthLimit']!.value) {
        return arguments[0];
      } else if (processor.variables['dw']!.value >
              projectProcessor.variables['phoneWidthLimit']!.value ||
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
        FunctionModel<void>('closeDrawer', (arguments, processor) {
      processor.consoleCallback
          .call('api:drawerClose|', arguments: [arguments[0]]);
    }, description: 'open the drawer');
    predefinedFunctions['openEndDrawer'] =
        FunctionModel<void>('openDrawer', (arguments, processor) {
      processor.consoleCallback
          .call('api:drawerEndOpen|', arguments: [arguments[0]]);
    }, description: 'open the drawer');
    predefinedFunctions['closeEndDrawer'] =
        FunctionModel<void>('closeDrawer', (arguments, processor) {
      processor.consoleCallback
          .call('api:drawerEndClose|', arguments: [arguments[0]]);
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
      processor
          .enableError('randInt function need one argument, none were given!');
      return 0;
    }, functionCode: '''
    int randInt(int? max){
    return Random.secure().nextInt(max??100);
    }
    ''', description: 'return a random integer between 0 and max');

    // predefinedFunctions['randomId'] = FunctionModel<String>('randomId', (arguments, processor) {
    //   return randomId;
    // }, functionCode: '''
    // int randInt(int? max){
    // return Random.secure().nextInt(max??100);
    // }
    // ''', description: 'return a random integer between 0 and max');
    predefinedFunctions['jsonEncode'] =
        FunctionModel<String>('jsonEncode', (arguments, processor) {
      if (arguments.length == 1) {
        return jsonEncode(arguments[0]);
      }
      return '';
    }, description: 'encode a json object');

    predefinedFunctions['base64Encode'] =
        FunctionModel<String>('base64Encode', (arguments, processor) {
      if (arguments.length == 1) {
        return base64Encode(arguments[0]);
      }
      return '';
    }, description: 'encode bytes to base64');

    predefinedFunctions['base64Decode'] =
        FunctionModel<Uint8List>('base64Decode', (arguments, processor) {
      if (arguments.length == 1 &&
          (arguments[0] is String) &&
          (arguments[0] as String).isNotEmpty) {
        try {
          return base64Decode(arguments[0]);
        } catch (e) {
          return Uint8List.fromList([]);
        }
      }
      return Uint8List.fromList([]);
    }, description: 'decode base64 to bytes');
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
        FunctionModel<FVBInstance>('randColor', (arguments, processor) {
      return FVBModuleClasses.fvbColorClass.createInstance(processor, [
        Colors.primaries[math.Random().nextInt(Colors.primaries.length)].value
      ]);
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
        stackActionCubit: sl<StackActionCubit>(),
        stateManagementBloc: sl<StateManagementBloc>(),
        arguments: arguments);
    return null;
  }

  static String? testConsoleCallback(String message,
      {List<dynamic>? arguments}) {
    return null;
  }

  static void testOnError(error, line) {
    sl<EventLogBloc>().add(ConsoleUpdatedEvent(
        ConsoleMessage(error.toString(), ConsoleMessageType.error)));
  }

  static void defaultOnError(error, (int, int)? line) {
    if (!disableError) {
      sl<EventLogBloc>().add(ConsoleUpdatedEvent(ConsoleMessage(
          error, ConsoleMessageType.error, line, processComponent)));
    }
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
    return ch == plusCodeUnit ||
        ch == minusCodeUnit ||
        ch == starCodeUnit ||
        ch == forwardSlashCodeUnit ||
        ch == equalCodeUnit ||
        ch == greaterThanCodeUnit ||
        ch == lessThanCodeUnit ||
        ch == empersonCodeUnit ||
        ch == approxCodeUnit ||
        ch == modeleCodeUnit ||
        ch == exclamationCodeUnit ||
        ch == questionMarkCodeUnit ||
        ch == pipeCodeUnit;
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
    if (ch == '%') {
      return 4;
    }
    if (ch == '+' || ch == '-' || ch == '|' || ch == '&' || ch == '!') {
      return 5;
    }
    if (ch == '*' || ch == '/' || ch == '~/') {
      return 6;
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
        (value is! VariableModel) || (!value.uiAttached && value.deletable));
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

  final doublePattern = RegExp(r'^\d+(\\.\d+)?$');

  FVBCacheValue getValue(int index, String variable, config,
      {String? object, Processor? processor}) {
    int? dotIndex;
    if ((dotIndex = variable.lastIndexOf('.')) > 0 &&
        double.tryParse(variable) == null) {
      final temp = variable.substring(0, dotIndex);
      localVariables[kInstance] =
          getValue(index, temp, config, object: object, processor: processor);
      object = kInstance;
      variable = variable.substring(dotIndex + 1);
    }
    if (object?.isNotEmpty ?? false) {
      final cache = getValue(index, object!, config, processor: processor);
      final value = cache.value;
      if (variable == 'runtimeType') {
        return FVBCacheValue(value.runtimeType.toString(), DataType.string);
      }

      /// To bind getters setters, and methods of dart object (i.e. String, int) to constants i.e "abc".toUppercase()
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
      if (value is Processor) {
        return value.getValue(index, variable, config,
            processor: processor ?? this);
      } else if (value is FVBInstance) {
        return value.processor
            .getValue(index, variable, config, processor: processor ?? this);
      } else if (value is FVBClass) {
        return value.getValue(variable, processor ?? this);
      } else if (value is FVBEnum) {
        if (value.values.containsKey(variable)) {
          return FVBCacheValue(
              value.values[variable], DataType.fvbEnumValue(variable));
        }
        throw Exception(
            'Enum "${value.name}" does not contain field $variable');
      } else if (value is FVBEnumValue) {
        if (variable == 'name') {
          return FVBCacheValue(value.name, DataType.string);
        } else if (variable == 'index') {
          return FVBCacheValue(value.index, DataType.fvbInt);
        }
        throw Exception('Variable "$variable" not found in Enum');
      }
      return FVBCacheValue.kNull;
    }
    dynamic v;
    if (variable.contains('[')) {
      return getOrSetListMapBracketValue(index, variable, config,
          processor: processor);
    } else if (variable == 'true') {
      return const FVBCacheValue(true, DataType.fvbBool);
    } else if (variable == 'false') {
      return const FVBCacheValue(false, DataType.fvbBool);
    } else if ((v = int.tryParse(variable)) != null) {
      return FVBCacheValue(v, DataType.fvbInt);
    } else if ((v = double.tryParse(variable)) != null) {
      return FVBCacheValue(v, DataType.fvbDouble);
    } else if (variable == 'this') {
      return FVBCacheValue(parentProcessor!, DataType.fvbDynamic);
    } else if (classes.containsKey(variable)) {
      return FVBCacheValue(classes[variable], DataType.fvbType(variable));
    } else if (enums.containsKey(variable)) {
      return FVBCacheValue(enums[variable], DataType.fvbEnumValue(variable));
    }
    Processor? pointer = this;
    while (pointer != null) {
      if (checkOnlyConfig == null ||
          !checkOnlyConfig!.avoidScopes!.contains(pointer.scopeName)) {
        if (pointer.localVariables.containsKey(variable)) {
          return pointer.localVariables[variable]!;
        } else if (pointer.variables.containsKey(variable)) {
          final model = pointer.variables[variable]!;
          if (model.getCall != null) {
            return FVBCacheValue(
                model.getCall!.call(null, pointer), model.dataType);
          }
          if (model.late && !model.initialized) {
            throw Exception('variable $variable is not initialized');
          }
          return FVBCacheValue(model.value, model.dataType);
        } else if (pointer.functions.containsKey(variable)) {
          return FVBCacheValue(pointer.functions[variable],
              pointer.functions[variable]!.dataType);
        }
      }
      pointer = pointer.parentProcessor;
    }
    for (final package in packages.entries) {
      if (package.value.variables.containsKey(variable)) {
        return package.value.getValue(index, variable, config);
      } else if (package.value.functions.containsKey(variable)) {
        return FVBCacheValue(package.value.functions[variable],
            package.value.functions[variable]!.dataType);
      }
    }
    if (operationType == OperationType.checkOnly &&
        ignoreVariables.containsKey(variable)) {
      return FVBCacheValue(ignoreVariables[variable], DataType.fvbDynamic);
    }
// else if (operationType == OperationType.checkOnly) {
//   showError('Variable $variable not found!!');
//   return null;
// }
    throw Exception('variable "$variable" does not exist!!');
  }

  bool setValue(
      int index, final String variable, dynamic value, ProcessorConfig config,
      {bool isFinal = false,
      bool isStatic = false,
      bool createNew = false,
      String? object,
      DataType? dataType,
      bool nullable = false}) {
    if (declarationMode && !createNew) {
      throw Exception('Cannot set variable $variable in declarative mode');
    }
    if (createNew) {
      if (variable.isEmpty) {
        throw Exception('Variable name not specified');
      }
      if (!CodeOperations.isValidVariableStartingChar(
          variable[0].codeUnits.first)) {
        throw Exception(
            'Invalid variable name starting character, it should be either Alphabet or "_"');
      }
      if (isStatic && scopeName == collection.project!.name) {
        throw Exception('Cannot create a static variable global scope');
      }

      DataType type;
      if (dataType == null ||
          (dataType == DataType.undetermined && value != null)) {
        type = DataTypeProcessor.getDartTypeToDatatype(value);
      } else if (DataTypeProcessor.checkIfValidDataTypeOfValue(
          this, value, dataType, variable, nullable,
          assignedCheck: false)) {
        type = dataType;
      } else {
        return false;
      }
      if (variables.containsKey(variable)) {
        throw Exception('Variable $variable already exists');
      }
      final variableModel = FVBVariable(variable, type,
          nullable: nullable,
          value: value,

// type: dataType == DataType.fvbInstance
//     ? (value as FVBInstance).fvbClass.name
//     : null,
          isFinal: isFinal);
      if (isStatic) {
        staticVariables[variable] = variableModel;
      } else {
        variables[variable] = variableModel;
      }
      return true;
    }
    if (object?.isNotEmpty ?? false) {
      final objectValue = getValue(index, object!, config).value;
      if (objectValue is FVBInstance) {
        objectValue.processor.setValue(index, variable, value, config);
      } else if (objectValue is FVBClass) {
        objectValue.setValue(variable, value);
      }
      return true;
    }
    if (variable.contains('[')) {
      getOrSetListMapBracketValue(index, variable, config, value: value);
      return true;
    }

    Processor? parent = this;
    while (parent != null) {
      if (parent.variables.containsKey(variable)) {
        if (parent.variables[variable]!.dataType == DataType.undetermined ||
            !parent.variables[variable]!.initialized) {
          parent.variables[variable]!.setValue(this, value);
          parent.variables[variable]!.initialized = true;
          parent.variables[variable]!.dataType =
              DataTypeProcessor.getDartTypeToDatatype(value);
          return true;
        } else if (parent.variables[variable]!.isFinal) {
          throw Exception('Cannot change value of final variable $variable');
        } else if (DataTypeProcessor.checkIfValidDataTypeOfValue(
          this,
          value,
          parent.variables[variable]!.dataType,
          variable,
          parent.variables[variable]!.nullable,
        )) {
          parent.variables[variable]!.setValue(this, value);
          return true;
        }
      } else if (parent.localVariables.containsKey(variable)) {
        parent.localVariables[variable] =
            FVBCacheValue(value, parent.localVariables[variable]!.dataType);
        return true;
      }
      parent = parent.parentProcessor;
    }
    throw Exception('Variable $variable not found');
  }

  FVBCacheValue getOrSetListMapBracketValue(
      int index, String variable, ProcessorConfig config,
      {dynamic value, Processor? processor}) {
    /// for list and map with respectively index and key
    int openBracket = variable.indexOf('[');

    if (openBracket != -1) {
      final closeBracket = CodeOperations.findCloseBracket(
          variable, openBracket, squareBracketOpen, squareBracketClose);

      final keyOutput = (processor ?? this).process(
          variable.substring(openBracket + 1, closeBracket),
          index: index + openBracket + 1,
          config: config);
      dynamic key;

      /// TODO(Fix this flow):
      if (operationType == OperationType.checkOnly) {
        key = keyOutput.dataType;
      } else {
        key = keyOutput.value;
      }
      final subVar = variable.substring(0, openBracket);
      if (closeBracket == null) {
        return FVBCacheValue.kNull;
      }
      openBracket = variable.indexOf('[', closeBracket);
      final cache = getValue(index, subVar, config);
      dynamic mapValue = cache.value;
      if (value != null && openBracket == -1) {
        mapValue[key] = value;
        return FVBCacheValue.kNull;
      } else {
        if ((mapValue is Map && mapValue.containsKey(key)) ||
            ((mapValue is List || mapValue is String) &&
                key is int &&
                key < mapValue.length)) {
          mapValue = mapValue[key];
        } else if (Processor.operationType == OperationType.checkOnly) {
          final type = cache.dataType.generics?[0] ?? DataType.fvbDynamic;
          return FVBCacheValue(FVBTest(type, false), type);
        } else {
          return FVBCacheValue.kNull;
        }
      }
      while (openBracket != -1) {
        final closeBracket = CodeOperations.findCloseBracket(
            variable, openBracket, '['.codeUnits.first, ']'.codeUnits.first);
        if (closeBracket == null) {
          return FVBCacheValue.kNull;
        }
        final keyOutput = (processor ?? this).process(
            variable.substring(openBracket + 1, closeBracket),
            index: index + openBracket + 1,
            config: config);
        final key = keyOutput.value;

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
                        ? mapValue.generics.values.first
                        : DataType.fvbDynamic,
                    false),
                DataType.fvbDynamic);
          }
        }
      }
      return FVBCacheValue(mapValue, DataType.fvbDynamic);
    }
    return FVBCacheValue.kNull;
  }

  void processOperator(
      int index,
      final String operator,
      final String object,
      final Stack2<FVBValue> valueStack,
      final Stack2<String> operatorStack,
      ProcessorConfig config) {
    FVBCacheValue? a, b;
    late FVBValue aVar, bVar;
    if (valueStack.isEmpty) {
      throw Exception('ValueStack is Empty, syntax error !!');
    } else {
      bVar = valueStack.pop()!;
      b = bVar.evaluateValue(index, this, config,
          ignoreIfNotExist: bVar.createVar);
    }
    if (operator != '!' && operator != '++' && operator != '--') {
      if (valueStack.isEmpty && operator != '-') {
        throw Exception(
            'Not enough values for operation "$operator" List ${valueStack._list}, syntax error !!');
      } else if ((operator != '-' ||
              valueStack.length > operatorStack.length) &&
          valueStack.isNotEmpty) {
        aVar = valueStack.pop()!;
        if (operator != '=') {
          a = aVar.evaluateValue(index, this, config,
              ignoreIfNotExist: bVar.createVar);
        } else {
          a = null;
        }
      }
    }
    if ((operationType == OperationType.checkOnly) && operator != '=') {
      final outputType = getOperatorOutputType(operator);
      valueStack.push(
          FVBValue(value: FVBTest(outputType, false), dataType: outputType));
      return;
    }
    late dynamic r;
    try {
      switch (operator) {
        case '??':
          r = a?.value ?? b.value;
          break;
        case '--':
        case '+':
          if (operator == '--' && a == null) {
            final v = (bVar.variableName != null
                    ? getValue(index, bVar.variableName!, config,
                            object: bVar.object)
                        .value
                    : bVar.value) -
                1;
            if (bVar.variableName != null) {
              setValue(index, bVar.variableName!, v, config);
            }
            r = v;
            break;
          }
          r = a!.value + b.value;
          break;
        case '-':
          if (a == null) {
            r = -b.value;
          } else {
            r = a.value - b.value;
          }
          break;
        case '*':
          r = a!.value * b.value;
          break;
        case '/':
          r = a!.value / b.value;
          break;
        case '~/':
          r = a!.value ~/ b.value;
          break;
        case '*-':
          r = a!.value * -b.value;
          break;
        case '/-':
          r = a!.value / -b.value;
          break;
        case '%':
          if (a?.value is num && b.value is num) {
            r = a!.value % b.value;
          } else {
            throw Exception('Can not do $a % $b, both are not type of int');
          }
          break;
        case '<':
          r = a!.value < b.value;
          break;
        case '>':
          r = a!.value > b.value;
          break;
        case '>-':
          r = a!.value > -b.value;
          break;
        case '<-':
          r = a!.value < -b.value;
          break;
        case '<=-':
          r = a!.value <= -b.value;
          break;
        case '>=-':
          r = a!.value >= -b.value;
          break;
        case '==-':
          r = a!.value == -b.value;
          break;
        case '!=-':
          r = a!.value != -b.value;
          break;
        case '!':
          r = !b.value;
          break;
        case '=':
          if ((!config.unmodifiable || aVar.createVar) &&
              aVar.variableName != null) {
            setValue(index, aVar.variableName!, b.value, config,
                isFinal: aVar.isVarFinal,
                createNew: aVar.createVar,
                dataType: aVar.dataType,
                isStatic: aVar.static,
                nullable: aVar.nullable,
                object: aVar.object ?? '');
          }
          r = b;
          break;
        case '++':
          final name = bVar.variableName!;
          final value = getValue(index, name, config,
                  processor: parentProcessor, object: bVar.object)
              .value;

          if (value != null) {
            if (!config.unmodifiable) {
              setValue(index, name, value! + 1, config, object: bVar.object);
            }
            r = value! + 1;
          } else {
            throw Exception('Variable $name is not defined');
          }

          break;
        case '+=':
          final name = aVar.variableName!;
          final value =
              getValue(index, name, config, object: aVar.object).value;
          if (value != null) {
            r = value! + b.value;
            if (!config.unmodifiable) {
              setValue(index, name, r, config, object: aVar.object);
            }
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '-=':
          final name = aVar.variableName!;
          final value =
              getValue(index, name, config, object: aVar.object).value;
          if (value != null) {
            if (!config.unmodifiable) {
              setValue(index, name, value! - b, config, object: aVar.object);
            }
            r = value! + b;
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '*=':
          final name = aVar.variableName!;
          final value =
              getValue(index, name, config, object: aVar.object).value;

          if (value != null) {
            if (!config.unmodifiable) {
              setValue(index, name, value! * b, config, object: aVar.object);
            }
            r = value! * b;
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '/=':
          final name = aVar.variableName!;
          final value =
              getValue(index, name, config, object: aVar.object).value;
          if (value != null) {
            if (!config.unmodifiable) {
              setValue(index, name, value! / b, config, object: aVar.object);
            }
            r = value! / b;
          } else {
            throw Exception('Variable $name is not defined');
          }
          break;
        case '<=':
          r = a!.value <= b.value;
          break;
        case '>=':
          r = a!.value >= b.value;
          break;
        case '>>':
          r = a!.value >> b.value;
          break;
        case '<<':
          r = a!.value << b.value;
          break;
        case '&&':
          r = (a!.value as bool) && (b.value as bool);
          break;
        case '||':
          r = (a!.value as bool) || (b.value as bool);
          break;
        case '==':
          r = (a!.value == b.value);
          break;
        case '!=':
          r = a!.value != b.value;
          break;
        case '&':
          r = a!.value & b.value;
          break;
        case '|':
          r = a!.value | b.value;
          break;
        case '^':
          r = a!.value ^ b.value;
          break;
        default:
          throw Exception('Unknown operator $operator');
      }
    } on Exception catch (e) {
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

  String? processString(String code, int index, ProcessorConfig config) {
    int si = -1, ei = -1;

    List<int> startList = [];
    List<int> endList = [];
    List<bool> fullBracketList = [];

    for (int i = 0; i < code.length; i++) {
      if (code.length - 1 > i &&
          code[i] == '\$' &&
          (i - 1 < 0 || code[i - 1] != '\\')) {
        startList.add(i);
        if (code[i + 1] == '{') {
          final close = CodeOperations.findCloseBracket(
              code, i + 1, curlyBracketOpen, curlyBracketClose);
          if (close == null) {
            break;
          }
          endList.add(close);
          i = close;
          fullBracketList.add(true);
        } else {
          int j = i + 1;
          if (code[j].codeUnits.first >= zeroCodeUnit &&
              code[j].codeUnits.first <= nineCodeUnit) {
            throw Exception('Expected an Identifier');
          }
          while (j < code.length &&
              CodeOperations.isVariableChar(code[j].codeUnits.first)) {
            j++;
          }
          endList.add(j);
          fullBracketList.add(false);
        }
      }
    }
    if (startList.length != endList.length) {
      throw Exception('Invalid syntax in string');
    }
    while (startList.isNotEmpty) {
      si = startList.removeAt(0);
      ei = endList.removeAt(0);
      final fullBracket = fullBracketList.removeAt(0);
      if (fullBracket) {
        if (si + 2 == ei) {
          throw Exception('invalid syntax in \${ and } !!');
// return CodeOutput.right('No variables');
        }
        if (ei > code.length) {
          throw Exception('Not enough characters in string');
        }
      } else {
        if (si + 1 == ei) {
          throw Exception('invalid syntax after \$');
// return CodeOutput.right('No variables');
        }
        if (ei > code.length) {
          throw Exception('Not enough characters in string');
        }
      }
      final variableName = code.substring(fullBracket ? si + 2 : si + 1, ei);
      final valueOutput = process(variableName,
          index: index + si + 2,
          resolve: true,
          suggestionSetting: ProcessSuggestionSetting(
              restricted: (!fullBracket)
                  ? ([
                      SuggestionType.variable,
                      SuggestionType.localVariable,
                      SuggestionType.staticVar,
                      SuggestionType.argument,
                      SuggestionType.valueKeyword,
                      SuggestionType.builtInVar
                    ])
                  : null),
          config: config);
      final value = valueOutput.value;
      if (value is FVBUndefined) {
        throw Exception('undefined ${value..varName}');
      }
      final k1 =
          fullBracket ? '$openInt$variableName$closeInt' : '\$$variableName';
      final v1 = value.toString();
      code = code.replaceAll(k1, v1);
      for (int i = 0; i < startList.length; i++) {
        startList[i] += v1.length - k1.length;
        endList[i] += v1.length - k1.length;
      }
    }
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < code.length; i++) {
      if (code[i] == '\\') {
        if (i + 1 < code.length) {
          if (code[i + 1] == '\$') {
            buffer.write(code[i + 1]);
            i = i + 1;
          } else if (code[i + 1] == 'n') {
            buffer.write('\n');
            i = i + 1;
          } else if (code[i + 1] == '\\') {
            buffer.write('\\');
            if (code.length > i + 2) {
              buffer.write(code[i + 2]);
              i = i + 2;
            } else {
              i = i + 1;
            }
          }
        } else {
          throw Exception('Unexpected end after backslash');
        }
      } else {
        buffer.write(code[i]);
      }
    }
    return buffer.toString();
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

  void callConstructor(int index, Map<String, String> arguments,
      Map<String, DataType> generics, Processor processor,
      {required ProcessorConfig config}) {
    if (functions.containsKey(scopeName)) {
      try {
        final fun = functions[scopeName]!;
        final args = ArgumentProcessor.process(
            fun,
            index,
            processor,
            fun.arguments
                .map((e) => arguments[e.argName] ?? '')
                .toList(growable: false),
            generics,
            config);
        if (Processor.error) {
          return;
        }
        functions[scopeName]!.execute(this, null, args, config: config);
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
      VoidCallback? onExecutionStart,
      ProcessorConfig? config}) {
    final code = cleanCode(input, this);
    if (code == null) {
      return null;
    }
    if (oldCode == code) {
      return code;
    }

    onExecutionStart?.call();
    error = false;
    operationType = type;
    finished = false;
    final codeCount = lastCodeCount;
    if (isSuggestionEnable) {
      lastCodeCount = 0;
    }

    cacheMemory = CacheMemory(this);
    onExecutionStart?.call();
    execute<T>(code, 0,
        declarativeOnly: declarativeOnly,
        givenConfig: config ?? const ProcessorConfig());

    if (codeCount > lastCodeCount) {
      for (int i = 0; i < codeCount - lastCodeCount; i++) {
        lastCodes.removeLast();
      }
    }
    return code;
  }

  static String? cleanCode(String input, Processor processor) {
    String trimCode = '';
    bool commentOpen = false;
    for (String line in input.split('\n')) {
      int index = -1;
      bool openSingleQuote = false, openDoubleQuote = false;
      for (int i = 0; i < line.length; i++) {
        final noBackslash = i == 0 || line[i - 1] != '\\';
        if (!openSingleQuote && line[i] == '"' && noBackslash) {
          openDoubleQuote = !openDoubleQuote;
        } else if (!openDoubleQuote && line[i] == '\'' && noBackslash) {
          openSingleQuote = !openSingleQuote;
        } else if (!openSingleQuote &&
            !openDoubleQuote &&
            i + 1 < line.length) {
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

  dynamic executeAsync<T>(final String trimCode,
      {bool declarativeOnly = false,
      bool returnOutput = false,
      required ProcessorConfig config}) async {
    final oldDeclarativeMode = declarationMode;
    declarationMode = declarativeOnly;
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
        final outputCache = process<T>(
          code,
          index: lastPoint,
          config: config,
        );
        final output = outputCache.value;
        if (output is FVBFuture) {
          final asyncOutput = process(output.asynCode.$1,
              index: output.asynCode.$2, config: config);

          /// Handling FVBTest for IDE based execution for suggestions
          if (asyncOutput.dataType.name == 'Future') {
            output.values.push(FVBValue(
                value: FVBTest(asyncOutput.dataType.generics![0], true),
                dataType: asyncOutput.dataType.generics![0]));
          } else if (asyncOutput.value is FVBInstance &&
              asyncOutput.value.fvbClass.name == 'Future') {
            if (operationType == OperationType.regular) {
              final future = await (asyncOutput.value.variables['future']!.value
                  as Future);
              output.values.push(FVBValue(
                  value: future,
                  dataType: DataType.future(
                      asyncOutput.value.generics.values.first)));
            } else {
              output.values.push(FVBValue(
                  value:
                      FVBTest(asyncOutput.value.generics.values.first, false),
                  dataType: asyncOutput.value.generics.values.first));
            }
          }
          process('',
              oldValueStack: output.values,
              oldOperatorStack: output.operators,
              config: config,
              index: lastPoint);
        }

        lastPoint = i + 1;
        if (error) {
          if (!isSuggestionEnable) {
            break;
          }
        }
        globalOutput = output;

        if (output is FVBContinue ||
            output is FVBBreak ||
            output is FVBReturn) {
          declarationMode = oldDeclarativeMode;
          return output;
        }
        if (finished) {
          break;
        }
      }
    }

    declarationMode = oldDeclarativeMode;
    if (returnOutput) return globalOutput;
  }

  dynamic execute<T>(final String trimCode, int startIndex,
      {bool declarativeOnly = false,
      bool returnOutput = false,
      required ProcessorConfig givenConfig}) {
    final oldDeclarativeMode = declarationMode;
    declarationMode = declarativeOnly;
    int count = 0;
    int lastPoint = 0;
    final config = givenConfig.copyWith(functions: [], classes: []);
    dynamic globalOutput;
    for (int i = 0; i < trimCode.length; i++) {
      if (trimCode[i] == '{' || trimCode[i] == '[' || trimCode[i] == '(') {
        count++;
      } else if (trimCode[i] == '}' ||
          trimCode[i] == ']' ||
          trimCode[i] == ')') {
        count--;
      }
      if (count == 0 && (trimCode.length == i + 1 || trimCode[i] == ';')) {
        final endIndex = trimCode[i] == ';' ? i : i + 1;
        final code = trimCode.substring(lastPoint, endIndex);
        final outputCache = process<T>(
          code,
          index: startIndex + lastPoint,
          config: config,
        );
        final output = outputCache.value;
        if ((trimCode[i] != '}' && trimCode[i] != ';') &&
            !config.singleLineProcess) {
          enableError('Missing ";"', (startIndex + i, startIndex + i + 1));
        }
        if (output is FVBFuture) {
          enableError(
              'can not use await in sync code, put "async" before opening curly-brace "${output.asynCode}"');
          return;
        }

        if (error) {
          enableError(
              errorMessage, (startIndex + lastPoint, startIndex + endIndex));
          if (!isSuggestionEnable) {
            break;
          }
        }
        lastPoint = i + 1;
        globalOutput = output;

        if (outputCache is FVBReturn) {
          declarationMode = oldDeclarativeMode;
          return outputCache;
        }
        if (output is FVBContinue || output is FVBBreak) {
          declarationMode = oldDeclarativeMode;
          return output;
        }
        if (finished) {
          break;
        }
      }
    }
    if (Processor.operationType == OperationType.checkOnly) {
      try {
        for (final function in config.functions ?? []) {
          function.execute(
              this,
              null,
              function.arguments
                  .map((e) => FVBTest(e.dataType, e.nullable))
                  .toList(growable: false),
              config: const ProcessorConfig(unmodifiable: false));
        }
      } on Exception catch (e) {
        enableError(e.toString());
      }
    }
    declarationMode = oldDeclarativeMode;
    if (returnOutput) return globalOutput;
  }

  dynamic cleanAndExecute(String code) {
    if (Processor.error) {
      return;
    }
    final clean = CodeOperations.trim(code);
    if (clean == null) {
      enableError('Error while cleaning code');
      return null;
    }
    final value =
        process(clean, index: 0, config: const ProcessorConfig()).value;
    return value;
  }

  FVBCacheValue process<T>(final String input,
      {bool resolve = false,
      int index = 0,
      Stack2<FVBValue>? oldValueStack,
      Stack2<String>? oldOperatorStack,
      required ProcessorConfig config,
      String extendedError = '',
      bool suggestion = true,
      ProcessSuggestionSetting? suggestionSetting}) {
    int editIndex = -1;
    if (isSuggestionEnable && suggestion) {
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
            editIndex = input.length - 1;
          }
        }
        lastCodes[lastCodeCount] = input;
      }
      lastCodeCount++;
    }
    try {
      if (T == String || T == FVBImage) {
        return FVBCacheValue(
            processString(input, index, config), DataType.string);
      } else if (T == Color && input.startsWith('#')) {
        return FVBCacheValue(input, DataType.string);
      }
      // if (error) {
      //   return FVBCacheValue.kNull;
      // }
      final Stack2<FVBValue> valueStack = oldValueStack ?? Stack2<FVBValue>();
      final Stack2<String> operatorStack = oldOperatorStack ?? Stack2<String>();
      bool stringOpen = false;
      bool doubleQuote = false;
      int stringCount = 0;
      String variable = '';
      String object = '';
      bool isNumber = true;
      final inputCodeUnits = input.codeUnits;
      for (int currentIndex = 0; currentIndex < input.length; currentIndex++) {
        final String nextToken = input[currentIndex];
        final ch = nextToken.codeUnits.first;
        if (stringOpen) {
          final noBackslash = currentIndex == 0 || ch != backslashCodeUnit;
          if (noBackslash &&
              stringCount == 0 &&
              ((ch == doubleQuoteCodeUnit && doubleQuote) ||
                  (!doubleQuote && ch == singleQuoteCodeUnit))) {
            stringOpen = !stringOpen;
            if (currentIndex - variable.length - 1 >= 0 &&
                (inputCodeUnits[currentIndex - variable.length - 1] ==
                        doubleQuoteCodeUnit ||
                    inputCodeUnits[currentIndex - variable.length - 1] ==
                        singleQuoteCodeUnit)) {
              valueStack.push(FVBValue.string(
                processString(variable, index + currentIndex, config),
              ));
              variable = '';
              continue;
            } else {
              return FVBCacheValue.kNull;
            }
          } else if (currentIndex + 1 < input.length &&
              ch == dollarCodeUnit &&
              inputCodeUnits[currentIndex + 1] == curlyBracketOpen) {
            stringCount++;
          } else if (stringCount > 0 && ch == curlyBracketClose) {
            stringCount--;
          }
          if (!noBackslash && currentIndex > 0) {
            variable = variable.substring(0, variable.length - 1);
          }
          variable += nextToken;

          continue;
        } else if (ch == doubleQuoteCodeUnit || ch == singleQuoteCodeUnit) {
          isNumber = false;
          stringOpen = true;
          doubleQuote = (ch == doubleQuoteCodeUnit);
        }

        /// List initialization
        else if (ch == squareBracketOpen) {
          int count = 0;

          for (int i = currentIndex + 1; i < input.length; i++) {
            if (inputCodeUnits[i] == squareBracketClose && count == 0) {
              final substring = input.substring(currentIndex + 1, i);
              if (!substring.contains(',') &&
                  (valueStack.peek?.value is List ||
                      valueStack.peek?.value is Map)) {
                final output =
                    process(substring, index: index + i, config: config);
                final lastValue = valueStack.pop()!;
                valueStack.push(FVBValue(
                    value: lastValue.value[output.value],
                    dataType: (lastValue.dataType?.isMap ?? false) &&
                            (lastValue.dataType!.generics?.length == 2)
                        ? lastValue.dataType!.generics![1]
                        : null));
                currentIndex = i;
                break;
              } else if (variable.isNotEmpty) {
                variable = '$variable[$substring]';
                currentIndex = i;
                break;
              } else {
                final values = CodeOperations.splitBy(substring).map((e) {
                  final cache = process(e, index: index + i, config: config);
                  return cache.value;
                }).toList();
                final dataTypes = <DataType>{};
                for (final v in values) {
                  dataTypes.add(DataTypeProcessor.getDartTypeToDatatype(v));
                }
                final value = FVBValue(
                  value: values,
                  dataType:
                      DataType.list(DataTypeProcessor.compatible(dataTypes)),
                );
                valueStack.push(
                  value,
                );
                variable = '';
                object = kInstance;
                isNumber = false;
                localVariables[object] = value.cacheValue;
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
                input, currentIndex, curlyBracketOpen, curlyBracketClose);
            if (closeCurlyBracket == null) {
              return FVBCacheValue.kNull;
            }
            final Processor processor = Processor(
                scope: Scope.object,
                consoleCallback: consoleCallback,
                onError: onError,
                scopeName: className,
                onSuggestions: onSuggestions);
            processor.execute(
                input.substring(currentIndex + 1, closeCurlyBracket),
                currentIndex + 1,
                declarativeOnly: true,
                givenConfig: currentConfig.copyWith());

            /// Creating new Class, to analyze code of class, we need to create new Processor which
            /// will compile class declaration part and then we will take that [functions] and [variables]
            /// to FVBClass

            final newClass = classes[className] = FVBClass(
              className,
              fvbFunctions: processor.functions,
              fvbVariables: Map.fromEntries(processor.variables.entries.map(
                  (entry) => MapEntry(entry.key, () => entry.value.clone()))),
              parent: this,
              fvbStaticVariables: processor.staticVariables,
              fvbStaticFunctions: processor._staticFunctions,
            );

            /// Testing functions/static functions for error-check and suggestions.
            /// TODO:(HandleViaProcessorConfigAnalyzerFlag)
            if (operationType == OperationType.checkOnly) {
              for (final function in newClass.fvbFunctions.values.toList()) {
                function.execute(
                    processor,
                    null,
                    function.arguments
                        .map((e) => FVBTest(e.dataType, e.nullable))
                        .toList(growable: false),
                    config: const ProcessorConfig(unmodifiable: false));
              }

              for (final function
                  in newClass.fvbStaticFunctions?.values.toList() ?? []) {
                function.execute(
                    this,
                    null,
                    function.arguments
                        .map((e) => FVBTest(e.dataType, e.nullable))
                        .toList(growable: false),
                    config: const ProcessorConfig(unmodifiable: false));
              }
            }
            config.classes?.add(newClass);
            currentIndex = closeCurlyBracket;
            variable = '';
            continue;
          } else if (variable.isNotEmpty && variable.startsWith('enum$space')) {
            final name = variable.substring(5);
            final closeCurlyBracket = CodeOperations.findCloseBracket(
                input, currentIndex, curlyBracketOpen, curlyBracketClose);
            if (closeCurlyBracket == null) {
              return FVBCacheValue.kNull;
            }
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
              if (inputCodeUnits[i] == curlyBracketClose && count == 0) {
                final map = Map.from(
                  CodeOperations.splitBy(input.substring(currentIndex + 1, i))
                      .asMap()
                      .map((e, n) {
                    final split =
                        CodeOperations.splitBy(n, splitBy: colonCodeUnit);
                    if (split.length != 2) {
                      if (operationType == OperationType.checkOnly) {
                        for (final element in split) {
                          process(element, config: config);
                        }
                      }

                      throw Exception('Invalid map entry');
                    }
                    final keyOut = process(
                      split[0],
                      index: index + i,
                      config: config,
                    );
                    final valueOut =
                        process(split[1], index: index + i, config: config);
                    return MapEntry(keyOut.value, valueOut.value);
                  }),
                );
                valueStack.push(
                  FVBValue(
                      value: map,
                      dataType: DataType.map(
                          [DataType.fvbDynamic, DataType.fvbDynamic])),
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
            ch == spaceReplacementCodeUnit) {
          if (ch == questionMarkCodeUnit) {
            if (currentIndex + 1 < input.length &&
                input[currentIndex + 1] == '?') {
              finishProcessing(currentIndex + 1, variable, '??', object,
                  operatorStack, valueStack, config.unmodifiable, config);
              operatorStack.push('??');
              variable = '';
              object = '';
              currentIndex++;
              continue;
            }
            final colonIndex = CodeOperations.findChar(
                input, currentIndex, colonCodeUnit, [spaceReplacementCodeUnit]);

            if (colonIndex != -1) {
              int index = CodeOperations.findChar(input, colonIndex + 1,
                  ','.codeUnits.first, [spaceReplacementCodeUnit]);
              if (index == -1) {
                index = input.length;
              }
              finishProcessing(currentIndex + 1, variable, '?', object,
                  operatorStack, valueStack, config.unmodifiable, config);
// operatorStack.push('?');
              final poppedValue = valueStack
                  .pop()
                  ?.evaluateValue(currentIndex + 1 + index, this, config);
              if (poppedValue?.value == true) {
                valueStack.push(FVBValue.fromCache(process(
                    input.substring(currentIndex + 1, colonIndex),
                    index: currentIndex + 1,
                    config: config)));
              } else {
                valueStack.push(FVBValue.fromCache(
                  process(input.substring(colonIndex + 1, index),
                      index: colonIndex + 1, config: config),
                ));
              }
              currentIndex = index;
              variable = '';
              object = '';
              continue;
            }
          } else if ((ch >= zeroCodeUnit && ch <= nineCodeUnit) &&
              variable.codeUnits.every((element) =>
                  (element >= zeroCodeUnit && element <= nineCodeUnit) ||
                  element == dotCodeUnit)) {
            isNumber = true;
          } else {
            isNumber = false;
          }
          if (ch == spaceReplacementCodeUnit) {
            if (variable == 'await') {
              return FVBCacheValue(
                  FVBFuture(valueStack, operatorStack, (
                    input.substring(currentIndex + 1),
                    index + currentIndex + 1
                  )),
                  DataType.future());
            } else if (variable == 'return') {
              final returnValue = process(input.substring(currentIndex + 1),
                  index: currentIndex + 1, config: config);
              return FVBReturn.fromCache(returnValue);
            }
          }
          variable += nextToken;
          if (editIndex == currentIndex && isSuggestionEnable) {
            if (variable.contains('.')) {
              final i = variable.indexOf('.');
              _handleVariableAndFunctionSuggestions(
                  editIndex,
                  variable.substring(i + 1),
                  variable.substring(0, i),
                  valueStack,
                  suggestionSetting,
                  config);
            } else {
              _handleVariableAndFunctionSuggestions(editIndex, variable, object,
                  valueStack, suggestionSetting, config);
            }
          }
        } else if (ch == dotCodeUnit) {
          if (isNumber && !variable.contains(input[currentIndex])) {
            variable += nextToken;
            if (currentIndex + 1 == input.length) {
              if (editIndex == currentIndex && isSuggestionEnable) {
                _handleVariableAndFunctionSuggestions(
                    editIndex,
                    '',
                    variable.substring(0, variable.length - 1),
                    valueStack,
                    suggestionSetting,
                    config);
              }
              throw Exception('Expected an Identifier');
            }
            continue;
          }
          if (object.isNotEmpty && variable.isNotEmpty) {
            final cache = getValue(index + currentIndex, object, config);
            final obj = cache.value;

            if (obj is FVBInstance) {
              object = kInstance;
              localVariables[object] = obj.processor.getValue(
                  index + currentIndex, variable, config,
                  processor: this);
            } else if (obj is FVBClass) {
              object = kInstance;
              localVariables[object] = obj.getValue(variable, this);
            } else {
              localVariables[kInstance] = getValue(
                  index + currentIndex, variable, config,
                  object: object, processor: this);
              object = kInstance;
            }
            variable = '';
            if (editIndex == currentIndex && onSuggestions != null) {
              _handleVariableAndFunctionSuggestions(editIndex, variable, object,
                  valueStack, suggestionSetting, config);
            }
            if (currentIndex + 1 == input.length) {
              throw Exception('Expected an Identifier');
            }
            continue;
          } else if (variable.isNotEmpty) {
            object = variable;
            variable = '';
            if (editIndex == currentIndex && onSuggestions != null) {
              _handleVariableAndFunctionSuggestions(editIndex, variable, object,
                  valueStack, suggestionSetting, config);
            }
            if (currentIndex + 1 == input.length) {
              throw Exception('Expected an Identifier');
            }
            continue;
          } else if (valueStack.isNotEmpty) {
            variable = kInstance;
            localVariables[variable] = valueStack.pop()!.cacheValue;
            object = variable;
            variable = '';
            if (editIndex == currentIndex && onSuggestions != null) {
              _handleVariableAndFunctionSuggestions(editIndex, variable, object,
                  valueStack, suggestionSetting, config);
            }
            if (currentIndex + 1 == input.length) {
              throw Exception('Expected an Identifier');
            }
            continue;
          } else {
            throw Exception('Expected an Identifier');
          }
        } else {
          /// Functions corner
          /// Condition 1 :: Variable is Not Empty
          if (variable.isNotEmpty && ch == '('.codeUnits[0]) {
            if (variable.contains('.')) {
              int i = variable.indexOf('.');
              object = variable.substring(0, i);
              variable = variable.substring(i + 1);
            }
            final int? closeRoundBracket = CodeOperations.findCloseBracket(
                input, currentIndex, '('.codeUnits.first, ')'.codeUnits.first);
            if (closeRoundBracket == null) {
              return FVBCacheValue.kNull;
            }
            if (variable == 'for') {
              if (declarationMode) {
                throw Exception('for is not allowed in declarative mode');
              }
              int? endIndex = CodeOperations.findCloseBracket(
                  input,
                  closeRoundBracket + 1,
                  '{'.codeUnits.first,
                  '}'.codeUnits.first);
              if (endIndex == null) {
                return FVBCacheValue.kNull;
              }
              final insideFor =
                  input.substring(currentIndex + 1, closeRoundBracket);
              final innerCode =
                  input.substring(closeRoundBracket + 2, endIndex);
              final splits =
                  CodeOperations.splitBy(insideFor, splitBy: semiColonCodeUnit);
              if (splits.length != 3) {
                if (insideFor.contains(':')) {
                  final split =
                      CodeOperations.splitBy(insideFor, splitBy: colonCodeUnit);
                  final listOutput = process(split[1],
                      index: currentIndex + 1 + split[0].length,
                      config: config);
                  final list = listOutput.value;
                  final variable = DataTypeProcessor.getFVBValueFromCode(
                      split[0], classes, enums);
                  if (variable == null) {
                    throw Exception('Invalid variable declaration in for-each');
                  }
                  if (list is! Iterable) {
                    throw Exception('Invalid for each loop');
                  } else {
                    if (operationType == OperationType.regular) {
                      final processor =
                          Processor.build(name: 'For-each', parent: this);
                      for (final item in list) {
                        processor.variables.clear();
                        processor.localVariables.clear();
                        processor.localVariables[variable.variableName!] =
                            FVBCacheValue(
                                item, variable.dataType ?? DataType.fvbDynamic);
                        final output = processor.execute(
                            innerCode, closeRoundBracket + 2,
                            givenConfig: config);
                        if (output is FVBBreak || error || finished) {
                          break;
                        }
                      }
                    } else if (operationType == OperationType.checkOnly) {
                      localVariables[variable.variableName!] = FVBCacheValue(
                          list.isNotEmpty
                              ? list.first
                              : FVBTest(variable.dataType!, false),
                          variable.dataType!);
                      execute(innerCode, closeRoundBracket + 2,
                          givenConfig: config);
                      localVariables.remove(variable.variableName!);
                    }
                  }
                } else {
                  if (operationType == OperationType.checkOnly) {
                    execute(insideFor, closeRoundBracket + 2,
                        givenConfig: config);
                  }
                  throw Exception('For loop syntax error');
                }
              } else {
                process(splits[0], index: currentIndex + 1, config: config);
                int count = 0;
                if (operationType == OperationType.regular) {
                  while (process(splits[1],
                              index: currentIndex + 1 + splits[0].length,
                              config: config)
                          .value ==
                      true) {
                    final output = execute(innerCode, closeRoundBracket + 2,
                        givenConfig: config);
                    if (output is FVBBreak || error || finished) {
                      break;
                    }
                    process(splits[2],
                        index: currentIndex +
                            1 +
                            splits[0].length +
                            splits[1].length,
                        config: config);

                    count++;
                    if (count > 1000000) {
                      throw Exception('For loop goes infinite!!');
                    }
                  }
                } else {
                  final i1 = currentIndex + 1 + splits[0].length;
                  process(splits[1], index: i1, config: config);
                  execute(innerCode, closeRoundBracket + 2,
                      givenConfig: config);
                  process(splits[2],
                      index: i1 + splits[1].length, config: config);
                }
              }
              variable = '';
              currentIndex = endIndex;
              continue;
            }
            final argumentList = CodeOperations.splitBy(
                input.substring(currentIndex + 1, closeRoundBracket));
            if (variable == 'switch') {
              if (declarationMode) {
                throw Exception(
                    'Switch statement is not allowed in declarative mode');
              }
              final valueCache = process(argumentList[0],
                  index: currentIndex + 1, config: config);
              final value = valueCache.value;
              int? endBracket = CodeOperations.findCloseBracket(
                  input,
                  closeRoundBracket + 1,
                  '{'.codeUnits.first,
                  '}'.codeUnits.first);
              if (endBracket == null) {
                return FVBCacheValue.kNull;
              }
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
                      splitBy: colonCodeUnit,
                    );
                    list.add(CaseStatement((split[0], caseIndex),
                        (split[1], caseIndex + split[0].length)));
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
                    splitBy: colonCodeUnit);
                if (split.length == 2) {
                  list.add(CaseStatement((split[0], caseIndex),
                      (split[1], caseIndex + split[0].length)));
                }
              }
              if (defaultIndex != -1) {
                list.add(
                  CaseStatement(null, (
                    innerCode.substring(defaultIndex + 8),
                    defaultIndex + 8
                  )),
                );
              }

              currentIndex = endBracket;
              variable = '';
              bool isTrue = false;
              for (final statement in list) {
                if (operationType == OperationType.checkOnly) {
                  if (statement.condition != null) {
                    process(statement.condition!.$1,
                        index: statement.condition!.$2, config: config);
                  }
                  execute(statement.body.$1, statement.body.$2,
                      givenConfig: config);
                  continue;
                }
                if (statement.condition == null) {
                  execute(statement.body.$1, statement.body.$2,
                      givenConfig: config);
                  break;
                } else if (process(statement.condition!.$1,
                                index: statement.condition!.$2, config: config)
                            .value ==
                        value ||
                    isTrue) {
                  final value = execute(statement.body.$1, statement.body.$2,
                      givenConfig: config);
                  isTrue = true;
                  if (value is FVBBreak) {
                    break;
                  }
                }
              }
              continue;
            }

            /// Constructor Corner
            /// Named and Normal Constructors
            else if (declarationMode &&
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
                if (closeCurlyBracket == null) {
                  return FVBCacheValue.kNull;
                }
                body =
                    input.substring(closeRoundBracket + 2, closeCurlyBracket);
                currentIndex = closeCurlyBracket;
              } else {
                body = '';
                currentIndex = closeRoundBracket;
              }
              final argumentList = CodeOperations.splitBy(
                  input.substring(openRoundBracket + 1, closeRoundBracket));
              functions[variable] = FVBFunction(
                  variable,
                  body,
                  processArgDefinitionList(
                      index + currentIndex, argumentList, config,
                      variables: variables));
              variable = '';
              object = '';
              continue;
            }

            /// Call named constructor
            else if (classes.containsKey(object) &&
                classes[object]!
                    .fvbFunctions
                    .containsKey('$object.$variable')) {
              final fvbClass = classes[object]!;
              final constructorName = '$object.$variable';
              final args = processArgList(
                  index + currentIndex,
                  fvbClass.fvbFunctions[constructorName]!,
                  argumentList,
                  {},
                  config);
              valueStack.push(
                FVBValue(
                    value: fvbClass.createInstance(
                      this,
                      args,
                      constructorName: '$object.$variable',
                    ),
                    dataType: DataType.fvbInstance(fvbClass.name)),
              );
              variable = '';
              object = '';
              currentIndex = closeRoundBracket;
              continue;
            }

            /// Simple constructor
            else if (classes.containsKey(variable)) {
              final fvbClass = classes[variable]!;
              final arguments = fvbClass.fvbFunctions.containsKey(variable)
                  ? processArgList(
                      index + currentIndex,
                      fvbClass.fvbFunctions[variable]!,
                      argumentList,
                      {},
                      config)
                  : [];
              valueStack.push(FVBValue(
                value: fvbClass.createInstance(this, arguments),
                dataType: DataType.fvbInstance(fvbClass.name),
              ));
              variable = '';
              currentIndex = closeRoundBracket;
              continue;
            } else if (!declarationMode &&
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
                function.execute(
                    processorMap[object]!,
                    null,
                    processArgList(index + currentIndex, function, argumentList,
                        {}, config),
                    config: config);
              } else {
                final processor = processorMap[variable];
                function = processor!.functions[variable];
                if (function != null) {
                  function.execute(
                      processor,
                      null,
                      processArgList(index + currentIndex, function,
                          argumentList, {}, config),
                      config: config);
                } else {
                  throw Exception(
                      'No constructor $variable found in class $variable');
                }
              }
            } else if (object.isNotEmpty) {
              /// Object dot function is called.
              final cache = getValue(index + currentIndex, object, config);
              var objectInstance = cache.value;
              if (operationType == OperationType.checkOnly) {
                objectInstance = FVBTest(cache.dataType, true,
                    fvbClass: cache.value is FVBInstance
                        ? cache.value.fvbClass
                        : null);
              }
              if (objectInstance is FVBInstance || objectInstance is FVBClass) {
                final function = objectInstance is FVBInstance
                    ? objectInstance.getFunction(this, variable)
                    : (objectInstance as FVBClass).getFunction(this, variable);
                if (function == null) {
                  throw Exception(
                      'Function "$variable" not found in class $object');
                }

                final processedArgs = processArgList(
                    index + currentIndex,
                    function,
                    argumentList,
                    objectInstance is FVBInstance
                        ? objectInstance.generics
                        : {},
                    config);
                final dynamic output;
                if (objectInstance is FVBInstance) {
                  output = objectInstance.executeFunction(
                      variable, processedArgs, config);
                } else {
                  output = (objectInstance as FVBClass)
                      .executeFunction(this, variable, processedArgs, config);
                }
                valueStack.push(FVBValue(
                  value: output,
                  dataType: objectInstance is FVBInstance
                      ? DataType.fvbInstance(objectInstance.fvbClass.name)
                      : DataType.fvbType((objectInstance as FVBClass).name),
                ));
              } else {
                _handleObjectMethods(index + currentIndex, objectInstance,
                    variable, argumentList, valueStack, config);
              }
              variable = '';
              object = '';
              currentIndex = closeRoundBracket;
              continue;
            } else if (variable == 'while') {
              if (declarationMode) {
                throw Exception(
                    'While statement is not allowed in declarative mode');
              }
              int? endIndex = CodeOperations.findCloseBracket(
                  input,
                  closeRoundBracket + 1,
                  '{'.codeUnits.first,
                  '}'.codeUnits.first);
              if (endIndex == null) {
                return FVBCacheValue.kNull;
              }
              final innerCode =
                  input.substring(closeRoundBracket + 2, endIndex);
              final conditionalCode =
                  input.substring(currentIndex + 1, closeRoundBracket);
              int count = 0;
              while (process(conditionalCode,
                          index: currentIndex + 1, config: config)
                      .value ==
                  true) {
                final output = execute(innerCode, closeRoundBracket + 2,
                    givenConfig: config);
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
              if (declarationMode) {
                throw Exception(
                    'If statement is not allowed in declarative mode');
              }
              final List<ConditionalStatement> conditionalStatements = [];
              if (closeRoundBracket + 1 < input.length &&
                  input[closeRoundBracket + 1] == '{') {
                int? endBracket = CodeOperations.findCloseBracket(
                    input,
                    closeRoundBracket + 1,
                    '{'.codeUnits.first,
                    '}'.codeUnits.first);
                if (endBracket == null) {
                  return FVBCacheValue.kNull;
                }
                conditionalStatements.add(ConditionalStatement((
                  argumentList[0],
                  currentIndex + 1
                ), (
                  input.substring(closeRoundBracket + 2, endBracket),
                  closeRoundBracket + 2
                )));
                currentIndex = endBracket;
                while (input.length > endBracket! + 7 &&
                    input.substring(endBracket + 1, endBracket + 5) == 'else') {
                  int startBracket = endBracket + 6;
                  if (input.substring(startBracket, endBracket + 8) == 'if') {
                    startBracket += 2;
                    int? endRoundBracket = CodeOperations.findCloseBracket(
                        input,
                        startBracket,
                        '('.codeUnits.first,
                        ')'.codeUnits.first);
                    if (endRoundBracket == null) {
                      return FVBCacheValue.kNull;
                    }
                    endBracket = CodeOperations.findCloseBracket(
                        input,
                        endRoundBracket + 1,
                        '{'.codeUnits.first,
                        '}'.codeUnits.first);
                    if (endBracket == null) {
                      return FVBCacheValue.kNull;
                    }
                    conditionalStatements.add(ConditionalStatement(
                      (
                        input.substring(startBracket + 1, endRoundBracket),
                        startBracket + 1
                      ),
                      (
                        input.substring(endRoundBracket + 2, endBracket),
                        endRoundBracket + 2
                      ),
                    ));
                    currentIndex = endBracket;
                  } else {
                    startBracket = endBracket + 5;
                    endBracket = CodeOperations.findCloseBracket(input,
                        startBracket, '{'.codeUnits.first, '}'.codeUnits.first);
                    if (endBracket == null) {
                      return FVBCacheValue.kNull;
                    }
                    conditionalStatements.add(
                      ConditionalStatement(
                        null,
                        (
                          input.substring(startBracket + 1, endBracket),
                          startBracket + 1
                        ),
                      ),
                    );
                    currentIndex = endBracket;
                    break;
                  }
                }
              } else if (operationType == OperationType.checkOnly &&
                  argumentList.isNotEmpty) {
                execute(argumentList[0], currentIndex + 1,
                    givenConfig: config.copyWith(singleLineProcess: true));
              }
              for (final statement in conditionalStatements) {
                if (operationType == OperationType.checkOnly) {
                  if (statement.condition != null) {
                    process(statement.condition!.$1,
                        index: statement.condition!.$2, config: config);
                  }
                  execute(statement.body.$1, statement.body.$2,
                      givenConfig: config);
                  continue;
                }
                if (statement.condition == null) {
                  final output = execute(statement.body.$1, statement.body.$2,
                      givenConfig: config);
                  if (output != null) {
                    valueStack.push(FVBValue(value: output));
                  }
                  break;
                } else if (process(
                      statement.condition!.$1,
                      index: statement.condition!.$2,
                      config: config,
                    ).value ==
                    true) {
                  final output = execute(statement.body.$1, statement.body.$2,
                      givenConfig: config);
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

              final int? closeBracketIndex = CodeOperations.findCloseBracket(
                  input,
                  isAsync ? closeRoundBracket + 6 : closeRoundBracket + 1,
                  '{'.codeUnits.first,
                  '}'.codeUnits.first);
              if (closeBracketIndex == null) {
                return FVBCacheValue.kNull;
              }
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
                  async: isAsync,
                  config,
                  isAsync ? closeRoundBracket + 7 : closeRoundBracket + 2);
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
              currentIndex = _handleLambdaFunction(variable, input,
                  currentIndex, closeRoundBracket, valueStack, config);
              variable = '';
              continue;
            } else {
              /// function execution

              if (declarationMode) {
                throw Exception('Can\'t call method here');
              }
              Processor? processor = this;
              if (processor._staticFunctions.containsKey(variable)) {
                currentIndex = _handleFunction(
                    index,
                    processor._staticFunctions[variable]!,
                    variable,
                    input,
                    currentIndex,
                    closeRoundBracket,
                    valueStack,
                    config);
                variable = '';
                break;
              }
              if (processor.parentProcessor?._staticFunctions
                      .containsKey(variable) ??
                  false) {
                currentIndex = _handleFunction(
                    index,
                    processor.parentProcessor!._staticFunctions[variable]!,
                    variable,
                    input,
                    currentIndex,
                    closeRoundBracket,
                    valueStack,
                    config);
                variable = '';
                break;
              }
              while (processor != null) {
                if (processor.functions.containsKey(variable)) {
                  currentIndex = _handleFunction(
                      index,
                      processor.functions[variable]!,
                      variable,
                      input,
                      currentIndex,
                      closeRoundBracket,
                      valueStack,
                      config);
                  variable = '';
                  break;
                } else if (processor.variables.containsKey(variable) ||
                    processor.localVariables.containsKey(variable)) {
                  final FVBFunction? function;
                  if (processor.variables[variable]?.value is FVBFunction) {
                    function = processor.variables[variable]?.value;
                  } else if ((processor.variables[variable]?.dataType
                              .equals(DataType.fvbFunction) ??
                          false) ||
                      (processor.variables[variable]?.dataType
                              .equals(DataType.fvbDynamic) ??
                          false)) {
                    function = null;
                    variable = '';
                    currentIndex = closeRoundBracket;
                    continue;
                  } else if (processor.localVariables[variable]
                      is FVBFunction) {
                    function = processor.localVariables[variable]?.value;
                  } else {
                    function = null;
                  }
                  if (function == null) {
                    throw Exception('Function $variable not found');
                  }
                  final argumentList = CodeOperations.splitBy(
                      input.substring(currentIndex + 1, closeRoundBracket));
                  final output = function.execute(this, null,
                      processArgList(index, function, argumentList, {}, config),
                      config: config);
                  if (output != null) {
                    valueStack.push(
                        FVBValue(value: output, dataType: function.returnType));
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
              int ind = currentIndex + 1;
              final processedArgs = argumentList.asMap().entries.map((e) {
                if (e.key > 0) {
                  ind += argumentList[e.key - 1].length;
                }
                final output = process(e.value, index: ind, config: config);
                return output.value;
              }).toList();
              final function = (predefinedFunctions[variable] ??
                  predefinedSpecificFunctions[variable])!;
              final output = function.perform.call(processedArgs, this);

              valueStack
                  .push(FVBValue(value: output, dataType: DataType.fvbDynamic));
              variable = '';
              currentIndex = closeRoundBracket;
            }
            continue;
          } else if (ch == '('.codeUnits[0]) {
            final closeOpenBracket = CodeOperations.findCloseBracket(
                input, currentIndex, '('.codeUnits.first, ')'.codeUnits.first);
            if (closeOpenBracket == null) {
              return FVBCacheValue.kNull;
            }
            if (closeOpenBracket + 1 < input.length &&
                input[closeOpenBracket + 1] == '=' &&
                input[closeOpenBracket + 2] == '>') {
              currentIndex = _handleLambdaFunction(variable, input,
                  currentIndex, closeOpenBracket, valueStack, config);
              continue;
            } else if (input.length > closeOpenBracket + 1 &&
                input[closeOpenBracket + 1] == '{') {
              final int? closeCurlyBracketIndex =
                  CodeOperations.findCloseBracket(input, closeOpenBracket + 1,
                      '{'.codeUnits.first, '}'.codeUnits.first);
              if (closeCurlyBracketIndex == null) {
                return FVBCacheValue.kNull;
              }
              final function = FunctionProcessor.parse(
                  this,
                  '',
                  input.substring(currentIndex + 1, closeOpenBracket),
                  input.substring(closeOpenBracket + 2, closeCurlyBracketIndex),
                  config,
                  closeOpenBracket + 2);
              currentIndex = closeCurlyBracketIndex;
              valueStack
                  .push(FVBValue(value: function, dataType: function.dataType));
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
            if (!resolveVariable(
                index + currentIndex, variable, object, valueStack, config)) {
              return FVBCacheValue.kNull;
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
                  return FVBCacheValue.kNull;
                }
                processOperator(index + currentIndex, operatorStack.pop()!,
                    object, valueStack, operatorStack, config);
              }
              operatorStack.push(operator);
            }
          } else if (ch == '('.codeUnits[0]) {
            final i = CodeOperations.findCloseBracket(
                input, currentIndex, '('.codeUnits.first, ')'.codeUnits.first);

            if (i == null) {
              return FVBCacheValue.kNull;
            }
            final innerProcess = process<T>(
                input.substring(currentIndex + 1, i),
                index: index + currentIndex + 1,
                resolve: true,
                config: config);
            valueStack.push(FVBValue.fromCache(innerProcess));
            currentIndex = i;
          }
        }
      }
      if (variable.isNotEmpty) {
        if (!resolveVariable(index + input.length - variable.length, variable,
            object, valueStack, config)) {
          return FVBCacheValue.kNull;
        }
        variable = '';
      }

// Empty out the operator stack at the end of the input
      while (operatorStack.isNotEmpty) {
        if (error) {
          return FVBCacheValue.kNull;
        }
        processOperator(index + input.length, operatorStack.pop()!, object,
            valueStack, operatorStack, config);
      }

// Print the result if no error has been seen.
      if (!error && valueStack.isNotEmpty) {
        FVBCacheValue? result;
        while (valueStack.isNotEmpty) {
          if (error) {
            return FVBCacheValue.kNull;
          }

          final FVBValue value = valueStack.pop()!;
          result = value.evaluateValue(index + input.length, this, config,
              ignoreIfNotExist: true);
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
              staticVariables[value.variableName!] = variableModel;
            } else {
              variables[value.variableName!] = variableModel;
            }
          }
        }

        if (operatorStack.isNotEmpty || valueStack.isNotEmpty) {
          enableError('Expression error.');
        } else {
          return result ?? FVBCacheValue.kNull;
        }
      }
      return FVBCacheValue.kNull;
    } on Exception catch (_) {
      final msg = '$_ at code "$input" $extendedError';
      enableError(msg);
      config.errorCallback?.call(msg, null);

      return FVBCacheValue.kNull;
    }
    // on Error catch (e) {
    //   final message = '$e at code "$input" $extendedError';
    //   config.errorCallback?.call(message, null);
    //   enableError(message);
    //   if (errorReported != message && message.contains('Null check')) {
    //     errorReported = message;
    //     _bugReported(message);
    //   }
    //   e.printError();
    //   return FVBCacheValue.kNull;
    // }
  }

  List<dynamic> processArgList(int index, FVBFunction fun,
      List<String> argumentList, Map<String, DataType> generics, config) {
    return ArgumentProcessor.process(
        fun, index, this, argumentList, generics, config);
  }

  List<FVBArgument> processArgDefinitionList(
      int index, List<String> argumentList, config,
      {Map<String, FVBVariable>? variables}) {
    return ArgumentProcessor.processArgumentDefinition(
        index, this, argumentList,
        variables: variables, config: config);
  }

  bool parseNumber(String number, valueStack) {
    if (number.contains('.')) {
      final parse = double.tryParse(number);
      if (parse != null) {
        valueStack.push(FVBValue(value: parse, dataType: DataType.fvbDouble));
        return true;
      }
    } else {
      final intParsed = int.tryParse(number);
      if (intParsed != null) {
        valueStack.push(FVBValue(value: intParsed, dataType: DataType.fvbInt));
        return true;
      }
    }
    return false;
  }

  void enableError(String message, [(int, int)? range]) {
    error = true;
    errorMessage = message;
    final errorMsg = '${message.replaceAll(space, ' ')} at $scopeName';
    onError.call(errorMsg, range);
  }

  bool isString(String value) {
    if (value.length >= 2) {
      return value[0] == value[value.length - 1] &&
          (value[0] == '\'' || value[0] == '"');
    }
    return false;
  }

  bool resolveVariable(
      int index, String variable, String object, valueStack, config) {
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
          value: FVBReturn.fromCache(
            process(
              variable.substring(7),
              config: config,
              index: index,
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
          variable, classes, Processor.enums);
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
      final Stack2<FVBValue> valueStack,
      ProcessorConfig config) {
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
      config,
      closeOpenBracket + 3,
      lambda: true,
    );
    if (function.name.isNotEmpty) {
      if (static) {
        _staticFunctions[function.name] = function;
      } else {
        functions[function.name] = function;
      }
    } else {
      valueStack.push(FVBValue(
        value: function,
        dataType: function.dataType,
      ));
    }
    return input.length - 1;
  }

  int _handleFunction(
      int index,
      final FVBFunction function,
      final String variable,
      final String input,
      int currentIndex,
      final int closeRoundBracket,
      final Stack2<FVBValue> valueStack,
      config) {
    if (valueStack.isEmpty && declarationMode) {
      throw Exception('can not call function $variable in declarative mode');
    }
    final argumentList = CodeOperations.splitBy(
        input.substring(currentIndex + 1, closeRoundBracket));
    final output = function.execute(
        this,
        null,
        processArgList(
            index + currentIndex + 1, function, argumentList, {}, config),
        config: config);
    valueStack.push(FVBValue(value: output, dataType: function.returnType));

    return closeRoundBracket;
  }

  void _handleObjectMethods(
      int index,
      final objectInstance,
      final String variable,
      final List<String> argumentList,
      final Stack2<FVBValue> valueStack,
      ProcessorConfig config) {
    if (objectInstance is FVBTest) {
      if (objectInstance.dataType.name == 'fvbInstance') {
        if (objectInstance.fvbClass != null) {
          objectInstance.fvbClass?.testMethod(index, variable, objectInstance,
              argumentList, this, valueStack, config);
          return;
        } else if (classes.containsKey(objectInstance.dataType.fvbName!)) {
          final fvbClass = classes[objectInstance.dataType.fvbName!];
          fvbClass?.testMethod(index, variable, objectInstance, argumentList,
              this, valueStack, config);
          return;
        } else {
          throw Exception(
              'Class ${objectInstance.dataType.fvbName} not found!');
        }
      } else if (objectInstance.dataType.name == 'Future') {
        final fvbClass = classes[objectInstance.dataType.name];
        fvbClass?.testMethod(index, variable, objectInstance, argumentList,
            this, valueStack, config);
        return;
      } else if (objectInstance.dataType.name == 'Type' &&
          objectInstance.dataType.fvbName != null) {
        final fvbClass = classes[objectInstance.dataType.fvbName!];
        fvbClass?.testStaticMethod(index, variable, objectInstance,
            argumentList, this, valueStack, config);
        return;
      }
    }
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
    final processedArgs =
        processArgList(index, method, argumentList, {}, config);
    valueStack.push(
      FVBValue(
          value: method.execute(this, null, processedArgs,
              self: objectInstance, config: config),
          dataType: method.returnType),
    );
  }

  void finishProcessing(
      int index,
      final String variable,
      final String operator,
      final String object,
      operatorStack,
      valueStack,
      bool unmodifiable,
      config) {
    if (variable.isNotEmpty) {
      resolveVariable(index, variable, object, valueStack, config);
    }
    while (operatorStack.isNotEmpty &&
        getPrecedence(operator) <= getPrecedence(operatorStack.peek!)) {
      if (error) {
        return;
      }

      processOperator(index, operatorStack.pop()!, object, valueStack,
          operatorStack, config);
    }
  }

  void _handleVariableAndFunctionSuggestions(
    final int index,
    final String variable,
    final String object,
    final Stack2<FVBValue> valueStack,
    ProcessSuggestionSetting? suggestionSetting,
    config,
  ) {
    if (onSuggestions == null) {
      return;
    }
    final setting = suggestionSetting ?? const ProcessSuggestionSetting();
    final CodeSuggestion suggestion;
    if (object.isNotEmpty) {
      suggestion = CodeSuggestion(variable, index);
      if (object == kInstance) {
        final instance = localVariables[kInstance];
        if (instance != null) {
          _handleSuggestionFromFVBCache(
              suggestion, object, variable, valueStack, instance);
        }
      } else if (object == 'this') {
        suggestion.addAll(SuggestionProcessor.processVariables(
            parentProcessor!.variables, variable, object, false));
        suggestion.addAll(
          SuggestionProcessor.processFunctions(
              parentProcessor!.functions.values, variable, object, '', false),
        );
      } else if (classes.containsKey(object)) {
        addFVBClassSuggestion(
            suggestion, classes[object]!, object, variable, valueStack);
      } else if (enums.containsKey(object)) {
        addEnumSuggestion(
            suggestion, enums[object]!, object, variable, valueStack);
      } else {
        final cacheValue = getValue(index, object, config);
        _handleSuggestionFromFVBCache(
            suggestion, object, variable, valueStack, cacheValue);
      }
    } else if (valueStack.isNotEmpty) {
      suggestion = CodeSuggestion(variable, index);
      _handleSuggestionFromFVBCache(suggestion, object, variable, valueStack,
          valueStack.peek!.cacheValue);
    } else {
      if (suggestionConfig.namedParameterSuggestion != null) {
        suggestion = CodeSuggestion(variable, index);
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
        suggestion = CodeSuggestion(keyword, index);
        if (list.length == 1) {
          Processor? processor = this;
          final globalName = collection.project!.name;
          if (setting.shouldShow(SuggestionType.keyword)) {
            suggestion.addAll(keywords
                .where((element) =>
                    element != keyword && element.startsWith(keyword))
                .map((e) => SuggestionTile(
                    e, globalName, SuggestionType.keyword, e, 0,
                    global: true)));
          }

          /// Value keyword means suggestions like true, false, null etc which specify value
          if (setting.shouldShow(SuggestionType.valueKeyword)) {
            suggestion.addAll(valueKeywords
                .where((element) =>
                    element != keyword && element.startsWith(keyword))
                .map((e) => SuggestionTile(
                    e, globalName, SuggestionType.valueKeyword, e, 0,
                    global: true)));
          }

          /// Predefined functions are functions static which are in-built given to interact between CodeProcessor and UI and will be deprecated soon :)
          if (setting.shouldShow(SuggestionType.builtInFun)) {
            suggestion.addAll(
              predefinedFunctions.entries
                  .where((e) => e.key.contains(keyword))
                  .map(
                    (e) => SuggestionTile(e.value, '',
                        SuggestionType.builtInFun, '${e.value.name}()', 1),
                  ),
            );
          }

          /// Predefined-Specific functions are code-processor dependent same as predefined function and this also will be deprecated soon :)
          if (setting.shouldShow(SuggestionType.builtInFun)) {
            suggestion.addAll(
              predefinedSpecificFunctions.entries
                  .where((e) => e.key.contains(keyword))
                  .map(
                    (e) => SuggestionTile(e.value, '',
                        SuggestionType.builtInFun, '${e.value.name}()', 1),
                  ),
            );
          }
          if (setting.shouldShow(SuggestionType.classes)) {
            SuggestionProcessor.processClasses(
                classes, keyword, object, valueStack, suggestion);
          }
          if (setting.shouldShow(SuggestionType.fvbEnum)) {
            SuggestionProcessor.processEnums(
                enums, keyword, object, valueStack, suggestion);
          }

          if (setting.shouldShow(SuggestionType.localVariable)) {
            suggestion.addAll(localVariables.keys
                .where((element) => element.contains(keyword))
                .map((element) => SuggestionTile(element, processor!.scopeName,
                    SuggestionType.localVariable, element, 0)));

            suggestion.addAll(ignoreVariables.keys
                .where((element) => element.contains(keyword))
                .map((element) => SuggestionTile(element, processor!.scopeName,
                    SuggestionType.localVariable, element, 0)));
          }
          if (setting.shouldShow(SuggestionType.function) ||
              setting.shouldShow(SuggestionType.variable)) {
            while (processor != null) {
              final global = processor.scopeName == globalName;

              if (setting.shouldShow(SuggestionType.function)) {
                suggestion.addAll(SuggestionProcessor.processFunctions(
                    processor.functions.values,
                    keyword,
                    processor.scopeName,
                    processor.scopeName,
                    global));
              }
              if (setting.shouldShow(SuggestionType.variable)) {
                suggestion.addAll(
                  SuggestionProcessor.processVariables(processor.variables,
                      keyword, processor.scopeName, global),
                );
              }
              processor = processor.parentProcessor;
            }
          }
          for (final package in packages.values) {
            if (setting.shouldShow(SuggestionType.function)) {
              suggestion.addAll(SuggestionProcessor.processFunctions(
                  package.functions.values,
                  keyword,
                  package.scopeName,
                  package.scopeName,
                  false));
            }
            if (setting.shouldShow(SuggestionType.variable)) {
              suggestion.addAll(
                SuggestionProcessor.processVariables(
                    package.variables, keyword, package.scopeName, false),
              );
            }
          }
        } else if (list.length == 2) {
          if (list.first.contains(keyword) &&
              setting.shouldShow(SuggestionType.keyword)) {
            final suggest1 =
                StringOperation.toCamelCase(list.first, startWithLower: true);
            suggestion.add(SuggestionTile(
                suggest1, '', SuggestionType.keyword, suggest1, 0));
          }
        }
      }
    }
    if (suggestion.suggestions.isNotEmpty) {
      onSuggestions?.call(suggestion);
    }
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
    suggestion.addAll(
      SuggestionProcessor.processNamedConstructor(
          fvbClass.fvbFunctions.values.where((element) => element.isFactory),
          variable,
          object,
          fvbClass.name,
          false),
    );

    if (fvbClass.fvbStaticVariables != null) {
      suggestion.addAll(SuggestionProcessor.processVariables(
          fvbClass.fvbStaticVariables!
              .map((key, value) => MapEntry(key, value)),
          variable,
          object,
          false));
    }
  }

  void addEnumSuggestion(CodeSuggestion suggestion, FVBEnum fvbEnum,
      String object, String variable, Stack2<FVBValue> valueStack) {
    suggestion.addAll(fvbEnum.values.values
        .where((element) => element.name.contains(variable))
        .map((e) => SuggestionTile(
              e,
              object,
              SuggestionType.fvbEnum,
              e.name,
              0,
              global: true,
            ))
        .toList(growable: false));
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

  // void _bugReported(String message) {
  //   sl<EventLogBloc>().add(HandleBugReportEvent(message));
  // }

  void _handleSuggestionFromFVBCache(CodeSuggestion suggestion, String object,
      String variable, valueStack, FVBCacheValue cacheValue) {
    final DataType dataType =
        cacheValue.value == null || cacheValue.value is FVBTest
            ? cacheValue.dataType
            : (DataTypeProcessor.getDartTypeToDatatype(cacheValue.value));
    if (cacheValue.value is FVBInstance) {
      addFVBInstanceSuggestion(
          suggestion,
          (cacheValue.value as FVBInstance).fvbClass,
          object,
          variable,
          valueStack);
    } else {
      if (dataType.isFVBInstance) {
        if (!classes.containsKey(dataType.fvbName!)) {
          enableError('Class "${dataType.fvbName}" not Found ');
          return;
        }
        addFVBInstanceSuggestion(suggestion, classes[dataType.fvbName!]!,
            object, variable, valueStack);
      } else if (classes.containsKey(dataType.name)) {
        addFVBInstanceSuggestion(
            suggestion, classes[dataType.name]!, object, variable, valueStack);
      } else if (dataType.name == 'enumValue') {
        suggestion.addAll(SuggestionProcessor.processVariables(
            enumVariables, variable, object, false));
      }
    }
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
  final (String, int)? condition;
  final (String, int) body;

  ConditionalStatement(this.condition, this.body);

  @override
  String toString() {
    return '$condition :: $body';
  }
}

class CaseStatement {
  final (String, int)? condition;
  final (String, int) body;

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
    if (value is FVBEnumValue) {
      return '${(value as FVBEnumValue).enumName}.${(value as FVBEnumValue).name}';
    }
    if (type == SuggestionType.keyword ||
        type == SuggestionType.localVariable) {
      return value;
    }
    if (value is String) {
      return value;
    }
    return value.name;
  }

  SuggestionTile(
      this.value, this.scope, this.type, this.result, this.resultCursorEnd,
      {this.global = false, this.resultCursorStart});
}

class CodeSuggestion extends Equatable {
  final String code;
  final List<SuggestionTile> suggestions = [];
  final int index;

  CodeSuggestion(this.code, this.index);

  void addAll(final Iterable<SuggestionTile> suggestions) {
    for (final suggestion in suggestions) {
      add(suggestion);
    }
  }

  void add(SuggestionTile suggestion) {
    final name = suggestion.title;
    if (name.startsWith(code)) {
      suggestion.priority += 100;
    } else if (name.startsWith(code.toLowerCase())) {
      suggestion.priority += 80;
    }
    int i = suggestions.length - 1;
    while (i >= 0 && suggestions[i].priority < suggestion.priority) {
      i--;
    }

    i++;
    if (i < suggestions.length) {
      suggestions.insert(i, suggestion);
    } else {
      suggestions.add(suggestion);
    }
  }

  @override
  List<Object?> get props => [code, index, suggestions];
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
  valueKeyword,
  fvbEnum,
}
