import '../../code_to_component.dart';
import '../../ui/models_view.dart';

class FVBEngine {
  final Map<String, DataType> variables = {};

  String fvbToDart(String code) {
    final trimCode = CodeOperations.trim(code)!;
    int count = 0;
    int lastPoint = 0;
    String dartCode = '';
    for (int i = 0; i < trimCode.length; i++) {
      if (trimCode[i] == '{' || trimCode[i] == '[' || trimCode[i] == '(') {
        count++;
      } else if (trimCode[i] == '}' ||
          trimCode[i] == ']' ||
          trimCode[i] == ')') {
        count--;
      }
      if (count == 0 && (trimCode[i] == ';' || i + 1 == trimCode.length)) {
        String codeLine =
            trimCode.substring(lastPoint, trimCode[i] != ';' ? i + 1 : i);
        if (codeLine.trim().isEmpty) {
          continue;
        }
        int whileIndex;
        whileIndex = codeLine.indexOf('while');
        if (whileIndex == -1) {
          whileIndex = codeLine.indexOf('if');
        }
        if (whileIndex == -1) {
          whileIndex = codeLine.indexOf('else');
        }
        if (whileIndex != -1) {
          final openBracket = codeLine.indexOf('{', whileIndex);
          final closeBracket = CodeOperations.findCloseBracket(
              codeLine, openBracket, '{'.codeUnits.first, '}'.codeUnits.first);
          codeLine = codeLine.replaceRange(
            openBracket + 1,
            closeBracket,
            fvbToDart(
              codeLine.substring(openBracket + 1, closeBracket),
            ),
          );
        } else if ((whileIndex = codeLine.indexOf('delayed')) != -1) {
          final openCircleBracket = whileIndex + 7;
          final closeCircleBracket = CodeOperations.findCloseBracket(codeLine,
              openCircleBracket, '('.codeUnits.first, ')'.codeUnits.first);
          final openCurlyBracket = closeCircleBracket + 1;
          final closeCurlyBracket = CodeOperations.findCloseBracket(codeLine,
              openCurlyBracket, '{'.codeUnits.first, '}'.codeUnits.first);
          final timeCode =
              codeLine.substring(openCircleBracket + 1, closeCircleBracket);
          final bodyCode =
              codeLine.substring(openCurlyBracket + 1, closeCurlyBracket);
          codeLine = codeLine.replaceRange(whileIndex, closeCurlyBracket + 1,
              'Future.delayed(${fvbToDart(timeCode).replaceAll(';', '')},(){\n${fvbToDart(bodyCode)}\n})');
        } else {
          final int equalIndex = codeLine.indexOf('=');
          if (equalIndex != -1 && codeLine[equalIndex + 1] != '=') {
            final variable = codeLine.substring(0, equalIndex);
            if (!variables.containsKey(variable)) {
              variables[variable] = DataType.dynamic;
              codeLine = codeLine.replaceRange(0, equalIndex, 'var $variable');
            }
          }
          int lastIndex = 0;
          while (codeLine.contains('{{')) {
            int sIndex = codeLine.indexOf('{{', lastIndex + 2);
            int eIndex = codeLine.indexOf('}}', sIndex + 2);
            codeLine = codeLine.replaceAll(
                codeLine.substring(sIndex, eIndex + 2),
                '\${${codeLine.substring(sIndex + 2, eIndex)}}');
          }

          final int returnIndex = codeLine.indexOf('return');
          if (returnIndex != -1) {
            final int endIndex = codeLine.indexOf(')', returnIndex);
            codeLine = codeLine.replaceAll(
                codeLine.substring(returnIndex + 6, endIndex + 1),
                ' ${codeLine.substring(returnIndex + 7, endIndex)}');
          }
        }
        lastPoint = i + 1;
        if (codeLine.endsWith('}')) {
          dartCode += '$codeLine\n';
        } else {
          dartCode += '$codeLine;\n';
        }
      }
    }
    return dartCode;
  }
}
