import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../common/compiler/code_processor.dart';

part 'suggestion_code_event.dart';

part 'suggestion_code_state.dart';

class SuggestionCodeBloc
    extends Bloc<SuggestionCodeEvent, SuggestionCodeState> {
  CodeSuggestion? suggestion;
  int selectionIndex = 0;

  SuggestionCodeBloc() : super(SuggestionCodeInitial()) {
    on<SuggestionCodeEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<SuggestionUpdatedEvent>(_onSuggestionUpdated);
    on<ClearSuggestionEvent>(_onClearSuggestion);
    on<SuggestionSelectionChangeEvent>(_onSuggestionSelectionChange);
  }

  void _onSuggestionUpdated(
      SuggestionUpdatedEvent event, Emitter<SuggestionCodeState> emit) {
   suggestion=event.suggestions;
   if(suggestion!=null){
     selectionIndex=0;
   }
    emit(SuggestionCodeUpdated(suggestion));
  }

  void _onClearSuggestion(
      ClearSuggestionEvent event, Emitter<SuggestionCodeState> emit) {
    suggestion=null;
  }

  void _onSuggestionSelectionChange(SuggestionSelectionChangeEvent event, Emitter<SuggestionCodeState> emit) {
    if(selectionIndex+event.change<0) {
      selectionIndex=suggestion!.suggestions.length-1;
    }
    else if(selectionIndex+event.change>=suggestion!.suggestions.length) {
      selectionIndex=0;
    }
    else {
      selectionIndex+=event.change;
    }
    emit(SuggestionSelectionChangeState(selectionIndex));
  }
}
