import 'common/logger.dart';

abstract class CodeOperations {
  static String? trim(String? code) {
    if (code == null) {
      return null;
    }
    final List<int> outputString = [];
    bool open = false;
    for (int i = 0; i < code.length; i++) {
      if (code[i] == '\''||code[i]=='`') {
        open = !open;
      } else if (!open && (code[i] == ' ' || code[i] == '\n')) {
        continue;
      }
      outputString.add(code.codeUnitAt(i));
    }
    return String.fromCharCodes(outputString);
  }

  static List<String> splitByComma(String paramCode) {
    if(paramCode.startsWith('[')&&paramCode.endsWith(']')){
      paramCode=paramCode.substring(1,paramCode.length-1);
    }
    int parenthesisCount = 0;
    final List<int> dividers = [-1];
    bool stringQuote=false;
    for (int i = 0; i < paramCode.length; i++) {
      if(paramCode[i]=='\''||paramCode[i]=='`'){
        stringQuote=!stringQuote;
      }
      if(stringQuote){
        continue;
      }
      if (paramCode[i] == ',' && parenthesisCount == 0) {
        dividers.add(i);
      }
      else if (paramCode[i] == '('||paramCode[i] == '[') {
        parenthesisCount++;
      } else if (paramCode[i] == ')'||paramCode[i] == ']') {
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
