import '../compiler/code_processor.dart';

class StringOperation {
  static String capitalize(String str) {
    if (str.length > 1) {
      return str.substring(0, 1).toUpperCase() + str.substring(1);
    }
    return str.toLowerCase();
  }

  static String toCamelCase(String str) {
    return str.split('_').map((word) => capitalize(word)).join();
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
      if (unit >= CodeProcessor.capitalACodeUnit &&
          unit <= CodeProcessor.capitalZCodeUnit) {
        output.write(' ');
        output.write(str[i].toUpperCase());
      } else {
        output.write(str[i]);
      }
    }
    return output.toString();
  }

  static String toSnakeCase(String str) {
    if (!str.contains(' ')) {
      final StringBuffer output = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        final unit = str[i].codeUnits.first;
        if (unit >= CodeProcessor.capitalACodeUnit &&
            unit <= CodeProcessor.capitalZCodeUnit) {
          output.write('_');
          output.write(str[i].toLowerCase());
        } else {
          output.write(str[i]);
        }
      }
      return output.toString();
    }
    return str.split(' ').map((word) => word.toLowerCase()).join('_');
  }
}
