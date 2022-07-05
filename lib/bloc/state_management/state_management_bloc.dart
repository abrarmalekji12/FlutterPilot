import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'state_management_event.dart';
part 'state_management_state.dart';

class StateManagementBloc
    extends Bloc<StateManagementEvent, StateManagementState> {
  StateManagementBloc() : super(const StateManagementInitial('')) {
    on<StateManagementUpdateEvent>(_onUpdate);
  }
  void _onUpdate(
      StateManagementUpdateEvent event, Emitter<StateManagementState> emit) {
    emit(StateManagementUpdatedState(event.id));
  }
}
