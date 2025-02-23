import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:meta/meta.dart';

part 'suggestion_code_event.dart';
part 'suggestion_code_state.dart';

class SuggestionCodeBloc
    extends Bloc<SuggestionCodeEvent, SuggestionCodeState> {
  CodeSuggestion? _suggestion;
  int selectionIndex = 0;

  SuggestionCodeBloc() : super(SuggestionCodeInitial()) {
    on<SuggestionCodeEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<SuggestionUpdatedEvent>(_onSuggestionUpdated);
    on<ClearSuggestionEvent>(_onClearSuggestion);
    on<SuggestionSelectionUpdateEvent>(_onSuggestionSelectionChange);
    on<SuggestionSelectedEvent>(_onSuggestionSelectionEvent);
  }

  void _onSuggestionUpdated(
      SuggestionUpdatedEvent event, Emitter<SuggestionCodeState> emit) {
    if (_suggestion != event.suggestions) {
      _suggestion = event.suggestions;
      if (_suggestion != null) {
        selectionIndex = 0;
      }
      emit(SuggestionCodeUpdated(_suggestion));
    }
  }

  void _onClearSuggestion(
      ClearSuggestionEvent event, Emitter<SuggestionCodeState> emit) {
    _suggestion = null;
  }

  void clear() {
    _suggestion = null;
  }

  void _onSuggestionSelectionChange(
      SuggestionSelectionUpdateEvent event, Emitter<SuggestionCodeState> emit) {
    if (_suggestion != null) {
      if (selectionIndex + event.change < 0) {
        selectionIndex = _suggestion!.suggestions.length - 1;
      } else if (selectionIndex + event.change <
          _suggestion!.suggestions.length) {
        selectionIndex += event.change;
      }
      emit(SuggestionSelectionChangeState(selectionIndex, _suggestion!));
    }
  }

  CodeSuggestion? get suggestion => _suggestion;

  FutureOr<void> _onSuggestionSelectionEvent(
      SuggestionSelectedEvent event, Emitter<SuggestionCodeState> emit) {
    selectionIndex = event.selection;
    emit(SuggestionSelectedState());
  }
}
