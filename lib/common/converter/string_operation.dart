import 'package:fvb_processor/compiler/constants/processor_constant.dart';

class StringOperation {
  static final RegExp _upperAlphaRegex = RegExp(r'[A-Z]');

  static const symbolSet = {' ', '.', '/', '_', '\\', '-'};

  static String capitalize(String str) {
    if (str.length > 1) {
      return str.substring(0, 1).toUpperCase() + str.substring(1);
    }
    return str.toLowerCase();
  }

  static String _upperCaseFirstLetter(String word) {
    if (word.isNotEmpty) {
      return '${word[0].toUpperCase()}${word.length > 1 ? word.substring(1).toLowerCase() : ''}';
    }
    return '';
  }

  static String toCamelCase(String str, {bool startWithLower = false}) {
    final _words = _groupIntoWords(str);
    final List<String> words = _words.map(_upperCaseFirstLetter).toList();
    if (_words.isNotEmpty && startWithLower) {
      words[0] = words[0].toLowerCase();
    }

    return words.join('');
  }

  static String toNormalCase(String str) {
    if (str.contains('_')) {
      return str.split('_').map((word) => capitalize(word)).join(' ');
    } else if (str.contains(' ')) {
      return str.split(' ').map((word) => capitalize(word)).join(' ');
    }
    final StringBuffer output = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final unit = str[i].codeUnits.first;
      if (unit >= capitalACodeUnit && unit <= capitalZCodeUnit) {
        if (i != 0) {
          output.write(' ');
        }
        output.write(str[i]);
      } else {
        if (i == 0) {
          output.write(str[i].toUpperCase());
        } else {
          output.write(str[i]);
        }
      }
    }
    return output.toString();
  }

  static List<String> _groupIntoWords(String text) {
    StringBuffer sb = StringBuffer();
    List<String> words = [];
    bool isAllCaps = text.toUpperCase() == text;

    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      String? nextChar = i + 1 == text.length ? null : text[i + 1];

      if (symbolSet.contains(char)) {
        continue;
      }

      sb.write(char);

      bool isEndOfWord = nextChar == null ||
          (_upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) ||
          symbolSet.contains(nextChar);

      if (isEndOfWord) {
        words.add(sb.toString());
        sb.clear();
      }
    }

    return words;
  }

  static String toSnakeCase(String str, {String separator = '_'}) {
    final List<String> words =
        _groupIntoWords(str).map((word) => word.toLowerCase()).toList();

    return words.join(separator);
  }
}
