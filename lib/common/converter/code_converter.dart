import 'package:dart_style/dart_style.dart';

import '../../code_to_component.dart';
import '../../ui/models_view.dart';

class FVBEngine {
  final Map<String, DataType> variables = {};

  String fvbToDart(String code) {
    String dartCode = '';
    final List<int> colonIndexList = [];
    int roundBracketCount = 0;
    int curlyBracketCount = 0;
    int squareBracketCount = 0;
    bool openString = false;
    bool classBlock = false;
    int? classBlockStart;
    String variableName = '';
    for (int i = 0; i < code.length; i++) {
      if (code[i] == ':') {
        colonIndexList.add(i);
      } else if (code[i] == '(') {
        roundBracketCount++;
      } else if (code[i] == ')') {
        roundBracketCount--;
      } else if (code[i] == '{') {
        curlyBracketCount++;
      } else if (code[i] == '}') {
        curlyBracketCount--;
        if (curlyBracketCount == classBlockStart) {
          classBlock = false;
          classBlockStart = null;
        }
      } else if (code[i] == '[') {
        squareBracketCount++;
      } else if (code[i] == ']') {
        squareBracketCount--;
      } else if (code[i] == '"') {
        openString = !openString;
      } else if (code[i] == '\'') {
        openString = !openString;
      }
      final charCode = code[i].codeUnits.first;
      if ((charCode >= 'A'.codeUnits.first &&
              charCode <= 'z'.codeUnits.first) ||
          (charCode >= '0'.codeUnits.first &&
              charCode <= '9'.codeUnits.first) ||
          code[i] == '_' ||
          code[i] == '~') {
        variableName += code[i];
        if (variableName == 'class') {
          classBlock = true;
          classBlockStart = curlyBracketCount;
        }
      } else {
        variableName = '';
      }
      if (i + 1 < code.length && code[i] == '{' && code[i + 1] == '{') {
        int sIndex = i;
        int eIndex = CodeOperations.findCloseBracket(
            code, i + 1, '{'.codeUnits.first, '}'.codeUnits.first);
        dartCode += '\${${code.substring(sIndex + 2, eIndex)}}';
        i = eIndex + 1;
        continue;
      }
      dartCode += code[i];
    }
    final DartFormatter formatter = DartFormatter();
    return '/** \n${formatter.format(dartCode)} \n**/';
  }

  String fvbLineToDart(String trimCode) {
    int count = 0;
    String dartCode = '';
    for (int i = 0; i < trimCode.length; i++) {
      if (trimCode[i] == '{' || trimCode[i] == '[' || trimCode[i] == '(') {
        count++;
      } else if (trimCode[i] == '}' ||
          trimCode[i] == ']' ||
          trimCode[i] == ')') {
        count--;
      }
      if (count == 0 && trimCode[i] == ':') {
        dartCode = '${trimCode.substring(i + 1)} ${trimCode.substring(0, i)}';
        return dartCode;
      }

      dartCode += trimCode[i];
    }
    if (count != 0) {
      throw Exception('Unmatched brackets');
    }
    return dartCode;
  }
}
