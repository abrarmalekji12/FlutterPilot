import '../compiler/code_processor.dart';

class SuggestionProcessor {
  SuggestionProcessor();

  static List<SuggestionTile> processVariables(
      final Map<String, FVBVariable> variables,
      String keyword,
      String object,
      bool global,
      {bool static = false}) {
    return variables.entries
        .where((element) => element.key.contains(keyword))
        .map((e) => SuggestionTile(
            e.value,
            object,
            static ? SuggestionType.staticVar : SuggestionType.variable,
            e.value.name,
            0,
            global: global))
        .toList(growable: false);
  }

  static void processClasses(Map<String, FVBClass> classes, String keyword,
      String object, Stack2<FVBValue> valueStack, CodeSuggestion suggestion) {
    for (final e in classes.entries.where((element) => element.key.contains(keyword))) {
      if (valueStack.isNotEmpty) {
        final sample = e.value.getDefaultConstructor?.sampleCode ??
            FVBFunctionSample(e.key + '()', 0, 0);
        suggestion.add(SuggestionTile(
            e.value, '', SuggestionType.classes, sample.code, sample.end,
            resultCursorStart: sample.start));
        suggestion.addAll(e.value.getNamedConstructor.map((e){
          final sample = e.sampleCode;
          return SuggestionTile(
              e, '', SuggestionType.classes, sample.code, sample.end,
              resultCursorStart: sample.start);
        }));
      }
      suggestion.add(SuggestionTile(
        e.value,
        '',
        SuggestionType.classes,
        e.key,
        0,
      ));
    }
  }

  static List<SuggestionTile> processFunctions(
      final Iterable<FVBFunction> functions,
      String keyword,
      String object,
      String name,
      bool global,
      {bool static = false}) {
    return functions
        .where(
            (element) => element.name.contains(keyword) && element.name != name && !element.name.startsWith('$name.'))
        .map((e) {
      final sampleCode = e.sampleCode;
      return SuggestionTile(
          e,
          object,
          static ? SuggestionType.staticFun : SuggestionType.function,
          global: global,
          sampleCode.code,
          sampleCode.end,
          resultCursorStart: sampleCode.start);
    }).toList(growable: false);
  }

  static List<SuggestionTile> processNamedConstructor(
      final Iterable<FVBFunction> functions,
      String keyword,
      String object,
      String name,
      bool global,
      {bool static = false}) {
    return functions
        .where(
            (element) => element.name.contains(keyword))
        .map((e) {
      final sampleCode = e.sampleCode;
      return SuggestionTile(
          e,
          object,
          static ? SuggestionType.staticFun : SuggestionType.function,
          global: global,
          sampleCode.code.split('.')[1],
          sampleCode.end,
          resultCursorStart: sampleCode.start);
    }).toList(growable: false);
  }
}

class SuggestionConfig{
  NamedParameterSuggestion? namedParameterSuggestion;
  SuggestionConfig();
}

class NamedParameterSuggestion{
  final List<String> parameters;
  final int lastCodeCount;
  NamedParameterSuggestion(this.parameters, this.lastCodeCount);
}