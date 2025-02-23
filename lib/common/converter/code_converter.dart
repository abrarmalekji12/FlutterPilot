import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/constants/processor_constant.dart';

import '../../code_operations.dart';

class AppendString {
  final String string;
  final int index;

  AppendString(this.string, this.index);
}

class FunctionModifier {
  final String returnType;
  final String body;

  FunctionModifier(this.returnType, this.body);
}

class FVBEngine {
  final Map<String, DataType> variables = {};
  static FVBEngine? _instance;

  static FVBEngine get instance => _instance ??= FVBEngine._();

  FVBEngine._();

  String getDartCode(Processor processor, String code,
      FunctionModifier? Function(String) appendInMethod) {
    String cleanCode = Processor.cleanCode(code, processor) ?? '';
    String charName = '';
    String beforeCharName = '';
    final List<AppendString> list = [];
    try {
      for (int i = 0; i < cleanCode.length; i++) {
        if (cleanCode[i] == '(') {
          final closeIndex = CodeOperations.findCloseBracket(
              cleanCode, i, roundBracketOpen, roundBracketClose);
          if (closeIndex == null) {
            return '';
          }
          if (charName == processor.scopeName) {
            int? endIndex;
            if (cleanCode[closeIndex + 1] == '{') {
              endIndex = CodeOperations.findCloseBracket(cleanCode,
                  closeIndex + 1, curlyBracketOpen, curlyBracketClose);
              if (endIndex == null) {
                return '';
              }
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
          if (cleanCode.length > closeIndex + 1 &&
              cleanCode[closeIndex + 1] == '{') {
            final appendString = appendInMethod.call(charName);
            if (appendString != null) {
              final closeBracketIndex = CodeOperations.findCloseBracket(
                  cleanCode,
                  closeIndex + 1,
                  curlyBracketOpen,
                  curlyBracketClose);
              if (closeBracketIndex == null) {
                return '';
              }
              list.add(AppendString(
                  appendString.returnType, i - charName.length - 1));
              if (beforeCharName.isNotEmpty &&
                  i - charName.length - beforeCharName.length - 1 >= 0) {
                cleanCode = cleanCode.replaceRange(
                    i - charName.length - beforeCharName.length - 1,
                    i - charName.length - 1,
                    ' ' * beforeCharName.length);
                beforeCharName = '';
              }
              list.add(AppendString(appendString.body, closeBracketIndex));
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
    int curlyBracketCount = 0;
    bool openString = false;
    int? classBlockStart;
    String variableName = '';
    for (int i = 0; i < code.length; i++) {
      if (code[i] == ':') {
        colonIndexList.add(i);
      } else if (code[i] == '{') {
        curlyBracketCount++;
      } else if (code[i] == '}') {
        curlyBracketCount--;
        if (curlyBracketCount == classBlockStart) {
          classBlockStart = null;
        }
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
          classBlockStart = curlyBracketCount;
        }
      } else {
        variableName = '';
      }
      if (i + 1 < code.length && code[i] == '{' && code[i + 1] == '{') {
        int sIndex = i;
        int? eIndex = CodeOperations.findCloseBracket(
            code, i + 1, '{'.codeUnits.first, '}'.codeUnits.first);
        if (eIndex == null) {
          return '';
        }
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
