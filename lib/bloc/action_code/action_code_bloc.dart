import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'action_code_event.dart';
part 'action_code_state.dart';

class ActionCodeBloc extends Bloc<ActionCodeEvent, ActionCodeState> {
  ActionCodeBloc() : super(ActionCodeInitial()) {
    on<ActionCodeEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<ActionCodeUpdatedEvent>(_actionCodeUpdated);
  }

  void _actionCodeUpdated(ActionCodeUpdatedEvent event, Emitter<ActionCodeState> emit) {
    emit(ActionCodeUpdatedState(event.scopeName));
  }
}
