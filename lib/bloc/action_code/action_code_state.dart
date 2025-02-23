part of 'action_code_bloc.dart';

@immutable
abstract class ActionCodeState {}

class ActionCodeInitial extends ActionCodeState {}

class ActionCodeUpdatedState extends ActionCodeState {
  ActionCodeUpdatedState(this.scope);
  final String scope;
}
