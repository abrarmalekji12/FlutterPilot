import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

import '../component_generator.dart';
import '../json_cleaner.dart';
import 'gemini_llm_integration.dart';
import 'llm_integration.dart';
import 'model_output.dart';

const _kAssistantId = 'asst_LJi8yhECsWz11x1AFJULWTNx';



class ChatgptLLMIntegration extends LLMIntegration {
  OpenAI? openAI;
  final JSONCleaner jsonCleaner = JSONCleaner();


  @override
  String get name => 'chatgpt';

  @override
  void initialize(String? secretKey) {
    if (secretKey != null) {
      openAI = OpenAI.instance.build(
          token: secretKey, // dotenv.get(secretKey)
          baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 60)),
          enableLog: true);
    } else {
      openAI = null;
    }
  }


  @override
  Future<ModelOutput?> process(String instruction, String prompt) {
    return callGPTAssistant(instruction, prompt, functionBody);
  }

  Future<ModelOutput?> callGPTAssistant(String instructions, String prompt, Map<String, dynamic> functionBody) async {
    const model = 'gpt-4o'; //gpt-3.5-turbo-0125
    final thread = {
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    };

    final inputToken = estimateTokens(instructions, thread, functionBody);
    print('INPUT TOKEN ESTIMATED: ${inputToken}');
    // return null;
    final request = CreateThreadAndRun(
      assistantId: _kAssistantId,
      instructions: instructions,
      model: model, //'gpt-3.5-turbo-0125'
      thread: thread,
      temperature: 0.3,
      topP: 0.8
    );
    final threadResponse = await openAI!.threads.v2.runs.createThreadAndRunV2(request: request);
    print('===================================');
    print('METADATA: ${threadResponse.metadata}');
    print('===================================');
    final threadId = threadResponse.threadId;
    final runId = threadResponse.id;
    CreateRunResponse? finalRun;
    int tries = 10;
    Map<String, dynamic>? output;
    int? outputToken;
    while (tries-- > 0) {
      await Future.delayed(const Duration(seconds: 2));
      finalRun = await openAI!.threads.v2.runs.retrieveRun(
        threadId: threadId,
        runId: runId,
      );
      print('STATUS:: ${finalRun.status}');

      if (finalRun.status == 'requires_action' || finalRun.status == 'completed') {
        String? outputString;
        if (finalRun.status == 'completed') {
          final messages = await openAI!.threads.v2.messages.listMessage(threadId: threadId, runId: runId);
          if (messages.data.isNotEmpty) {
            final assistantMessage = messages.data.firstWhere((msg) => msg.role == 'assistant');
// Convert content list to a single clean string
            outputString = assistantMessage.content.map((e) => e.text?.value ?? '').join('\n').trim();
          }
          print('Action: ${finalRun.instructions} ${finalRun.requiredAction}');
        }

        final toolCall = finalRun.requiredAction?['submit_tool_outputs']?['tool_calls'][0];
        if (toolCall != null) {
          outputString = toolCall['function']['arguments'];
        }

        if (outputString != null) {
          try {
            print('==============RAW-OUTPUT===================');
            print(outputString);
            print('===========================================');
            print('===========================================');
            outputToken = simpleTokenCount(outputString);
            print('===========================================');
            print('OUTPUT TOKEN: ${outputToken}');
            print('===========================================');
            print('TOTAL TOKEN: ${inputToken + outputToken}');
            print('===========================================');

            outputString = outputString.replaceAll('""', '"').replaceAll('"\\"', '"').replaceAll('\\"', '"');
            output = await jsonCleaner.clean(outputString);
            if (output != null) {
              print('==============OUTPUT===================');
              print(prettyJson(output));
              print('===========================================');
            }
          } catch (e, track) {
            print(e);
            print(track);
          }
        }
        break;
      }
    }
    return ModelOutput(output: output, model: model, inputToken: inputToken, outputToken: outputToken ?? 0);
  }
}
