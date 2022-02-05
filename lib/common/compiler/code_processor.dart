import 'dart:core';

import 'package:flutter/cupertino.dart';
import '../../models/variable_model.dart';

class CodeProcessor {
  final Map<String, VariableModel> variables = {};
  late Stack2<double> valueStack;
  late Stack2<int> operatorStack;
  late bool error;

  CodeProcessor() {
    operatorStack = Stack2<int>();
    valueStack = Stack2<double>();
    error = false;
  }

  void addVariable(String name, VariableModel value) {
    variables[name] = value;
  }

  bool isOperator(int ch) {
    return ch == '+'.codeUnits[0] ||
        ch == '-'.codeUnits[0] ||
        ch == '*'.codeUnits[0] ||
        ch == '/'.codeUnits[0];
  }

  int getPrecedence(int ch) {
    if (ch == '+'.codeUnits[0] || ch == '-'.codeUnits[0]) {
      return 1;
    }
    if (ch == '*'.codeUnits[0] || ch == '/'.codeUnits[0]) {
      return 2;
    }
    return 0;
  }

  void processOperator(String t) {
    double a, b;
    if (valueStack.isEmpty) {
      error = true;
      return;
    } else {
      b = valueStack.peek!;
      valueStack.pop();
    }
    if (valueStack.isEmpty) {
      error = true;
      return;
    } else {
      a = valueStack.peek!;
      valueStack.pop();
    }
    double r = 0;
    if (t == '+') {
      r = a + b;
    } else if (t == '-') {
      r = a - b;
    } else if (t == '*') {
      r = a * b;
    } else if (t == '/') {
      r = a / b;
    } else {
      error = true;
    }
    valueStack.push(r);
  }

  double? process(final String input) {
    operatorStack.clear();
    valueStack.clear();
    String number = '';
    String variable = '';
    error=false;
    for (int n = 0; n < input.length; n++) {
      if(error){
        return null;
      }
      final String nextToken = input[n];
      final ch = nextToken.codeUnits.first;

      if ((ch >= '0'.codeUnits.first && ch <= '9'.codeUnits.first) ||
          ch == '.'.codeUnits.first) {
        number += nextToken;
      } else if ((ch >= 'A'.codeUnits.first && ch <= 'z'.codeUnits.first)) {
        variable += nextToken;
      } else {
        if (number.isNotEmpty) {
          valueStack.push(double.parse(number));
          number = '';
        } else if (variable.isNotEmpty) {
          if(!variables.containsKey(variable)){
            return null;
          }
          valueStack.push(variables[variable]!.value);
          variable = '';
        }
        if (isOperator(ch)) {
          if (operatorStack.isEmpty ||
              getPrecedence(ch) > getPrecedence(operatorStack.peek!)) {
            operatorStack.push(ch);
          } else {
            while (operatorStack.isNotEmpty &&
                getPrecedence(ch) <= getPrecedence(operatorStack.peek!)) {
              int toProcess = operatorStack.peek!;
              operatorStack.pop();
              processOperator(String.fromCharCode(toProcess));
            }
            operatorStack.push(ch);
          }
        } else if (ch == '('.codeUnits[0]) {
          operatorStack.push(ch);
        } else if (ch == ')'.codeUnits[0]) {
          while (operatorStack.isNotEmpty && isOperator(operatorStack.peek!)) {
            int toProcess = operatorStack.peek!;
            operatorStack.pop();
            processOperator(String.fromCharCode(toProcess));
          }
          if (operatorStack.isNotEmpty &&
              operatorStack.peek == '('.codeUnits[0]) {
            operatorStack.pop();
          } else {
            return null;
          }
        }
      }
    }
    if (number.isNotEmpty) {
      valueStack.push(double.parse(number));
      number = '';
    } else if (variable.isNotEmpty) {
      if(!variables.containsKey(variable)){
        return null;
      }
      valueStack.push(variables[variable]!.value);
      variable = '';
    }
    // Empty out the operator stack at the end of the input
    while (operatorStack.isNotEmpty && isOperator(operatorStack.peek!)) {
      final int toProcess = operatorStack.peek!;
      operatorStack.pop();
      processOperator(String.fromCharCode(toProcess));
    }
    // Print the result if no error has been seen.
    if (!error) {
      final double? result = valueStack.peek;
      valueStack.pop();
      if (operatorStack.isNotEmpty || valueStack.isNotEmpty) {
        debugPrint('Expression error.');
      } else {
        debugPrint('The result is $input = $result');
        return result;
      }
    }
  }
}

class Stack2<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

  E? pop() => isNotEmpty?_list.removeLast():null;

  E? get peek => isNotEmpty?_list.last:null;

  bool get isEmpty => _list.isEmpty;

  bool get isNotEmpty => _list.isNotEmpty;

  void clear(){
    _list.clear();
  }
  @override
  String toString() => _list.toString();
}
