import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:fvb_processor/compiler/fvb_functions.dart';

final List<FVBCodeSnippet> codeSnippets = [
  FVBCodeSnippet(
      name: 'Show SnackBar',
      fields: fvbFunShowSnackBar.arguments,
      code: (data) {
        return 'App.${fvbFunShowSnackBar.generate(data)};';
      },
      defaultValues: {
        'content': FVBCode('\'This is simple SnackBar\''),
        'duration': FVBCode('Duration(milliseconds:300)'),
      }),
  FVBCodeSnippet(
      name: 'Pop the screen',
      fields: fvbFunShowSnackBar.arguments,
      code: (data) {
        return 'App.pop(context);';
      },
      defaultValues: {}),
];

class FVBCodeSnippet {
  final String name;
  final String? image;
  final List<FVBArgument> fields;
  final Map<String, FVBCode> defaultValues;
  final String Function(Map<String, dynamic>) code;

  FVBCodeSnippet({
    required this.name,
    required this.fields,
    required this.code,
    required this.defaultValues,
    this.image,
  });
}
