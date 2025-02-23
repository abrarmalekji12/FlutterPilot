part of 'right_side_bloc.dart';

@immutable
abstract class RightSideEvent {}

class RightSideUpdateEvent extends RightSideEvent {
  final RightSide side;

  RightSideUpdateEvent(this.side);
}
