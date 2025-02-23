import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../runtime_provider.dart';
import '../../ui/fvb_code_editor.dart';

part 'error_event.dart';
part 'error_state.dart';

class EventLogBloc extends Bloc<ErrorEvent, ErrorState> {
  final Map<RuntimeMode, List<ConsoleMessage>> consoleMessages = {};
  bool consoleVisible = true;

  EventLogBloc() : super(ErrorInitial()) {
    on<ConsoleUpdatedEvent>(_consoleUpdated);
    on<ClearMessageEvent>(_clear);
    on<ClearComponentMessageEvent>(_clearComponentErrors);
    on<HandleBugReportEvent>(_handleBugReport);
  }

  void _consoleUpdated(ConsoleUpdatedEvent event, Emitter<ErrorState> emit) {
    if (consoleVisible) {
      if (!consoleMessages.containsKey(RuntimeProvider.global)) {
        consoleMessages[RuntimeProvider.global] = [event.consoleMessage];
      } else {
        consoleMessages[RuntimeProvider.global]!.add(event.consoleMessage);
      }

      emit(ErrorUpdatedState());
    }
  }

  void _clear(ClearMessageEvent event, Emitter<ErrorState> emit) {
    consoleMessages.remove(event.mode);
    emit(ErrorUpdatedState());
  }

  void _clearComponentErrors(
      ClearComponentMessageEvent event, Emitter<ErrorState> emit) {
    for (final list in consoleMessages.entries) {
      list.value
          .removeWhere((element) => element.component?.id == event.componentId);
    }
    emit(ErrorUpdatedState());
  }

  FutureOr<void> _handleBugReport(
      HandleBugReportEvent event, Emitter<ErrorState> emit) {
    emit(BugReportState(event.error));
  }
}
