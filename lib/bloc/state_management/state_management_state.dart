part of 'state_management_bloc.dart';

@immutable
abstract class StateManagementState {}

class StateManagementInitial extends StateManagementState {}


class StateManagementUpdatedState extends StateManagementState {
  final String id;

  StateManagementUpdatedState(this.id);
}