part of 'state_management_bloc.dart';

@immutable
abstract class StateManagementEvent {}

class StateManagementUpdateEvent extends StateManagementEvent {
  final String id;

  StateManagementUpdateEvent(this.id);
}
