import 'package:google_generative_ai/google_generative_ai.dart';

import '../constant/other_constant.dart';

GenerativeModel? generativeModel;

void initializeGemini() {
  generativeModel = GenerativeModel(
    model: 'gemini-pro',
    apiKey: geminiAPIKey,
    generationConfig: GenerationConfig(),
  );
}
