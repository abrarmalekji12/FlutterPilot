
import 'dart:convert';

import 'model_output.dart';

abstract class LLMIntegration {

  String get name;

  void initialize(String? secretKey);

  Future<ModelOutput?> process(String instruction, String prompt);
}
int simpleTokenCount(String text) {
  return (text.length / 4).ceil();
}

int estimateTokens(
    String instruction,
    Map<String, dynamic> thread,
    Map<String, dynamic> functionBody,
    ) {
  var total = 0;

  // 1. Instruction (as a “system” message)
  total += simpleTokenCount('system'); // role overhead
  total += simpleTokenCount(instruction); // its content

  // 2. All user/assistant/function messages
  for (var msg in thread['messages']) {
    total += simpleTokenCount(msg['role']); // role overhead
    total += simpleTokenCount(msg['content']); // message content
  }

  // 3. The standalone function body (tagged as “function”)
  total += simpleTokenCount('function');
  total += simpleTokenCount(jsonEncode(functionBody));

  return total;
}