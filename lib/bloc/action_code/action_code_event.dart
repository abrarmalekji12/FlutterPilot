part of 'action_code_bloc.dart';

@immutable
abstract class ActionCodeEvent {}

class ActionCodeUpdatedEvent extends ActionCodeEvent {
  ActionCodeUpdatedEvent(this.scopeName);
  final String scopeName;
}