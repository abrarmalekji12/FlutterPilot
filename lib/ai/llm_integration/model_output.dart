class ModelOutput {
  final Map<String, dynamic>? output;
  final String model;
  final int inputToken;
  final int outputToken;

  ModelOutput({required this.output, required this.model, required this.inputToken, required this.outputToken});

  factory ModelOutput.fromJson(Map<String, dynamic> json) {
    return ModelOutput(
      output: json['output'] != null ? Map<String, dynamic>.from(json['output']) : null,
      model: json['model'] ?? '',
      inputToken: json['inputToken'] ?? 0,
      outputToken: json['outputToken'] ?? 0,
    );
  }
}
