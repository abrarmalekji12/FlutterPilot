import 'dart:core';
import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../code_to_component.dart';
import '../../component_list.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../models/function_model.dart';
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
  final Map<String,FVBFunction> functions;
  final Map<String,FVBVariable> variables;
  FVBClass(this.name,this.functions, this.variables);
  FVBInstance createInstance(){
    return FVBInstance(FVBClass(name,functions, variables));
  }
}
class FVBInstance{
  final FVBClass fvbClass;
  FVBInstance(this.fvbClass);
}

class FVBFunction {
  final String code;
  final Map<String, FVBVariable> localVariables = {};
  final List<String> arguments;

  FVBFunction(this.code, this.arguments);

  dynamic execute(
      final CodeProcessor processor,
      final List<dynamic> argumentValues,
      String? Function(String) consoleCallback,
      void Function(String) onError) {
    Map<String, dynamic> oldVariables = {};
    for (int i = 0; i < arguments.length; i++) {
      if (processor.localVariables.containsKey(arguments[i])) {
        oldVariables[arguments[i]] = processor.localVariables[arguments[i]];
      }
      processor.localVariables[arguments[i]] = argumentValues[i];
    }
    final variables = Map<String, VariableModel>.from(processor.variables);
    final output = processor.executeCode(code, consoleCallback, onError);
    processor.variables.clear();
    processor.variables.addAll(variables);
    for (int i = 0; i < arguments.length; i++) {
      if (oldVariables.containsKey(arguments[i])) {
        processor.localVariables[arguments[i]] = oldVariables[arguments[i]];
      } else {
        processor.localVariables.remove(arguments[i]);
      }
    }
    return output;
  }
}

class FVBVariable {
  final String name;
  dynamic value;
  final DataType dataType;

  FVBVariable(this.name,this.dataType);
}

class CodeProcessor {
  final Map<String, VariableModel> variables = {};
  final Map<String, FunctionModel> predefinedFunctions = {};
  final Map<String, FVBFunction> functions = {};
  final Map<String, FVBClass> classes={};
  final Map<String, dynamic> localVariables = {};

  late bool error;
  String errorMessage = '';
  final capitalACodeUnit = 'A'.codeUnits.first,
      smallZCodeUnit = 'z'.codeUnits.first,
      underScoreCodeUnit = '_'.codeUnits.first;
  final zeroCodeUnit = '0'.codeUnits.first,
      nineCodeUnit = '9'.codeUnits.first,
      dotCodeUnit = '.'.codeUnits.first;

  CodeProcessor() {
    error = false;
    variables['pi'] = VariableModel(
        'pi', pi, false, 'it is mathematical value of pi', DataType.double, '',
        deletable: false);
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

    predefinedFunctions['toInt'] = FunctionModel<int>('toInt', (arguments) {
      return int.parse(arguments[0]);
    }, ''' ''');
    predefinedFunctions['toDouble'] =
        FunctionModel<double>('toDouble', (arguments) {
      return double.parse(arguments[0]);
    }, ''' ''');

    predefinedFunctions['lookUp'] =
        FunctionModel<dynamic>('lookUp', (arguments) {
      final id = arguments[0];
      String? out;
      ComponentOperationCubit.currentFlutterProject?.currentScreen.rootComponent
          ?.forEach((p0) {
        if (p0.id == id) {
          if (p0 is CTextField) {
            out = p0.textEditingController.text;
          }
        }
      });
      return out;
    }, ''' ''');

    predefinedFunctions['refresh'] =
        FunctionModel<dynamic>('refresh', (arguments) {
      final id = arguments[0];
      ComponentOperationCubit.currentFlutterProject?.currentScreen.rootComponent
          ?.forEach((p0) {
        logger('here4 ${p0.id}');
        if (p0.id == id) {}
      });
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

  void processOperator(final String operator, final Stack2<dynamic> valueStack,
      final Stack2<String> operatorStack) {
    dynamic a, b;
    if (valueStack.isEmpty) {
      error = true;
      errorMessage = 'ValueStack is Empty, syntax error !!';
      return;
    } else {
      b = valueStack.pop()!;
    }
    if (valueStack.isEmpty && operator != '-' && operator != '++') {
      error = true;
      errorMessage = 'Not enough values, syntax error !!';
      return;
    } else if (valueStack.isNotEmpty) {
      a = valueStack.pop()!;
    }
    late dynamic r;
    switch (operator) {
      case '--':
      case '+':
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
        print('HERE I AM $a $b');
        dynamic key;
        if (a.endsWith('*')) {
          a = a.substring(0, a.length - 1);
          key = valueStack.pop()!;
        }
        if (variables.containsKey(a)) {
          if (key != null) {
            variables[a]?.value[key] = b;
          } else {
            variables[a]?.value = b;
          }
        } else if (localVariables.containsKey(a)) {
          if (key != null) {
            localVariables[a][key] = b;
          } else {
            localVariables[a] = b;
          }
        } else if (key == null) {
          late final DataType dataType;
          if (b is double) {
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
          } else if (b is FVBInstance){
            dataType= DataType.fvbInstance;
          }else {
            throw Exception('Invalid datatype of variable');
          }
          variables[a] = VariableModel(a, b, false, null, dataType, '',type: dataType == DataType.fvbInstance?(b as FVBInstance).fvbClass.name:null);
        }
        r = null;
        break;
      case '++':
        if (variables.containsKey(b)) {
          variables[b]!.value = variables[b]!.value! + 1;
        } else if (localVariables.containsKey(b)) {
          localVariables[b] = localVariables[b] + 1;
        }
        r = null;
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
        r = a.toString() == b.toString();
        break;
      case '!=':
        r = a != b;
        break;
      default:
        error = true;
        errorMessage = 'Operation "$operator" not found!!';
        r = null;
    }
    valueStack.push(r);
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
        error = true;
        errorMessage = 'No expression between {{ and }} !!';
        return null;
        // return CodeOutput.right('No variables');
      }
      final variableName = code.substring(si + 2, ei);
      final value = process<String>(variableName,
          resolve: true, consoleCallback: consoleCallback, onError: onError);
      if (value != null) {
        final k1 = '{{$variableName}}';
        final v1 = value.toString();
        code = code.replaceAll(k1, v1);
        for (int i = 0; i < startList.length; i++) {
          startList[i] += v1.length - k1.length;
          endList[i] += v1.length - k1.length;
        }
      } else {
        return code; //CodeOutput.right('No varaible with name $variableName')
      }
    }
    return code;
  }

  dynamic executeCode(final String input,
      String? Function(String) consoleCallback, void Function(String) onError) {
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
          onError.call(errorMessage);
        } else if (output != null) {
          globalOutput = output;
          consoleCallback(output.toString());
        }
      }
    }
    return globalOutput;
  }

  dynamic process<T>(final String input,
      {bool resolve = false,
      String? Function(String)? consoleCallback,
      void Function(String)? onError}) {
    final Stack2<dynamic> valueStack = Stack2<dynamic>();
    final Stack2<String> operatorStack = Stack2<String>();
    String number = '';
    String variable = '';
    error = false;
    if (input.length >= 3 &&
        input[0] == '{' &&
        input[1] != '{' &&
        input[input.length - 1] == '}' &&
        input[input.length - 2] != '}') {
      return executeCode(input, consoleCallback!, onError!);
    }
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
      if (ch == '['.codeUnits.first) {
        int count = 0;
        for (int i = n + 1; i < input.length; i++) {
          if (input[i] == ']' && count == 0) {
            if (variable.isNotEmpty) {
              final key = process(input.substring(n + 1, i),
                  consoleCallback: consoleCallback, onError: onError);
              if (i + 2 < input.length &&
                  input[i + 1] == '=' &&
                  input.substring(i + 1, i + 3) != '==') {
                valueStack.push(key);
                valueStack.push('$variable*');
                variable = '';
                n = i;
                break;
              }
              resolveVariable(variable, valueStack, index: key);
              variable = '';
              n = i;
              break;
            }
            valueStack.push(CodeOperations.splitBy(input.substring(n + 1, i))
                .map((e) => process(e,
                    consoleCallback: consoleCallback, onError: onError))
                .toList());
            variable = '';
            n = i + 1;
            break;
          } else if (input[i] == '[') {
            count++;
          } else if (input[i] == ']') {
            count--;
          }
        }
        continue;
      } else if (ch == '{'.codeUnits.first) {
        if(variable.isNotEmpty&&variable.startsWith('class')){
          final className=variable.substring(5);
         final closeCurlyBracket=CodeOperations.findCloseBracket(input, n, '{'.codeUnits.first, '}'.codeUnits.first);
         final instructions=CodeOperations.getFVBInstructionsFromCode(input.substring(n+1,closeCurlyBracket));
         final CodeProcessor processor=CodeProcessor();
         for(final instruction in instructions) {
           processor.process(instruction);
         }
         classes[className]=FVBClass(className,processor.functions, processor.variables.map((key, value) => MapEntry(key, FVBVariable(value.name, value.dataType))));
         n=closeCurlyBracket;
         variable='';
         continue;
        }else {
          int count = 0;
          for (int i = n + 1; i < input.length; i++) {
            if (input[i] == '}' && count == 0) {
              valueStack.push(
                Map.from(
                  CodeOperations.splitBy(input.substring(n + 1, i))
                      .asMap()
                      .map((e, n) {
                    final split = CodeOperations.splitBy(n, splitBy: ':');
                    logger('MAP OPEN BRACKET $n   ==  $split');
                    return MapEntry(
                        process(split[0],
                            consoleCallback: consoleCallback, onError: onError),
                        process(split[1],
                            consoleCallback: consoleCallback,
                            onError: onError));
                  }),
                ),
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
      } else if ((ch >= zeroCodeUnit && ch <= nineCodeUnit)) {
        if (variable.isNotEmpty) {
          variable += number + nextToken;
          number = '';
        } else {
          number += nextToken;
        }
      } else if ((ch >= capitalACodeUnit && ch <= smallZCodeUnit) ||
          ch == underScoreCodeUnit) {
        variable += nextToken;
      } else if (ch == '"'.codeUnits.first) {
        if (variable.isEmpty) {
          continue;
        }
        if (n - variable.length - 1 >= 0 &&
            input[n - variable.length - 1] == '"') {
          return variable;
        } else {
          return null;
        }
      } else {
        if (variable.isNotEmpty && ch == '('.codeUnits[0]) {
          int count = 0;
          for (int m = n + 1; m < input.length; m++) {
            if (input[m] == '(') {
              count++;
            }
            if (count == 0 && input[m] == ')') {
              print('CLASS CONTAINS ${classes.keys.contains(variable)}');
              if(classes.keys.contains(variable)){
                valueStack.push(classes[variable]!.createInstance());
                variable='';
                n=m;
               break;
              }
              else if (variable == 'while') {
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
                int endIndex = CodeOperations.findCloseBracket(
                    input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                int elseEndIndex = -1;

                if (input.substring(endIndex + 1, endIndex + 5) == 'else') {
                  elseEndIndex = CodeOperations.findCloseBracket(input,
                      endIndex + 5, '{'.codeUnits.first, '}'.codeUnits.first);
                }
                if (process(input.substring(n + 1, m),
                        consoleCallback: consoleCallback, onError: onError) ==
                    true) {
                  executeCode(input.substring(m + 2, endIndex),
                      consoleCallback!, onError!);

                  //endIndex+6<input.length&&
                } else if (elseEndIndex != -1) {
                  executeCode(input.substring(endIndex + 6, elseEndIndex - 1),
                      consoleCallback!, onError!);
                }
                if (elseEndIndex != -1) {
                  endIndex = elseEndIndex;
                }
                n = endIndex;
                variable = '';
                continue;
              } else if (variable == 'delayed') {
                int endIndex = CodeOperations.findCloseBracket(
                    input, m + 1, '{'.codeUnits.first, '}'.codeUnits.first);
                final int durationInMillis = process(
                    input.substring(n + 1, m),
                    consoleCallback: consoleCallback,
                    onError: onError);
                Future.delayed(Duration(milliseconds: durationInMillis), () {
                  executeCode(input.substring(m + 2, endIndex),
                      consoleCallback!, onError!);
                });
                n = endIndex;
                variable = '';
                continue;
              } else if (variable == 'return') {
                return process(input.substring(n + 1, m),
                    consoleCallback: consoleCallback, onError: onError);
              } else if (input.length > m + 1 && input[m + 1] == '{') {
                int closeBracketIndex = -1;
                count = 0;
                for (int i = m + 2; i < input.length; i++) {
                  if (input[i] == '}' && count == 0) {
                    closeBracketIndex = i;
                    break;
                  } else if (input[i] == '{') {
                    count++;
                  } else if (input[i] == '}') {
                    count--;
                  }
                }
                if (closeBracketIndex < 0) {
                  error = true;
                  errorMessage = 'Invalid function syntax!!';
                  return;
                }
                final argumentList =
                    CodeOperations.splitBy(input.substring(n + 1, m));
                functions[variable] = FVBFunction(
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
                    consoleCallback!,
                    onError!);
                if (output != null) {
                  valueStack.push(output);
                }
                variable = '';
                n = m;
                continue;
              }
              final argumentList =
                  CodeOperations.splitBy(input.substring(n + 1, m));
              if (!predefinedFunctions.containsKey(variable)) {
                showError('No predefined function named $variable found');
                return;
              }
              final output = predefinedFunctions[variable]!.perform.call(
                  argumentList
                      .map((e) => process(e,
                          consoleCallback: consoleCallback, onError: onError))
                      .toList());
              valueStack.push(output);

              variable = '';
              n = m;
              continue;
            } else if (input[m] == ')') {
              count--;
            }
          }
          continue;
        }

        if (number.isNotEmpty) {
          final parse = double.tryParse(number);
          if (parse == null) {
            return null;
          }
          valueStack.push(parse);
          number = '';
        }
        if (isOperator(ch)) {
          String operator = input[n];
          if (n + 1 < input.length && isOperator(input[n + 1].codeUnits.first)) {
            operator = operator +  input[n + 1];
            n++;
          }
          if ((operator == '++' || operator == '=') && variable.isNotEmpty) {
            valueStack.push(variable);
            variable = '';
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
          final index = input.indexOf(')', n);
          if (index == -1) {
            return null;
          }
          final innerProcess = process<T>(input.substring(n + 1, index),
              resolve: true,
              consoleCallback: consoleCallback,
              onError: onError);
          if (innerProcess != null) {
            valueStack.push(innerProcess);
            n = index;
            continue;
          } else {
            return null;
          }
        }

        if (variable.isNotEmpty) {
          if (!resolveVariable(variable, valueStack)) {
            return null;
          }
          variable = '';
        }
      }
    }
    if (number.isNotEmpty) {
      final parse = double.tryParse(number);
      if (parse == null) {
        return null;
      }
      valueStack.push(parse);
      number = '';
    } else if (variable.isNotEmpty) {
      if (!resolveVariable(variable, valueStack)) {
        return null;
      }
      variable = '';
    }

    logger('stacks $valueStack ${operatorStack._list}');
    // Empty out the operator stack at the end of the input
    while (operatorStack.isNotEmpty) {
      processOperator(operatorStack.pop()!, valueStack, operatorStack);
    }

    // Print the result if no error has been seen.
    if (!error && valueStack.isNotEmpty) {
      final result = valueStack.pop();

      if (operatorStack.isNotEmpty || valueStack.isNotEmpty) {
        logger('Expression error.');
      } else {
        return result;
      }
    }
    return null;
  }

  void showError(String message) {
    error = true;
    errorMessage = message;
    if (kDebugMode) {
      throw Exception(message);
    }
  }

  bool isString(String value) {
    if (value.length >= 2) {
      return value[0] == value[value.length - 1] &&
          (value[0] == '\'' || value[0] == '"');
    }
    return false;
  }

  bool resolveVariable(String variable, valueStack, {dynamic index}) {
    if (variables.containsKey(variable)) {
      valueStack.push(index != null
          ? variables[variable]!.value[index]
          : variables[variable]!.value);
    } else if (localVariables.containsKey(variable)) {
      valueStack.push(index != null
          ? localVariables[variable]![index]
          : localVariables[variable]!);
    } else if (variable == 'true') {
      valueStack.push(true);
    } else if (variable == 'false') {
      valueStack.push(false);
    } else {
      return false;
    }
    return true;
  }
}

class Stack2<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

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
