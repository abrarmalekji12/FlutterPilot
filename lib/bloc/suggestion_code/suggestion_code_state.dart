part of 'suggestion_code_bloc.dart';

@immutable
abstract class SuggestionCodeState {}

class SuggestionCodeInitial extends SuggestionCodeState {}

class SuggestionCodeUpdated extends SuggestionCodeState {
  final CodeSuggestion? suggestions;
  SuggestionCodeUpdated(this.suggestions);
}

class SuggestionSelectedState extends SuggestionCodeState {
  SuggestionSelectedState();
}

class SuggestionSelectionChangeState extends SuggestionCodeState {
  final int selectionIndex;
  final CodeSuggestion suggestion;
  SuggestionSelectionChangeState(this.selectionIndex, this.suggestion);
}
