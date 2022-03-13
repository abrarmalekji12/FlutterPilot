part of 'action_edit_cubit.dart';

@immutable
abstract class ActionEditState {}

class ActionEditInitial extends ActionEditState {}


class ActionChangeState extends ActionEditState {
  ActionChangeState();
}
