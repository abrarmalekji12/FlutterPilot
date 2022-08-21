import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../ui/action_code_editor.dart';

part 'error_event.dart';

part 'error_state.dart';

class ErrorBloc extends Bloc<ErrorEvent, ErrorState> {
  final List<ConsoleMessage> consoleMessages = [];
  bool consoleVisible = true;

  ErrorBloc() : super(ErrorInitial()) {
    on<ConsoleUpdatedEvent>(_consoleUpdated);
    on<ClearMessageEvent>(_clear);
  }

  void _consoleUpdated(ConsoleUpdatedEvent event, Emitter<ErrorState> emit) {
    if (consoleVisible) {
      consoleMessages.insert(0, event.consoleMessage);
      emit(ErrorUpdatedState());
    }
  }

  void _clear(ClearMessageEvent event, Emitter<ErrorState> emit) {
    consoleMessages.clear();
    emit(ErrorUpdatedState());
  }
}
