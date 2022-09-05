import 'package:dart_style/dart_style.dart';

import '../../code_to_component.dart';
import '../compiler/code_processor.dart';
import '../compiler/constants.dart';

class AppendString {
  final String string;
  final int index;

  AppendString(this.string, this.index);
}

class FVBEngine {
  final Map<String, DataType> variables = {};
  static FVBEngine? _instance;

  static FVBEngine get instance => _instance ??= FVBEngine._();

  FVBEngine._();

  String getDartCode(CodeProcessor processor, String code,
      String? Function(String) appendInMethod) {
    String cleanCode = CodeProcessor.cleanCode(code, processor) ?? '';
    String charName = '';
    String beforeCharName = '';
    final List<AppendString> list = [];
    try {
      for (int i = 0; i < cleanCode.length; i++) {
        if (cleanCode[i] == '(') {
          final closeIndex = CodeOperations.findCloseBracket(cleanCode, i,
              CodeProcessor.roundBracketOpen, CodeProcessor.roundBracketClose);
          if (charName == processor.scopeName) {
            int endIndex;
            if (cleanCode[closeIndex + 1] == '{') {
              endIndex = CodeOperations.findCloseBracket(
                  cleanCode,
                  closeIndex + 1,
                  CodeProcessor.curlyBracketOpen,
                  CodeProcessor.curlyBracketClose);
            } else {
              endIndex = closeIndex + 1;
            }
            cleanCode =
                cleanCode.replaceRange(0, endIndex + 1, ' ' * (endIndex + 1));
            i = endIndex;
            beforeCharName = '';
            charName = '';
            continue;
          }
          if (cleanCode.length>closeIndex+1&&cleanCode[closeIndex + 1] == '{') {
            final appendString = appendInMethod.call(charName);
            if (appendString != null) {
              final closeBracketIndex = CodeOperations.findCloseBracket(
                  cleanCode,
                  closeIndex + 1,
                  CodeProcessor.curlyBracketOpen,
                  CodeProcessor.curlyBracketClose);

              if (beforeCharName.isNotEmpty &&
                  i - charName.length - beforeCharName.length - 1 >= 0) {
                  cleanCode = cleanCode.replaceRange(
                      i - charName.length - beforeCharName.length - 1,
                      i - charName.length - 1,
                      ' ' * beforeCharName.length);
                beforeCharName = '';
              }

              list.add(AppendString(appendString, closeBracketIndex));
              i = closeBracketIndex;
              charName = '';
              continue;
            }
          }
          i = closeIndex;
          charName = '';
          continue;
        }
        if (cleanCode[i] == space) {
          beforeCharName = charName;
          charName = '';
        } else {
          if (CodeOperations.isVariableChar(cleanCode[i].codeUnits.first)) {
            charName += cleanCode[i];
          } else {
            beforeCharName = '';
            charName = '';
          }
        }
      }
    } catch (e) {
      print('ERROR $e');
    }
    int index = 0;
    for (final append in list) {
      cleanCode = cleanCode.substring(0, index + append.index) +
          append.string +
          cleanCode.substring(index + append.index);
      index += append.string.length;
    }
    // processor.execute(cleanCode,declarativeOnly: true);
    return fvbToDart(cleanCode.replaceAll(space, ' '));
  }

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
          code[i] == space) {
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
    // final DartFormatter formatter = DartFormatter();
    // formatter.format(
    return '\n$dartCode\n';
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
