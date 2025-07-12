import 'package:google_generative_ai/google_generative_ai.dart';

import '../component_generator.dart';
import '../json_cleaner.dart';
import 'llm_integration.dart';
import 'model_output.dart';

final flutterWidgetSchema = Schema(
  SchemaType.object,
  properties: {
    'name': Schema(SchemaType.string,
        description: 'Name of the Flutter component (e.g., Scaffold, Column, Container)', nullable: false),
    'props': Schema(SchemaType.array,
        description: 'Flat key-value properties for the widget',
        items: Schema(SchemaType.object, properties: {
          'name': Schema(SchemaType.string),
          'value': Schema(SchemaType.string),
        })
        // properties: {
        //   'color': Schema(SchemaType.string),
        //   'fontSize': Schema(SchemaType.string),
        // },
        ),
    'child': Schema(
      SchemaType.object,
      description: 'Single child widget (if supported)',
      properties: {
        'name': Schema(SchemaType.string, description: 'Nested widget name'),
        'props': Schema(SchemaType.string, description: 'Nested widget properties')
      },
      // Recursive reference handled manually
      // This would be replaced with `flutterWidgetSchema` or similar in actual code
    ),
    'children': Schema(
      SchemaType.array,
      description: 'Multiple children (if supported)',
      items: Schema(
        SchemaType.object,
        description: 'Child widget', // Optional
        properties: {
          'name': Schema(SchemaType.string, description: 'Child widget name'),
          'props': Schema(SchemaType.string, description: 'Child widget properties')
        },
      ),
    ),
    'slots': Schema(
      SchemaType.object,
      description: 'Map of named single-child or multi-child slots (keys can be dynamic)',
      properties: {
        'slot1': Schema(
          SchemaType.object,
          properties: {'name': Schema(SchemaType.string, description: 'Slot widget name')},
        ),
        'slot2': Schema(
          SchemaType.array,
          items: Schema(
            SchemaType.object,
            description: 'Child widget', // Optional
            properties: {
              'name': Schema(SchemaType.string, description: 'Child widget name'),
              'props': Schema(SchemaType.string, description: 'Child widget properties')
            },
          ),
        ),
      },
    ),
  },
);
const Map<String, dynamic> functionBody = {
  'name': 'generateFlutterUI',
  'description': 'Generate a Flutter UI as JSON using predefined component schema for a low-code platform.',
  'strict': false,
  'parameters': {
    'type': 'object',
    'description': 'Root widget of the UI in JSON format following custom Flutter widget schema',
    'properties': {
      'name': {'type': 'string', 'description': 'Name of the Flutter component (e.g., Scaffold, Column, Container)'},
      'props': {
        'type': 'object',
        'description': 'Flat key-value map of properties in string i.e color, fontSize etc',
        'additionalProperties': {'type': 'string'}
      },
      'child': {'\$ref': '#', 'description': 'Single child widget (if supported)'},
      'children': {
        'type': 'array',
        'items': {'\$ref': '#'},
        'description': 'Multiple children (if supported)'
      },
      'slots': {
        'type': 'object',
        'description': 'Map of named single-child or multi-child slots (keys can be dynamic)',
        'additionalProperties': {'\$ref': '#'}
      }
      // 'childMap': {
      //   'type': 'object',
      //   'description': 'Map of named single-child slots (keys can be dynamic)',
      //   'additionalProperties': {'\$ref': '#'}
      // },
      // 'childrenMap': {
      //   'type': 'object',
      //   'description': 'Map of named children arrays (keys can be dynamic)',
      //   'additionalProperties': {
      //     'type': 'array',
      //     'items': {'\$ref': '#'}
      //   }
      // }
    },
    'required': ['name', 'props']
  }
};

class GeminiLLMIntegration extends LLMIntegration {
  GenerativeModel? gemini;
  final JSONCleaner jsonCleaner = JSONCleaner();
  String? _secretKey;

  @override
  String get name => 'gemini';

  @override
  void initialize(String? secretKey) {
    if (secretKey != null) {
      this._secretKey = secretKey;
    }
  }

  @override
  Future<ModelOutput?> process(String instruction, String prompt) {
    return callGPTAssistant(instruction, prompt, functionBody);
  }

  Future<Map<String, dynamic>?> parseOutputJson(String outputString, [int attempt = 1]) async {
    try {
      print('==============RAW-OUTPUT===================');
      print(outputString);
      print('===========================================');

      outputString = outputString.replaceAll('""', '"').replaceAll('"\\"', '"').replaceAll('\\"', '"');
      final output = await jsonCleaner.clean(outputString);
      if (output != null) {
        print('==============OUTPUT===================');
        print(prettyJson(output));
        print('=======================================');
      } else if (attempt < 3) {
        final response = await gemini?.generateContent([
          Content.text(outputString),
          Content.text('\nFix above malformed JSON'),
        ]);
        final outputText = response?.candidates.map((e) => e.text ?? '').join('');
        if (outputText?.trim().isNotEmpty ?? false) {
          return parseOutputJson(outputText!, attempt + 1);
        }
      }
      return output;
    } catch (e, track) {
      print(e);
      print(track);
    }
    return null;
  }

  Future<ModelOutput?> callGPTAssistant(String instructions, String prompt, Map<String, dynamic> functionBody) async {
    if (_secretKey == null) {
      return null;
    }
    const model = 'gemini-1.5-flash-latest';
    gemini = GenerativeModel(
      model: model, // Or 'gemini-1.5-pro-latest'
      apiKey: _secretKey!,
      systemInstruction: Content.system(instructions),
      // tools: [
      //   Tool(
      //     functionDeclarations: [
      //       FunctionDeclaration(, description, parameters)
      //     ]
      //   )
      // ]
    );
    final response = await gemini?.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        // responseSchema: flutterWidgetSchema,
        temperature: 0.7,
        topP: 0.8,
        maxOutputTokens: 5000,
      ),
    );

    final thread = {
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    };
    print('Gemini Output: ${response?.text} ${response?.candidates.map((e) => e.content.toJson()).join('\n')}');
    String? outputString = response?.text ?? response?.candidates.map((e) => e.text ?? '').join();
    final inputToken = estimateTokens(instructions, thread, flutterWidgetSchema.toJson());
    print('INPUT TOKEN ESTIMATED: ${inputToken}');
    int? outputToken;
    Map<String, dynamic>? output;

    if (outputString != null) {
      print('===========================================');
      outputToken = simpleTokenCount(outputString);
      print('===========================================');
      print('OUTPUT TOKEN: ${outputToken}');
      print('===========================================');
      print('TOTAL TOKEN: ${inputToken + outputToken}');
      print('===========================================');

      output = await parseOutputJson(outputString);
    }

    return ModelOutput(output: output, model: model, inputToken: inputToken, outputToken: outputToken ?? 0);
  }
}
