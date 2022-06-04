part of 'stack_action_cubit.dart';

@immutable
abstract class StackActionState {}

class StackActionInitial extends StackActionState {}

class StackUpdatedState extends StackActionState {
  StackUpdatedState();
}
