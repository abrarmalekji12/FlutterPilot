import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/constants/processor_constant.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';

import 'common/converter/string_operation.dart';

enum QuoteType { single, double, back }

abstract class CodeOperations {
  static String? trim(String? code, {bool removeBackSlash = true}) {
    if (code == null) {
      return null;
    }
    final List<int> outputString = [];
    bool openSingleQuote = false;
    bool openDoubleQuote = false;
    bool openBackQuote = false;
    bool enable = true;
    final codeUnits = code.codeUnits;
    for (int i = 0; i < code.length; i++) {
      final noBackslash = i == 0 || codeUnits[i - 1] != backslashCodeUnit;
      if ((!openDoubleQuote) &&
          !openBackQuote &&
          (codeUnits[i] == singleQuoteCodeUnit && noBackslash)) {
        openSingleQuote = !openSingleQuote;
        enable = !openSingleQuote;
      } else if (!openSingleQuote &&
          !openBackQuote &&
          codeUnits[i] == doubleQuoteCodeUnit &&
          noBackslash) {
        openDoubleQuote = !openDoubleQuote;
        enable = !openDoubleQuote;
      } else if (code[i] == '`') {
        openBackQuote = !openBackQuote;
        enable = !openBackQuote;
      } else if (!openBackQuote &&
          (codeUnits[i] == dollarCodeUnit &&
              i < code.length - 1 &&
              codeUnits[i + 1] == curlyBracketOpen)) {
        final endIndex = CodeOperations.findCloseBracket(
            code, i + 1, curlyBracketOpen, curlyBracketClose);
        if (endIndex != null) {
          final subCode = trim(code.substring(i + 2, endIndex));
          outputString.addAll(extendedStringFormatterOpen);
          outputString.addAll(subCode?.codeUnits ?? []);
          i = endIndex;
        }
      } else if (enable &&
          (codeUnits[i] == realSpaceCodeUnit ||
              (removeBackSlash && codeUnits[i] == backslashNCodeUnit))) {
        continue;
      }
      outputString.add(code.codeUnitAt(i));
    }
    final output = String.fromCharCodes(outputString);
    return output;
  }

  static jsonToModel(dynamic map, Processor processor, String name) {
    if (map is List) {
      return List.generate(
          map.length, (index) => jsonToModel(map[index], processor, name));
    }
    if (map is Map<String, dynamic>) {
      final values = map.entries
          .map((e) => jsonToModel(
              e.value, processor, StringOperation.capitalize(e.key)))
          .toList();
      return FVBModelClass.create(name, vars: {
        for (int i = 0; i < map.entries.length; i++)
          map.entries.elementAt(i).key.toString(): () => FVBVariable(
                map.entries.elementAt(i).key.toString(),
                DataType.fromValue(values[i]),
              ),
      }, funs: [
        FVBFunction(name, '', [
          for (final entry in map.keys) FVBArgument('this.$entry'),
        ])
      ]).createInstance(
        processor,
        values,
      );
    }
    return map;
  }

  static FVBModelClass? jsonToClass(dynamic map, String name) {
    if (map is List) {
      return null;
    }
    if (map is Map<String, dynamic>) {
      final values = map.entries
          .map((e) => jsonToClass(e.value, StringOperation.capitalize(e.key)))
          .toList();
      return FVBModelClass.create(name, vars: {
        for (int i = 0; i < map.entries.length; i++)
          map.entries.elementAt(i).key.toString(): () => FVBVariable(
                map.entries.elementAt(i).key.toString(),
                DataType.fromValue(values[i]),
              ),
      }, funs: [
        FVBFunction(name, '', [
          for (final entry in map.keys) FVBArgument('this.$entry'),
        ])
      ]);
    }
    return map;
  }

  static String? trimAvoidSingleSpace(String? code) {
    if (code == null) {
      return null;
    }
    final List<int> outputString = [];
    bool openSingleQuote = false;
    bool openDoubleQuote = false;
    bool openBackQuote = false;
    int spaceCount = 0;
    bool enable = true;
    for (int i = 0; i < code.length; i++) {
      if (code[i] != ' ') {
        if (spaceCount >= 1) {
          if (i - spaceCount - 1 >= 0 &&
              isVariableChar(code[i].codeUnits.first) &&
              isVariableChar(code[i - spaceCount - 1].codeUnits.first)) {
            outputString.add(spaceReplacementCodeUnit);
          } else {
            outputString.add(' '.codeUnits.first);
          }
        }
        spaceCount = 0;
      }
      final noBackslash = i == 0 || code[i - 1] != '\\';
      if (!openDoubleQuote &&
          !openBackQuote &&
          code[i] == '\'' &&
          noBackslash) {
        openSingleQuote = !openSingleQuote;
        enable = !openSingleQuote;
      } else if ((!openSingleQuote) &&
          !openBackQuote &&
          code[i] == '"' &&
          noBackslash) {
        openDoubleQuote = !openDoubleQuote;
        enable = !openDoubleQuote;
      } else if (code[i] == '`') {
        openBackQuote = !openBackQuote;
        enable = !openBackQuote;
      } else if (!openBackQuote &&
          ((code[i] == '\$' && i < code.length - 1 && code[i + 1] == '{'))) {
        final endIndex = CodeOperations.findCloseBracket(
            code, i + 1, curlyBracketOpen, curlyBracketClose);
        if (endIndex != null) {
          final subCode = trimAvoidSingleSpace(code.substring(i + 2, endIndex));
          outputString.addAll(extendedStringFormatterOpen);
          outputString.addAll(subCode?.codeUnits ?? []);
          i = endIndex;
        }
        // if (code[i] == '\$') {
        //   openStringFormat = true;
        //   enable = true;
        // } else if (openStringFormat) {
        //   openStringFormat = false;
        //   enable = false;
        // }
      } else if (enable) {
        if (code[i] == ' ') {
          spaceCount++;
          continue;
        } else if (code[i] == '\n') {
          continue;
        }
      }
      outputString.add(code.codeUnitAt(i));
    }

    final finalCode = String.fromCharCodes(outputString)
        .replaceAll('${space}in$space', ':')
        .replaceAll('${space}is$space', '.runtimeType==');
    return finalCode;
  }

  static bool isVariableChar(final int codeUnit) {
    return (codeUnit >= capitalACodeUnit && codeUnit <= capitalZCodeUnit) ||
        (codeUnit >= smallACodeUnit && codeUnit <= smallZCodeUnit) ||
        (codeUnit >= zeroCodeUnit && codeUnit <= nineCodeUnit) ||
        [underScoreCodeUnit, singleQuoteCodeUnit, doubleQuoteCodeUnit]
            .contains(codeUnit);
  }

  static bool isValidVariableStartingChar(final int codeUnit) {
    return (codeUnit >= capitalACodeUnit && codeUnit <= smallZCodeUnit) ||
        underScoreCodeUnit == codeUnit;
  }

  static int backslashCount(String code, int index) {
    int i = index;
    while (i >= 0 && code[i] == '\\') {
      i--;
    }
    return index - i;
  }

  static String? checkSyntaxInCode(String code) {
    int roundCount = 0;
    int squareCount = 0;
    int curlyCount = 0;
    bool doubleQuote = false;
    bool singleQuote = false;
    bool stringBracketOpen = false;
    int? stringOpenIndex;
    for (int i = 0; i < code.length; i++) {
      final a = code[i];
      switch (a) {
        case '"':
          if (!singleQuote && backslashCount(code, i - 1) % 2 == 0) {
            doubleQuote = !doubleQuote;
          }
          break;
        case '\'':
          if (!doubleQuote && backslashCount(code, i - 1) % 2 == 0) {
            singleQuote = !singleQuote;
          }
          break;
        case '(':
          if (!doubleQuote && !singleQuote) {
            roundCount++;
          }
          break;
        case ')':
          if (!doubleQuote && !singleQuote) {
            roundCount--;
          }
          break;
        case '[':
          if (!doubleQuote && !singleQuote) {
            squareCount++;
          }
          break;
        case ']':
          if (!doubleQuote && !singleQuote) {
            squareCount--;
          }
          break;
        case '{':
          if ((!doubleQuote && !singleQuote)) {
            curlyCount++;
          } else if (i > 0 &&
              code[i - 1] == '\$' &&
              backslashCount(code, i - 2) % 2 == 0) {
            stringBracketOpen = true;
            stringOpenIndex = i + 1;
          }
          break;
        case '}':
          if (!doubleQuote && !singleQuote) {
            curlyCount--;
          } else if (stringBracketOpen) {
            stringBracketOpen = false;
            if (i <= code.length && i - stringOpenIndex! >= 1) {
              final output =
                  checkSyntaxInCode(code.substring(stringOpenIndex, i));
              if (output != null) {
                return output;
              }
            }
          }
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
    if (stringBracketOpen) {
      return 'Missing curly bracket in string format';
    }
    if (doubleQuote) {
      return 'Missing closing double quote';
    }
    if (singleQuote) {
      return 'Missing closing single quote';
    }
    return null;
  }

  static getRuntimeTypeWithoutGenerics(dynamic value) {
    if (value is FVBTest) {
      return value.dataType.name;
    }
    if (value is Map) {
      return 'Map';
    }
    if (value is List) {
      return 'List';
    }
    if (value is int) {
      return 'int';
    }
    if (value is Iterable) {
      return 'Iterable';
    }
    if (value is double) {
      return 'double';
    }
    final name = value.runtimeType.toString();
    final genericIndex = name.indexOf('<');
    return name.substring(0, genericIndex > 0 ? genericIndex : name.length);
  }

  static getDatatypeToDartType(final DataType dataType) {
    if (dataType.fvbName == 'List') {
      return List;
    } else if (dataType.fvbName == 'Map') {
      return Map;
    } else if (dataType.fvbName == 'Iterable') {
      return Iterable;
    }
    if (dataType.name == 'fvbInstance') {
      return dataType.fvbName;
    }
    switch (dataType) {
      case DataType.fvbInt:
        return int;
      case DataType.fvbDouble:
        return double;
      case DataType.string:
        return String;
      case DataType.fvbBool:
        return bool;
      case DataType.fvbDynamic:
        return dynamic;
      case DataType.fvbFunction:
        return FVBFunction;
      case DataType.unknown:
        return null;
    }
  }

  static int findChar(
      String input, int startIndex, int target, List<int> stopWhen,
      {bool Function(int)? stop}) {
    int count = 0;
    for (int i = startIndex + 1; i < input.length; i++) {
      final unit = input[i].codeUnits.first;
      if (unit == target) {
        if (count == 0) {
          return i;
        }
      }
      if (stopWhen.contains(unit) || (stop?.call(unit) ?? false)) {
        return -1;
      }
      if (unit == roundBracketOpen ||
          unit == squareBracketOpen ||
          unit == curlyBracketOpen) {
        count++;
      } else if (unit == roundBracketClose ||
          unit == squareBracketClose ||
          unit == curlyBracketClose) {
        count--;
      }
    }
    return -1;
  }

  static int? findCloseBracket(
    String input,
    int openIndex,
    int openBracket,
    int closeBracket,
  ) {
    int count = 0;
    bool stringOpen = false;
    for (int i = openIndex + 1; i < input.length; i++) {
      final unit = input[i].codeUnits.first;
      if ((unit == doubleQuoteCodeUnit || unit == singleQuoteCodeUnit) &&
          input[i - 1].codeUnits.first != backslashCodeUnit) {
        stringOpen = !stringOpen;
      }
      if (stringOpen) {
        continue;
      }
      if (unit == closeBracket) {
        if (count == 0) {
          return i;
        }
        count--;
      } else if (unit == openBracket) {
        count++;
      }
    }
    return null;
  }

  static int findCloseBracketStringCheckDisabled(
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

    return -1;
  }

  static List<String> splitBy(String paramCode, {int splitBy = commaCodeUnit}) {
    // if (paramCode[0]=='[' && paramCode[paramCode.length-1]==']') {
    //   paramCode = paramCode.substring(1, paramCode.length - 1);
    // }
    int parenthesisCount = 0;
    final List<int> dividers = [-1];
    bool stringQuote = false;
    QuoteType? type;
    for (int i = 0; i < paramCode.length; i++) {
      final unit = paramCode[i].codeUnits.first;
      if (unit == singleQuoteCodeUnit ||
          unit == doubleQuoteCodeUnit ||
          unit == backQuoteCodeUnit) {
        if (stringQuote) {
          if (((type == QuoteType.double && unit == doubleQuoteCodeUnit) ||
              (type == QuoteType.single && unit == singleQuoteCodeUnit) ||
              (type == QuoteType.back && unit == backQuoteCodeUnit))) {
            stringQuote = false;
          }
        } else {
          stringQuote = true;
          type = (unit == doubleQuoteCodeUnit)
              ? QuoteType.double
              : ((unit == singleQuoteCodeUnit)
                  ? QuoteType.single
                  : QuoteType.back);
        }
      }
      if (stringQuote) {
        continue;
      }
      if (unit == splitBy && parenthesisCount == 0) {
        dividers.add(i);
      } else if (unit == roundBracketOpen ||
          unit == squareBracketOpen ||
          unit == curlyBracketOpen) {
        parenthesisCount++;
      } else if (unit == roundBracketClose ||
          unit == squareBracketClose ||
          unit == curlyBracketClose) {
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
