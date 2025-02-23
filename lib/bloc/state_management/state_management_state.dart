part of 'state_management_bloc.dart';

@immutable
abstract class StateManagementState {
  final String id;
  final RuntimeMode mode;
  const StateManagementState(this.id, this.mode);
}

class StateManagementInitial extends StateManagementState {
  const StateManagementInitial(super.id, super.mode);
}

class StateManagementUpdatedState extends StateManagementState {
  const StateManagementUpdatedState(super.id, super.mode);
}
