part of 'state_management_bloc.dart';

@immutable
abstract class StateManagementState {
  final String id;
  const StateManagementState(this.id);
}

class StateManagementInitial extends StateManagementState {
  const StateManagementInitial(super.id);
}

class StateManagementUpdatedState extends StateManagementState {
  const StateManagementUpdatedState(super.id);
}
