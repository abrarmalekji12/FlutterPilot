

abstract class CodeToComponent {

  static List<String> splitByComma(String paramCode){
    int parenthesisCount = 0;
    final List<int> dividers = [-1];
    for (int i = 0; i < paramCode.length; i++) {
      if (paramCode[i] == ',' && parenthesisCount==0) {
        dividers.add(i);
      } else if (paramCode[i] == '(') {
        parenthesisCount++;
      } else if (paramCode[i] == ')') {
        parenthesisCount--;
      }
    }
    List<String> parameterCodes = [];
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