import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../models/fvb_ui_core/component/component_model.dart';
import '../../runtime_provider.dart';

part 'state_management_event.dart';
part 'state_management_state.dart';

class StateManagementBloc
    extends Bloc<StateManagementEvent, StateManagementState> {
  StateManagementBloc()
      : super(const StateManagementInitial('', RuntimeMode.edit)) {
    on<StateManagementUpdateEvent>(_onUpdate);
    on<StateManagementRefreshEvent>(_refresh);
  }
  void _onUpdate(
      StateManagementUpdateEvent event, Emitter<StateManagementState> emit) {
    if (event.component.parentAffected) {
      emit(StateManagementUpdatedState(
          event.component.parent is Component
              ? event.component.parent.id
              : event.component.id,
          event.mode));
    } else
      emit(StateManagementUpdatedState(event.component.id, event.mode));
  }

  FutureOr<void> _refresh(
      StateManagementRefreshEvent event, Emitter<StateManagementState> emit) {
    emit(StateManagementUpdatedState(event.id, event.mode));
  }
}
