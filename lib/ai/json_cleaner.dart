import 'dart:convert';

class JSONCleaner {
  String fixBrackets(String input) {
    final List<Map<String, dynamic>> stack = [];
    final Set<int> removeIndexes = {};
    bool insideString = false;

    // First pass: track unmatched brackets
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final isEscaped = i > 0 && input[i - 1] == '\\';

      if (char == '"' && !isEscaped) {
        insideString = !insideString;
      }

      if (!insideString) {
        if (char == '{' || char == '[' || char == '(') {
          stack.add({'char': char, 'index': i});
        } else if (char == '}' || char == ']' || char == ')') {
          if (stack.isNotEmpty) {
            final openBracket = stack.last;
            final openChar = openBracket['char'];

            bool match = (openChar == '{' && char == '}') ||
                (openChar == '[' && char == ']') ||
                (openChar == '(' && char == ')');

            if (match) {
              stack.removeLast();
            } else {
              removeIndexes.add(i); // mismatched closing bracket
            }
          } else {
            removeIndexes.add(i); // unmatched closing bracket
          }
        }
      }
    }

    // Build the result string, skipping unmatched closing brackets
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      if (!removeIndexes.contains(i)) {
        buffer.write(input[i]);
      }
    }

    // Append closing brackets for unmatched openings
    for (final bracket in stack) {
      final openChar = bracket['char'];
      String? closingChar;
      if (openChar == '{') closingChar = '}';
      if (openChar == '[') closingChar = ']';
      if (openChar == '(') closingChar = ')';

      if (closingChar != null) buffer.write(closingChar);
    }

    return buffer.toString();
  }

  String fixMalformedJson(String input) {
    String fixed = input;

    // Remove trailing commas before } or ]
    // fixed = fixed.replaceAll(RegExp(r',\s*([}\]])'), r'\1');
    fixed = fixed.replaceAllMapped(RegExp(r',\s*([}\]])'), (match) => match.group(1)!);

    // Remove wrapping parentheses
    // fixed = fixed.trim();

    if (fixed.startsWith('(') && fixed.endsWith(')')) {
      fixed = fixed.substring(1, fixed.length - 1).trim();
    }

    // Remove unmatched brackets
    fixed = fixBrackets(fixed);

    return fixed;
  }

  // Map<String, dynamic>? parseJson(String data) {
  //   try {
  //     final output = json.decode(data);
  //     return output;
  //   } on FormatException catch (e, trace) {
  //     print('❌ Parse JSON: ${e.offset} ${e.message}');
  //     print('❌ Stack $trace');
  //   }
  //   return null;
  // }

  Future<Map<String, dynamic>?> clean(String input, {int attempt = 0}) async {
    try {
      // final cleaned = await IOOperations.runJsonRepair(input);
      final cleaned = fixMalformedJson(input);
      return json.decode(cleaned);
    } on FormatException catch (e, trace) {
      print('❌ ATTEMPT: ${attempt} to parse JSON: ${e.offset} ${e.message}');
      print('❌ Stack $trace');
      if (e.offset != null && e.offset! < input.length && attempt < 5) {
        final updated = input.substring(0, e.offset!) + input.substring(e.offset! + 1);

        final output = await clean(updated, attempt: attempt + 1);

        if (output == null) {
          Map<String, int> counts = {
            '{': 0,
            '}': 0,
            '[': 0,
            ']': 0,
          };
          for (int i = 0; i < input.length; i++) {
            if (input[i] == '{' || input[i] == '}' || input[i] == '[' || input[i] == ']') {
              counts[input[i]] = (counts[input[i]] ?? 0) + 1;
            }
          }
          final String? parenthesis;
          if (counts['{']! > counts['}']!) {
            parenthesis = '}';
          } else if (counts['{']! < counts['}']!) {
            parenthesis = '{';
          } else if (counts['[']! > counts[']']!) {
            parenthesis = ']';
          } else if (counts['[']! < counts[']']!) {
            parenthesis = '[';
          } else {
            parenthesis = null;
          }
          if (parenthesis != null) {
            final updated = input.substring(0, e.offset!) + parenthesis + input.substring(e.offset!);
            final output = await clean(updated, attempt: attempt + 1);
            if (output != null) {
              return output;
            }
          }
        }
        return output;
      }
    }
    return null;
  }
}
