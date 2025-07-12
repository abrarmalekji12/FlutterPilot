import 'dart:convert';

import '../injector.dart';
import '../io/io_operations_stub.dart' if (dart.library.io) '../io/io_operations.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../user_session.dart';
import 'ai_post_processor.dart';
import 'dummy_response.dart';
import 'json_cleaner.dart';
import 'llm_integration/chatgpt_llm_integration.dart';
import 'llm_integration/gemini_llm_integration.dart';
import 'llm_integration/llm_integration.dart';
import 'llm_integration/model_output.dart';
import 'prompt_generator.dart';

class ComponentGenerator {
  final AIPostProcessor aiPostProcessor = AIPostProcessor();
  final PromptGenerator _promptGenerator = PromptGenerator();
  final UserSession _userSession=sl<UserSession>();
  final JSONCleaner jsonCleaner=JSONCleaner();
  final LLMIntegration _geminiIntegration = GeminiLLMIntegration();
  final LLMIntegration _chatgptIntegration = ChatgptLLMIntegration();


  void initialize(){
    _geminiIntegration.initialize(_userSession.settingModel?.geminiSecretToken);
    _chatgptIntegration.initialize(_userSession.settingModel?.openAISecretToken);
  }


  Future<(List<Component>, List<Map<String, dynamic>>)?> generate(String prompt) async {

    print('===================================');
    print('MESSAGE: ${prompt}');
    print('===================================');

    // final output = await callGPTAssistant(prompt);

    // final output =
    //     ModelOutput.fromJson(await IOOperations.readJsonFile('prompts', 'prompt_2025-07-12T16:26:59.875981.json'));


    final output = ModelOutput(output: await jsonCleaner.clean(dummyCode), model: '-', inputToken: 0, outputToken: 0);

    // if (output != null) {
    //   IOOperations.createJsonFile('prompts', 'prompt_${DateTime.now().toIso8601String()}.json', {
    //     'prompt': prompt,
    //     'output': output.output,
    //     'inputToken': output.inputToken,
    //     'outputToken': output.outputToken,
    //   });
    // }

    final List<Map<String, dynamic>> outputList = output?.output != null ? [output!.output!] : [];

    List<Component>? generatedComponents;
    if (outputList.isNotEmpty) {
      generatedComponents = outputList.map((e) => aiPostProcessor.processMap(e)).whereType<Component>().toList();
    }
    return generatedComponents != null ? (generatedComponents, outputList) : null;
  }

  Future<ModelOutput?> callGPTAssistant(String prompt) async {
    final _integration=_geminiIntegration;
    final instructions = _promptGenerator.generatePromptLite(model: _integration.name);
    final output = await _integration.process(instructions, prompt);

    if (output != null && output.output != null && output.inputToken > 0) {
      IOOperations.createJsonFile('prompts', 'prompt_${DateTime.now().toIso8601String()}.json', {
        'prompt': prompt,
        'model':output.model,
        'output': output.output,
        'inputToken': output.inputToken,
        'outputToken': output.outputToken,
      });
    }
    return output;
  }
}

String prettyJson(Map<String, dynamic>? data) => const JsonEncoder.withIndent('  ').convert(data);


