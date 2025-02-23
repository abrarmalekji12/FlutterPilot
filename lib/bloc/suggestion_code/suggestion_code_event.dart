part of 'suggestion_code_bloc.dart';

@immutable
abstract class SuggestionCodeEvent {}

class SuggestionUpdatedEvent extends SuggestionCodeEvent {
  final CodeSuggestion? suggestions;
  SuggestionUpdatedEvent(this.suggestions);
}

class SuggestionSelectedEvent extends SuggestionCodeEvent {
  final int selection;
  SuggestionSelectedEvent(this.selection);
}

class ClearSuggestionEvent extends SuggestionCodeEvent {
  ClearSuggestionEvent();
}

class SuggestionSelectionUpdateEvent extends SuggestionCodeEvent {
  final int change;

  SuggestionSelectionUpdateEvent(this.change);
}
