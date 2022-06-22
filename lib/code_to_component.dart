import 'common/compiler/code_processor.dart';
import 'ui/models_view.dart';

abstract class CodeOperations {
  static String? trim(String? code, {bool removeBackSlash = true}) {
    if (code == null) {
      return null;
    }
    final List<int> outputString = [];
    bool openString = false;
    code = code.replaceAll(' in ', ':');
    for (int i = 0; i < code.length; i++) {
      if (code[i] == '\'' ||
          code[i] == '"' ||
          code[i] == '`' ||
          (code[i] == '{' && i < code.length - 1 && code[i + 1] == '{') ||
          (code[i] == '}' && i < code.length - 1 && code[i + 1] == '}')) {
        openString = !openString;
      } else if (!openString && (code[i] == ' ' || (removeBackSlash && code[i] == '\n'))) {
        continue;
      }
      outputString.add(code.codeUnitAt(i));
    }
    return String.fromCharCodes(outputString);
  }

  static String? trimAvoidSingleSpace(String? code) {
    if (code == null) {
      return null;
    }
    final List<int> outputString = [];
    bool openString = false;
    int spaceCount = 0;
    code = code.replaceAll(' in ', ':');
    for (int i = 0; i < code.length; i++) {
      if (code[i] != ' ') {
        if (spaceCount >= 1) {
          if (i - spaceCount - 1 >= 0 &&
              isVariableChar(code[i].codeUnits.first) &&
              isVariableChar(code[i - spaceCount - 1].codeUnits.first)) {
            outputString.add('~'.codeUnits.first);
          } else {
            outputString.add(' '.codeUnits.first);
          }
        }
        spaceCount = 0;
      }
      if (code[i] == '\'' ||
          code[i] == '"' ||
          code[i] == '`' ||
          (code[i] == '{' && i < code.length - 1 && code[i + 1] == '{') ||
          (code[i] == '}' && i < code.length - 1 && code[i + 1] == '}')) {
        openString = !openString;
      } else if (!openString) {
        if (code[i] == ' ') {
          spaceCount++;
          continue;
        } else if (code[i] == '\n') {
          continue;
        }
      }
      outputString.add(code.codeUnitAt(i));
    }
    return String.fromCharCodes(outputString);
  }

  static bool isVariableChar(final int codeUnit) {
    return (codeUnit >= CodeProcessor.capitalACodeUnit && codeUnit <= CodeProcessor.smallZCodeUnit) ||
        (codeUnit >= CodeProcessor.zeroCodeUnit && codeUnit <= CodeProcessor.nineCodeUnit) ||
        codeUnit == CodeProcessor.underScoreCodeUnit;
  }

  static String? checkSyntaxInCode(String code) {
    int roundCount = 0;
    int squareCount = 0;
    int curlyCount = 0;
    bool doubleQuote = false;
    bool singleQuote = false;
    for (int i = 0; i < code.length; i++) {
      final a = code[i];
      switch (a) {
        case '"':
          doubleQuote = !doubleQuote;
          break;
        case '\'':
          singleQuote = !singleQuote;
          break;
        case '(':
          roundCount++;
          break;
        case ')':
          roundCount--;
          break;
        case '[':
          squareCount++;
          break;
        case ']':
          squareCount--;
          break;
        case '{':
          curlyCount++;
          break;
        case '}':
          curlyCount--;
          break;
      }
    }
    if (roundCount != 0) {
      if (roundCount > 0) {
        return 'Missing closing round bracket';
      } else {
        return 'Missing opening round bracket';
      }
    }
    if (squareCount != 0) {
      if (squareCount > 0) {
        return 'Missing closing square bracket';
      } else {
        return 'Missing opening square bracket';
      }
    }
    if (curlyCount != 0) {
      if (curlyCount > 0) {
        return 'Missing closing curly bracket';
      } else {
        return 'Missing opening curly bracket';
      }
    }
    if (doubleQuote) {
      return 'Missing closing double quote';
    }
    if (singleQuote) {
      return 'Missing closing single quote';
    }
    return null;
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

      case DataType.iterable:
        return Iterable;
      case DataType.fvbInstance:
        return FVBInstance;
      case DataType.fvbFunction:
        return FVBFunction;
    }
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
    throw Exception('No close bracket found ${String.fromCharCode(closeBracket)}');
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
      } else if (paramCode[i] == '(' || paramCode[i] == '[' || paramCode[i] == '{') {
        parenthesisCount++;
      } else if (paramCode[i] == ')' || paramCode[i] == ']' || paramCode[i] == '}') {
        parenthesisCount--;
      }
    }
    final List<String> parameterCodes = [];
    for (int divideIndex = 0; divideIndex < dividers.length; divideIndex++) {
      if (divideIndex + 1 < dividers.length) {
        final subCode = paramCode.substring(dividers[divideIndex] + 1, dividers[divideIndex + 1]);
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
