part of 'state_management_bloc.dart';

@immutable
abstract class StateManagementEvent {}

class StateManagementUpdateEvent extends StateManagementEvent {
  final Component component;
  final RuntimeMode mode;

  StateManagementUpdateEvent(this.component, this.mode);
}

class StateManagementRefreshEvent extends StateManagementEvent {
  final String id;
  final RuntimeMode mode;

  StateManagementRefreshEvent(this.id, this.mode);
}
