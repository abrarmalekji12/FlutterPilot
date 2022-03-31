import 'dart:core';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import '../../code_to_component.dart';
import '../../models/function_model.dart';
import '../../models/other_model.dart';
import '../../models/variable_model.dart';
import '../../ui/models_view.dart';

Color? colorToHex(String hexString) {
  if (hexString.length < 7) {
    return null;
  }
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  final colorInt = int.tryParse(buffer.toString(), radix: 16);
  if (colorInt == null) {
    return null;
  }
  return Color(colorInt);
}

class CodeProcessor {
  final Map<String, VariableModel> variables = {};
  final Map<String, FunctionModel> functions = {};
  final Map<String, dynamic> modelVariables = {};

  late bool error;
  final capitalACodeUnit = 'A'.codeUnits.first,
      smallZCodeUnit = 'z'.codeUnits.first,
      underScoreCodeUnit = '_'.codeUnits.first;
  final zeroCodeUnit = '0'.codeUnits.first,
      nineCodeUnit = '9'.codeUnits.first,
      dotCodeUnit = '.'.codeUnits.first;

  CodeProcessor() {
    error = false;
    functions['res'] = FunctionModel<dynamic>('res', (arguments) {
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

    functions['ifElse'] = FunctionModel<dynamic>('ifElse', (arguments) {
      if (arguments.length >= 2) {
        if (arguments[0] == true) {
          return arguments[1];
        } else if (arguments.length == 3) {
          return arguments[2];
        }
      }
    }, '''
    double ifElse(dynamic expression,dynamic ifTrue,[dynamic elseTrue]){
    if(expression==true){
    return ifTrue;
    }
    else if(elseTrue!=null){
    return elseTrue;
    }
    }
    ''');
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
        ch == '%'.codeUnits[0] ||
        ch == '!'.codeUnits[0] ||
        ch == '~'.codeUnits[0] ||
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

  void processOperator(String t, valueStack, operatorStack) {
    bool error = false;
    dynamic a, b;
    if (valueStack.isEmpty) {
      error = true;
      print('error 1');
      return;
    } else {
      b =  valueStack.pop()!;
    }
    if (valueStack.isEmpty && t != '-' && t != '!') {
      error = true;
      print('error 2');
      return;
    } else if (valueStack.isNotEmpty) {
      a = valueStack.pop()!;
    }
    late dynamic r;
    switch (t) {
      case '--' :
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
        r= a * -b;
        break;
      case '**' :
        r=pow(a,int.parse(b.toString()));
        break;
      case '/-':
        r = a / -b;
        break;
      case '%':
        r = a % b;
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
        if (variables.containsKey(a)) {
          variables[a]?.value = b;
        } else if (modelVariables.containsKey(a)) {
          modelVariables[a] = b;
        } else {
          print('assign $a = $b');
          variables[a] = VariableModel(a, b, true, null, DataType.dynamic,'');
        }
        r = b;
        break;
      case '<=':
        r = a <= b;
        break;
      case '>=':
        r = a >= b;
        break;
      case '>>':
        r= a>> b;
        break;
      case '<<':
        r= a<<b;
        break;
      case '&&':
        r = (a as bool) && (b as bool);
        break;
      case '||':
        r = (a as bool) || (b as bool);
        break;
      case '==':
        r = a == b;
        break;
      case '!=':
        r = a != b;
        break;
      default:
        error = true;

        print('error 3');
        r = null;
    }
    valueStack.push(r);
  }

  String? processString(String code) {
    while (code.contains('{{') && code.contains('}}')) {
      final si = code.indexOf('{{'), ei = code.indexOf('}}');
      if (si + 2 == ei) {
        return null;
        // return CodeOutput.right('No variables');
      }
      final variableName = code.substring(si + 2, ei);
      final value = process<String>(variableName, resolve: true);
      if (value != null) {
        code = code.replaceAll('{{$variableName}}', value.toString());
      } else {
        return code; //CodeOutput.right('No varaible with name $variableName')
      }
    }
    return code;
  }

  dynamic process<T>(final String inputWithoutTrim, {bool resolve = false}) {
    final Stack2<dynamic> valueStack = Stack2<dynamic>();
    final Stack2<String> operatorStack = Stack2<String>();
    String number = '';
    String variable = '';
    error = false;
    if ((T == String||T == ImageData) && !resolve) {
      return processString(inputWithoutTrim);
    }else if(T == Color && inputWithoutTrim.startsWith('#')){
      return inputWithoutTrim;
    }
    else if(inputWithoutTrim.contains('{{')){
      return null;
    }
    final String input=inputWithoutTrim.replaceAll(' ','');
    for (int n = 0; n < input.length; n++) {
      if (error) {
        return null;
      }
      final String nextToken = input[n];
      final ch = nextToken.codeUnits.first;

      if ((ch >= zeroCodeUnit && ch <= nineCodeUnit) || ch == dotCodeUnit) {
        if (ch != dotCodeUnit && variable.isNotEmpty) {
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
          if (!functions.containsKey(variable)) {
            return null;
          }
          int count = 0;
          for (int m = n + 1; m < input.length; m++) {
            if (input[m] == '(') {
              count++;
            } else if (count == 0 && input[m] == ')') {
              if ((m-n-1)==0&&functions[variable] == null) {
                return null;
              }
              final argument =
              CodeOperations.splitByComma(input.substring(n + 1, m));
              valueStack.push(functions[variable]!
                  .perform
                  .call(argument.map((e) => process(e)).toList()));
              variable = '';
              n = m;
              break;
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
          if (n - 1 > 0 && isOperator(input[n - 1].codeUnits.first)) {
            operator = input[n - 1] + operator;
            operatorStack.pop();
          }
          if (operator == '=' && variable.isNotEmpty) {
            valueStack.push(variable);
            variable = '';
          }
          if (operatorStack.isEmpty ||
              getPrecedence(operator) > getPrecedence(operatorStack.peek!)) {
            operatorStack.push(operator);
          } else {
            while (operatorStack.isNotEmpty &&
                getPrecedence(operator) <= getPrecedence(operatorStack.peek!)) {
              final String pickOperator = operatorStack.peek!;
              operatorStack.pop();
              processOperator(pickOperator, valueStack, operatorStack);
            }
            operatorStack.push(operator);
          }
        } else if (ch == '('.codeUnits[0]) {
          final index = input.indexOf(')', n);
          if (index == -1) {
            return null;
          }
          final innerProcess =
          process<T>(input.substring(n + 1, index), resolve: true);
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

    // Empty out the operator stack at the end of the input
    while (operatorStack.isNotEmpty) {
      final String topOperator = operatorStack.pop()!;
      processOperator(topOperator, valueStack, operatorStack);
    }

    // Print the result if no error has been seen.
    if (!error && valueStack.isNotEmpty) {
      final result = valueStack.pop();

      if (operatorStack.isNotEmpty || valueStack.isNotEmpty) {
        print('Expression error.');
      } else {
        // debugPrint('The result is $input = $result');
        return result;
      }
    }
    return null;
  }

  bool resolveVariable(String variable, valueStack) {
    if (variables.containsKey(variable)) {
      valueStack.push(variables[variable]!.value);
    } else if (modelVariables.containsKey(variable)) {
      valueStack.push(modelVariables[variable]!);
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

/*
import 'dart:math' as math;

void main() {
  CodeProcessor cd = CodeProcessor();
  cd.modelVariables['name'] = 'Abrar';
  cd.modelVariables['a'] = 1;
  cd.modelVariables['ac'] = false;
  cd.variables['acd']= VariableModel('acd', false, true, null, DataType.dynamic);

  print(cd.process<String>('my name is {{name}} {{b=10}} {{a}}  {{randBool()}} '));

}

class CodeProcessor {
  final Map<String, VariableModel> variables = {};
  final Map<String, FunctionModel> functions = {};
  final Map<String, dynamic> modelVariables = {};

  late bool error;
  final capitalACodeUnit = 'A'.codeUnits.first,
      smallZCodeUnit = 'z'.codeUnits.first,
      underScoreCodeUnit = '_'.codeUnits.first;
  final zeroCodeUnit = '0'.codeUnits.first,
      nineCodeUnit = '9'.codeUnits.first,
      dotCodeUnit = '.'.codeUnits.first;

  CodeProcessor() {
    error = false;
    functions['res'] = FunctionModel<dynamic>('res', (arguments) {
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

    functions['if']=  FunctionModel<dynamic>('if', (arguments) {
      if(arguments.length>=2){
     if(arguments[0]==true){
       return arguments[1];
     }
        else if(arguments.length==3){
          return arguments[2];
        }
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

        functions['randInt']=  FunctionModel<dynamic>('randInt', (arguments) {
      if(arguments.length==1){
        return math.Random.secure().nextInt(arguments[0]??100);
      }

    }, '''
    double randInt(int max){
    return math.Random.secure().nextInt(max??100);
  }
    ''');

       functions['randDouble']=  FunctionModel<dynamic>('randDouble', (arguments) {
        return math.Random.secure().nextDouble();


    }, '''
    double randDouble(){
    return math.Random.secure().nextDouble();
  }
    ''');
      functions['randBool']=  FunctionModel<dynamic>('randBool', (arguments) {
        return math.Random.secure().nextBool();


    }, '''
    double randBool(){
    return math.Random.secure().nextBool();
  }
    ''');
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

  void processOperator(String t, valueStack, operatorStack) {
    bool error = false;
    dynamic a, b;
    if (valueStack.isEmpty) {
      error = true;
      print('error 1');
      return;
    } else {
      b = valueStack.peek!;
      valueStack.pop();
    }
    if (valueStack.isEmpty && t != '-') {
      error = true;

      print('error 2');
      return;
    } else if (valueStack.isNotEmpty) {
      a = valueStack.peek!;
      valueStack.pop();
    }
    late dynamic r;
    if (t == '+') {
      r = a + b;
    } else if (t == '-') {
      if (a == null) {
        r = -b;
      } else {
        r = a - b;
      }
    } else if (t == '*') {
      r = a * b;
    } else if (t == '/') {
      r = a / b;
    } else if (t == '~/') {
      r = a ~/ b;
    }  else if (t == '/-') {
      r = a /- b;
    } else if (t == '%') {
      r = a % b;
    } else if (t == '<') {
      r = a < b;
    } else if (t == '>') {
      r = a > b;
    } else if (t == '=') {
      if (variables.containsKey(a)) {
        variables[a]?.value = b;
      } else if (modelVariables.containsKey(a)) {
        modelVariables[a] = b;
      } else {
        print('= $b');
        variables[a] = VariableModel(a, b, true, null, DataType.dynamic);
      }
      r = b;
    } else if (t == '<=') {
      r = a <= b;
    } else if (t == '>=') {
      r = a >= b;
    } else if (t == '&&') {
      r = (a as bool) && (b as bool);
    } else if (t == '||') {
      r = (a as bool) || (b as bool);
    } else if (t == '==') {
      r = a == b;
    } else if (t == '!=') {
      r = a != b;
    } else {
      error = true;

      print('error 3');
      r = null;
    }
    valueStack.push(r);
  }

  String? processString(String code) {
    while (code.contains('{{') && code.contains('}}')) {
      final si = code.indexOf('{{'), ei = code.indexOf('}}');
      if (si + 2 == ei) {
        return null;
        // return CodeOutput.right('No variables');
      }
      final variableName = code.substring(si + 2, ei);
      final value = process<String>(variableName, resolve: true);
      if (value != null) {
        code = code.replaceAll('{{$variableName}}', value.toString());
      } else {
        return code; //CodeOutput.right('No varaible with name $variableName')
      }
    }
    return code;
  }

  dynamic process<T>(final String input, {bool resolve = false}) {
    final Stack2<dynamic> valueStack = Stack2<dynamic>();
    final Stack2<String> operatorStack = Stack2<String>();
    String number = '';
    String variable = '';
    error = false;
    if (T == String && !resolve) {
      return processString(input);
    }
    for (int n = 0; n < input.length; n++) {
      if (error) {
        return null;
      }
      final String nextToken = input[n];
      final ch = nextToken.codeUnits.first;

      if ((ch >= zeroCodeUnit && ch <= nineCodeUnit) || ch == dotCodeUnit) {
        if (ch != dotCodeUnit && variable.isNotEmpty) {
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
          if (!functions.containsKey(variable)) {
            return null;
          }
          int count = 0;
          for (int m = n + 1; m < input.length; m++) {
            if (input[m] == '(') {
              count++;
            }
            if (count == 0 && input[m] == ')') {
              if (functions[variable] == null) {
                return null;
              }
              final argument =
                  CodeOperations.splitByComma(input.substring(n + 1, m));

              return functions[variable]!
                  .perform
                  .call(argument.map((e) => process(e)).toList());
            } else if (input[m] == ')') {
              count--;
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
        }
        if (isOperator(ch)) {
          String operator = input[n];
          if (n - 1 > 0 && isOperator(input[n - 1].codeUnits.first)) {
            operator = input[n - 1] + operator;
            operatorStack.pop();
          }
          if (operator == '=') {
            valueStack.push(variable);
            variable = '';
          }
          if (operatorStack.isEmpty ||
              getPrecedence(operator) > getPrecedence(operatorStack.peek!)) {
            operatorStack.push(operator);
          } else {
            while (operatorStack.isNotEmpty &&
                getPrecedence(operator) <= getPrecedence(operatorStack.peek!)) {
              final String pickOperator = operatorStack.peek!;
              operatorStack.pop();
              processOperator(pickOperator, valueStack, operatorStack);
            }
            operatorStack.push(operator);
          }
        } else if (ch == '('.codeUnits[0]) {
          final index = input.indexOf(')', n);
          if (index == -1) {
            return null;
          }
          final innerProcess =
              process<T>(input.substring(n + 1, index), resolve: true);
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

    print('stacks ${valueStack} ${operatorStack._list}');
    // Empty out the operator stack at the end of the input
    while (operatorStack.isNotEmpty) {
      final String topOperator = operatorStack.peek!;
      operatorStack.pop();
      processOperator(topOperator, valueStack, operatorStack);
    }

    // Print the result if no error has been seen.
    if (!error && valueStack.isNotEmpty) {
      final result =valueStack.pop();

      if (operatorStack.isNotEmpty || valueStack.isNotEmpty) {
        print('Expression error.');
      } else {
        // debugPrint('The result is $input = $result');
        return result;
      }
    }
    return null;
  }

  bool resolveVariable(String variable, valueStack) {
    late dynamic value;
    if (variables.containsKey(variable)) {
      value = variables[variable]!.value;
    } else if (modelVariables.containsKey(variable)) {
      value = modelVariables[variable]!;
    } else {
      value = null;
      return false;
    }
    if (value == 'true') {
      valueStack.push(true);
    } else if (value == 'false') {
      valueStack.push(false);
    } else if (value != null) {
      valueStack.push(value);
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

class VariableModel {
  String name;
  dynamic value;
  final DataType dataType;
  bool runtimeAssigned;
  String? description;
  String? assignmentCode;
  final bool deletable;

  VariableModel(this.name, this.value, this.runtimeAssigned, this.description,
      this.dataType,
      {this.assignmentCode, this.deletable = true});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'deletable': deletable,
      'description': description,
      'dataType': dataType.name,
    };
  }

  factory VariableModel.fromJson(Map<String, dynamic> map) {
    return VariableModel(
        map['name'],
        map['value'],
        false,
        map['description'],
        map['dataType'] != null
            ? DataType.values
                .firstWhere((element) => element.name == map['dataType'])
            : DataType.double,
        deletable: map['deletable'] ?? true);
  }
}

class DynamicVariableModel {
  String name;
  DataType dataType;
  String? description;

  DynamicVariableModel(this.name, this.dataType, {this.description = ''});

  factory DynamicVariableModel.fromJson(Map<String, dynamic> json) {
    return DynamicVariableModel(
        json['name'],
        DataType.values
            .firstWhere((element) => element.name == json['dataType']),
        description: json['description']);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dataType': dataType.name,
      'description': description,
    };
  }
}

class FunctionModel<T> {
  final String name;
  final T Function(List<dynamic>) perform;
  final String functionCode;
  FunctionModel(this.name, this.perform, this.functionCode);
}

enum DataType { int, double, string, dynamic }

abstract class CodeOperations {
  static String? trim(String? code) {
    if (code == null) {
      return null;
    }
    final List<int> outputString = [];
    bool open = false;
    for (int i = 0; i < code.length; i++) {
      if (code[i] == '\'' || code[i] == '`') {
        open = !open;
      } else if (!open && (code[i] == ' ' || code[i] == '\n')) {
        continue;
      }
      outputString.add(code.codeUnitAt(i));
    }
    return String.fromCharCodes(outputString);
  }

  static List<String> splitByComma(String paramCode) {
    if (paramCode.startsWith('[') && paramCode.endsWith(']')) {
      paramCode = paramCode.substring(1, paramCode.length - 1);
    }
    int parenthesisCount = 0;
    final List<int> dividers = [-1];
    bool stringQuote = false;
    for (int i = 0; i < paramCode.length; i++) {
      if (paramCode[i] == '\'' || paramCode[i] == '`') {
        stringQuote = !stringQuote;
      }
      if (stringQuote) {
        continue;
      }
      if (paramCode[i] == ',' && parenthesisCount == 0) {
        dividers.add(i);
      } else if (paramCode[i] == '(' || paramCode[i] == '[') {
        parenthesisCount++;
      } else if (paramCode[i] == ')' || paramCode[i] == ']') {
        parenthesisCount--;
      }
    }
    final List<String> parameterCodes = [];
    for (int divideIndex = 0; divideIndex < dividers.length; divideIndex++) {
      if (divideIndex + 1 < dividers.length) {
        final subCode = paramCode.substring(
            dividers[divideIndex] + 1, dividers[divideIndex + 1]);
        if (subCode.isNotEmpty) {
          parameterCodes.add(subCode);
        }
      } else {
        final subCode = paramCode.substring(dividers[divideIndex] + 1);
        if (subCode.isNotEmpty) {
          parameterCodes.add(subCode);
        }
      }
    }

    return parameterCodes;
  }
}

* */
