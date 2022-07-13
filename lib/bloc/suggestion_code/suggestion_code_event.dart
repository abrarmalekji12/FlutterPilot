part of 'suggestion_code_bloc.dart';

@immutable
abstract class SuggestionCodeEvent {}

class SuggestionUpdatedEvent extends SuggestionCodeEvent {
  final CodeSuggestion? suggestions;
  SuggestionUpdatedEvent(this.suggestions);
}
class ClearSuggestionEvent extends SuggestionCodeEvent {
ClearSuggestionEvent();
}
class SuggestionSelectionChangeEvent extends SuggestionCodeEvent {
  final int change;
  SuggestionSelectionChangeEvent(this.change);
}
