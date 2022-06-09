import 'package:get/get.dart';

import 'common/compiler/code_processor.dart';
import 'common/logger.dart';
import 'ui/models_view.dart';

abstract class CodeOperations {
  static String? trim(String? code, {bool removeBackSlash = true}) {
    if (code == null) {
      return null;
    }
    final List<int> outputString = [];
    bool openString = false;
    for (int i = 0; i < code.length; i++) {
      if (code[i] == '\'' ||
          code[i] == '"' ||
          code[i] == '`' ||
          (code[i] == '{' && i < code.length - 1 && code[i + 1] == '{') ||
          (code[i] == '}' && i < code.length - 1 && code[i + 1] == '}')) {
        openString = !openString;
      } else if (!openString &&
          (code[i] == ' ' || (removeBackSlash && code[i] == '\n'))) {
        continue;
      }
      outputString.add(code.codeUnitAt(i));
    }
    return String.fromCharCodes(outputString);
  }

  static getDatatypeToDartType(DataType dataType) {
    switch (dataType) {
      case DataType.int:
        return int;
      case DataType.double:
        return double;
      case DataType.string:
        return String;
      case DataType.bool:
        return bool;
      case DataType.dynamic:
        return dynamic;
      case DataType.list:
        return List;
      case DataType.map:
        return Map;
      case DataType.fvbInstance:
        return FVBInstance;
      case DataType.fvbFunction:
       return FVBFunction;
    }
  }

  static List<String> getFVBInstructionsFromCode(String code) {
    final trimCode = CodeOperations.trim(code)!;
    int count = 0, lastPoint = 0;
    final List<String> instructions = [];
    for (int i = 0; i < trimCode.length; i++) {
      if (trimCode[i] == '{' || trimCode[i] == '[' || trimCode[i] == '(') {
        count++;
      } else if (trimCode[i] == '}' ||
          trimCode[i] == ']' ||
          trimCode[i] == ')') {
        count--;
      }
      if (count == 0 && (trimCode[i] == ';' || trimCode.length == i + 1)) {
        instructions
            .add(trimCode.substring(lastPoint, trimCode[i] == ';' ? i : i + 1));
        lastPoint = i + 1;
      }
    }
    return instructions;
  }

  static int findCloseBracket(
    String input,
    int openIndex,
    int openBracket,
    int closeBracket,
  ) {
    int count = 0;
    for (int i = openIndex + 1; i < input.length; i++) {
      final unit = input[i].codeUnits.first;
      if (unit == closeBracket) {
        if (count == 0) {
          return i;
        }
        count--;
      } else if (unit == openBracket) {
        count++;
      }
    }
    throw Exception(
        'No close bracket found ${String.fromCharCode(closeBracket)}');
  }

  static List<String> splitBy(String paramCode, {String splitBy = ','}) {
    // if (paramCode[0]=='[' && paramCode[paramCode.length-1]==']') {
    //   paramCode = paramCode.substring(1, paramCode.length - 1);
    // }
    int parenthesisCount = 0;
    final List<int> dividers = [-1];
    bool stringQuote = false;
    for (int i = 0; i < paramCode.length; i++) {
      if (paramCode[i] == '\'' || paramCode[i] == '"' || paramCode[i] == '`') {
        stringQuote = !stringQuote;
      }
      if (stringQuote) {
        continue;
      }
      if (paramCode[i] == splitBy && parenthesisCount == 0) {
        dividers.add(i);
      } else if (paramCode[i] == '(' ||
          paramCode[i] == '[' ||
          paramCode[i] == '{') {
        parenthesisCount++;
      } else if (paramCode[i] == ')' ||
          paramCode[i] == ']' ||
          paramCode[i] == '}') {
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
